---
description: Blockcell report formatting standard — auto-injected when editing report generators, lib/html.py, or shared styles
globs: reports/**/generate.py, reports/**/wireframes.py, lib/html.py, lib/components.css, lib/tokens.*
---

# Blockcell Report Formatting Standard

Universal formatting parameters for all Blockcell-hosted reports in this project. Apply these whenever creating or modifying a report.

## Layout

- **Max-width**: 1200px, horizontally centered.
- Apply to both the page title and the report body via `extra_head` CSS in each report's `generate.py`:

```css
h1, [data-component="report-body"] { max-width: 1200px; margin: 0 auto; }
```

- `lib/html.py`'s `render_report()` produces `<h1>{title}</h1>` followed by `<main data-component="report-body">`. The `h1` sits outside `<main>`, so both selectors are needed.

## Color Scheme

Dark theme. All colors come from `lib/tokens.css` custom properties — never hardcode hex values in report-specific CSS.

- **Backgrounds**: `--bg-base` (page), `--bg-surface` (cards/panels), `--bg-border` (borders), `--bg-hover` (interactive hover)
- **Text**: `--text-primary` (headings, values), `--text-secondary` (labels, descriptions), `--text-muted` (footnotes), `--text-body` (prose)
- **Accents**: `--accent-primary` (indigo, interactive elements), `--accent-success` (green), `--accent-warning` (amber), `--accent-danger` (red)
- **Charts**: Use `VR.color(i)` from `lib/charts.js` for chart series colors (indexes into `--chart-0` through `--chart-14`)

## Typography

System font stack via `--font-family`. Use token-based size variables:

| Token | Size | Use for |
|-------|------|---------|
| `--font-xs` | 10px | Footnotes, sort arrows |
| `--font-sm` | 11px | Labels, stat card details |
| `--font-md` | 12px | Table cells, descriptions |
| `--font-base` | 13px | Body text, filter labels |
| `--font-lg` | 14px | Chart titles, dropdown text |
| `--font-xl` | 18px | Section headers (h2) |
| `--font-2xl` | 22px | Page title (h1), stat values |

Font weights: `--font-normal` (400), `--font-semibold` (600), `--font-bold` (700).

## Spacing

Use token variables, not raw pixel values:

- `--sp-xs` (4px), `--sp-sm` (8px), `--sp-md` (12px), `--sp-lg` (16px), `--sp-xl` (24px), `--sp-2xl` (32px)
- Body padding: `var(--sp-xl)` (set in `lib/components.css`)

## Border Radii

- Cards and panels: `--radius-card` (10px)
- Inputs and smaller elements: `--radius-md` (8px)
- Tags and micro-elements: `--radius-sm` (4px)

## Shared Components

Use classes from `lib/components.css` rather than writing custom styles:

- `.stat-card` — metric value cards (with `.label`, `.value`, `.detail`)
- `.stat-row` — flex container for stat cards
- `.chart-box` — chart container (with `.title`, `.desc`)
- `.tbl-wrap` — scrollable table container (max-height 600px)
- `.insight` — callout box with colored left border
- `.sub-tabs` / `.sub-tab` — underline-style tab bar
- `.top-tabs` / `.top-tab` — pill-style tab bar
- `.filter-dropdown` — styled select element
- `.filter-bar` — flex container for filter controls

## Chart.js

- Use `VR.lineChart()`, `VR.barChart()` from `lib/charts.js` — they merge `VR.BASE_OPTS` automatically.
- `VR.BASE_OPTS` sets `maintainAspectRatio: false` and `responsive: true`. Charts size to their container.
- Wrap `<canvas>` elements in a container with explicit height (e.g., `<div style="height:280px">`) so Chart.js has a bounded parent.
- For direct `new Chart()` calls, merge with `VR.BASE_OPTS` via `Object.assign({}, VR.BASE_OPTS, yourOpts)`.

## Report Footer

`render_report()` auto-generates a footer with generation timestamp, data window, and links back to the executive dashboard and Signal Deck. No per-report footer CSS is needed.
