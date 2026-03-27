#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "glean-api-client>=0.5.0",
#     "click>=8.0.0",
# ]
# ///
"""Glean Chat CLI for agent skills.

Queries Glean's AI chat (enterprise knowledge) from the command line.
All output is JSON for easy machine parsing.

Environment variables:
    GLEAN_API_TOKEN   – API token with CHAT scope
    GLEAN_SERVER_URL  – e.g. https://your-company-be.glean.com
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

import click

CONFIG_DIR = Path.home() / ".config" / "glean-skill"
CONFIG_FILE = CONFIG_DIR / "config.json"


def _load_config() -> dict:
    if CONFIG_FILE.exists():
        return json.loads(CONFIG_FILE.read_text())
    return {}


def _save_config(cfg: dict) -> None:
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    CONFIG_FILE.write_text(json.dumps(cfg, indent=2))


def _get_credentials() -> tuple[str, str]:
    """Return (api_token, server_url) from env vars or saved config."""
    cfg = _load_config()
    token = os.environ.get("GLEAN_API_TOKEN") or cfg.get("api_token")
    server = os.environ.get("GLEAN_SERVER_URL") or cfg.get("server_url")
    if not token:
        click.echo(json.dumps({"error": "GLEAN_API_TOKEN not set. Run: glean-cli.py auth setup"}))
        sys.exit(1)
    if not server:
        click.echo(json.dumps({"error": "GLEAN_SERVER_URL not set. Run: glean-cli.py auth setup"}))
        sys.exit(1)
    return token, server


def _make_client():
    from glean.api_client import Glean

    token, server = _get_credentials()
    return Glean(api_token=token, server_url=server)


def _extract_text(response) -> str:
    """Pull text from a Glean chat response object."""
    if not response.messages:
        return ""
    last = response.messages[-1]
    parts = []
    if hasattr(last, "fragments") and last.fragments:
        for frag in last.fragments:
            if hasattr(frag, "text") and frag.text:
                parts.append(frag.text)
    return "\n".join(parts)


def _extract_citations(response) -> list[dict]:
    """Pull citation info from a Glean chat response."""
    citations = []
    if not response.messages:
        return citations
    last = response.messages[-1]
    if hasattr(last, "fragments") and last.fragments:
        for frag in last.fragments:
            if hasattr(frag, "citation") and frag.citation:
                c = frag.citation
                entry: dict = {}
                if hasattr(c, "source_document") and c.source_document:
                    doc = c.source_document
                    if hasattr(doc, "title"):
                        entry["title"] = doc.title
                    if hasattr(doc, "url"):
                        entry["url"] = doc.url
                if entry:
                    citations.append(entry)
    return citations


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

@click.group()
def cli():
    """Glean Chat CLI – query your company's knowledge from the terminal."""
    pass


# -- auth ------------------------------------------------------------------

@cli.group()
def auth():
    """Manage Glean API credentials."""
    pass


@auth.command("setup")
@click.option("--token", prompt="Glean API token (CHAT scope)", help="API token")
@click.option("--server", prompt="Glean server URL (e.g. https://acme-be.glean.com)", help="Server URL")
def auth_setup(token: str, server: str):
    """Save Glean API credentials locally."""
    server = server.rstrip("/")
    cfg = _load_config()
    cfg["api_token"] = token
    cfg["server_url"] = server
    _save_config(cfg)
    click.echo(json.dumps({"status": "ok", "server_url": server, "config_path": str(CONFIG_FILE)}))


@auth.command("status")
def auth_status():
    """Check if credentials are configured."""
    try:
        token, server = _get_credentials()
        masked = token[:8] + "..." + token[-4:] if len(token) > 12 else "***"
        click.echo(json.dumps({"authenticated": True, "server_url": server, "token_preview": masked}))
    except SystemExit:
        pass


@auth.command("clear")
def auth_clear():
    """Remove saved credentials."""
    if CONFIG_FILE.exists():
        CONFIG_FILE.unlink()
    click.echo(json.dumps({"status": "cleared"}))


