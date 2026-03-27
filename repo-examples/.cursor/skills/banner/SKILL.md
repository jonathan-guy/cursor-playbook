---
name: banner
description: Toggle the dashboard update banner on or off. Use when the user invokes /banner, asks to show/hide the refresh banner, or mentions the "pixel dust" banner.
---

# Dashboard Update Banner

The executive dashboard (`dx-executive-dashboard.html`) has a built-in update banner that warns readers a data refresh is in progress. It lives just below the `<header>` element.

## Locating the banner

Search for `class="update-banner"` in `dx-executive-dashboard.html`. It looks like:

```html
<div class="update-banner" style="display:none">
  <span class="pulse-dot"></span>
  Pardon our pixel dust&ensp;&mdash;&ensp;data refresh in progress <code>DATE</code>. Numbers may shift.
</div>
```

## Showing the banner (refresh starting)

1. Remove `style="display:none"` from the `update-banner` div (or replace with `style=""`).
2. Update the `<code>` date to today's date (e.g., `3/24`).
3. Build and deploy: `just bundle && just build && just publish`.

## Hiding the banner (refresh complete)

1. Add `style="display:none"` to the `update-banner` div.
2. Build and deploy: `just bundle && just build && just publish`.

## Notes

- The banner CSS (`.update-banner`, `.pulse-dot`) is defined in the `<style>` block of `dx-executive-dashboard.html`. No external stylesheet changes needed.
- Do **not** delete the banner HTML — just toggle visibility so it's ready next time.