# -- chat ------------------------------------------------------------------

@cli.command("ask")
@click.argument("question")
@click.option("--chat-id", default=None, help="Continue an existing conversation")
@click.option("--agent-id", default=None, help="Use a specific Glean agent")
@click.option("--save/--no-save", default=True, help="Save conversation in Glean history")
def ask(question: str, chat_id: str | None, agent_id: str | None, save: bool):
    """Send a question to Glean Chat and get a response."""
    from glean.api_client import models

    with _make_client() as glean:
        kwargs: dict = {
            "messages": [
                {"fragments": [models.ChatMessageFragment(text=question)]},
            ],
            "save_chat": save,
        }
        if chat_id:
            kwargs["chat_id"] = chat_id
        if agent_id:
            kwargs["agent_id"] = agent_id

        try:
            resp = glean.client.chat.create(**kwargs)
        except Exception as e:
            click.echo(json.dumps({"error": str(e)}))
            sys.exit(1)

        result: dict = {
            "answer": _extract_text(resp),
        }
        cid = getattr(resp, "chat_id", None)
        if cid:
            result["chat_id"] = cid
        cites = _extract_citations(resp)
        if cites:
            result["citations"] = cites

        click.echo(json.dumps(result, ensure_ascii=False))


@cli.command("stream")
@click.argument("question")
@click.option("--chat-id", default=None, help="Continue an existing conversation")
@click.option("--agent-id", default=None, help="Use a specific Glean agent")
def stream(question: str, chat_id: str | None, agent_id: str | None):
    """Stream a Glean Chat response (prints chunks as they arrive)."""
    from glean.api_client import models

    with _make_client() as glean:
        kwargs: dict = {
            "messages": [
                {"fragments": [models.ChatMessageFragment(text=question)]},
            ],
        }
        if chat_id:
            kwargs["chat_id"] = chat_id
        if agent_id:
            kwargs["agent_id"] = agent_id

        try:
            for chunk in glean.client.chat.create_stream(**kwargs):
                if chunk:
                    sys.stdout.write(str(chunk))
                    sys.stdout.flush()
            sys.stdout.write("\n")
        except Exception as e:
            click.echo(json.dumps({"error": str(e)}))
            sys.exit(1)


@cli.command("history")
@click.option("--limit", default=20, help="Max conversations to list")
def history(limit: int):
    """List recent Glean chat conversations."""
    with _make_client() as glean:
        try:
            resp = glean.client.chat.list(count=limit)
            chats = []
            if hasattr(resp, "results") and resp.results:
                for c in resp.results:
                    entry: dict = {}
                    if hasattr(c, "chat_id"):
                        entry["chat_id"] = c.chat_id
                    if hasattr(c, "name"):
                        entry["name"] = c.name
                    if hasattr(c, "created_at"):
                        entry["created_at"] = str(c.created_at)
                    chats.append(entry)
            click.echo(json.dumps({"conversations": chats}, ensure_ascii=False))
        except Exception as e:
            click.echo(json.dumps({"error": str(e)}))
            sys.exit(1)


@cli.command("get")
@click.argument("chat_id")
def get_chat(chat_id: str):
    """Retrieve a specific conversation by chat ID."""
    with _make_client() as glean:
        try:
            resp = glean.client.chat.retrieve(chat_id=chat_id)
            messages = []
            if hasattr(resp, "messages") and resp.messages:
                for msg in resp.messages:
                    text_parts = []
                    if hasattr(msg, "fragments") and msg.fragments:
                        for frag in msg.fragments:
                            if hasattr(frag, "text") and frag.text:
                                text_parts.append(frag.text)
                    author = getattr(msg, "author", None)
                    messages.append({
                        "author": str(author) if author else "unknown",
                        "text": "\n".join(text_parts),
                    })
            click.echo(json.dumps({"chat_id": chat_id, "messages": messages}, ensure_ascii=False))
        except Exception as e:
            click.echo(json.dumps({"error": str(e)}))
            sys.exit(1)


if __name__ == "__main__":
    cli()
