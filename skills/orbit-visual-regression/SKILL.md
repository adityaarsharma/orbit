---
name: orbit-visual-regression
description: Pixel-diff visual regression tests for a WordPress plugin's admin pages, frontend output, and admin colour-scheme variants. Catches unintended UI changes between releases. Includes responsive breakpoints (375 / 768 / 1440) and admin colour scheme matrix (default / midnight / coffee / etc.). Use when the user says "visual regression", "pixel diff", "screenshot diff", "responsive layout", "admin colors", "design refresh baseline".
---

# 🪐 orbit-visual-regression — Pixel-perfect UI testing

Catches the visual changes humans miss — a 2px shift in button padding, a colour drift, a layout break at 375px width.

---

## Quick start — diff against last baseline

```bash
# Run the visual project
npx playwright test --project=visual

# If anything regressed, see the diffs
npx playwright show-report reports/playwright-html
```

Each failure shows: expected (baseline) | actual (current) | diff (red highlight).

---

## Establish a baseline (first run, or after intentional redesign)

```bash
# Generate fresh baselines
npx playwright test --project=visual --update-snapshots

# Commit them — these are now the source of truth
git add tests/playwright/visual/__screenshots__/
git commit -m "baseline: v2.0 design refresh"
```

**Hard rule:** every visual baseline commit must reference the design intent. "baseline update" is not enough — "baseline: v2.0 design refresh" or "baseline: fix admin notice spacing" tells future you why.

---

## How it works

1. Playwright runs each test, navigates to a URL, takes a screenshot.
2. Compares the screenshot to `tests/playwright/visual/__screenshots__/<test>-<browser>.png`.
3. If pixels differ above threshold → fail with a diff image.

Threshold is configurable per test:
```js
await expect(page).toHaveScreenshot('settings.png', {
  maxDiffPixelRatio: 0.02,        // 2% pixels can differ
  animations: 'disabled',         // freeze CSS/JS animations
  caret: 'hide',                  // hide blinking cursor
  fullPage: false,                // viewport only (default)
});
```

---

## Responsive matrix (built-in)

```bash
# Mobile (375 × 667 — iPhone 8)
npx playwright test --project=mobile-chrome

# Tablet (768 × 1024 — iPad)
npx playwright test --project=tablet

# Desktop (1440 × 900)
npx playwright test --project=chromium
```

Each project produces its own snapshot folder. A button looking right on desktop but cramped at 375px → fails the mobile project, ships clean.

---

## Admin colour-scheme matrix

WordPress admin has 9 colour schemes (default, light, modern, blue, coffee, ectoplasm, midnight, ocean, sunrise). Hardcoded colours in your plugin break on at least one of them.

```bash
PLUGIN_ADMIN_SLUG=my-plugin-settings \
  npx playwright test --project=admin-colors
```

Output: `reports/screenshots/admin-colors/<scheme>-<page>.png` for every (scheme × page) combo. Open the report and visually scan — anything where your primary button is invisible against the background = bug.

---

## Visual UAT (Plugin A vs Plugin B)

For paired comparisons, this skill ships the `snapPair()` helper:

```js
await snapPair(page, 1, 'dashboard', 'a', SNAP);  // → pair-01-dashboard-a.png
// ... navigate to plugin B ...
await snapPair(page, 1, 'dashboard', 'b', SNAP);  // → pair-01-dashboard-b.png
```

The HTML report (`/orbit-uat-compare`) auto-pairs by slug — Social with Social, Settings with Settings.

---

## Configure URLs for visual checks

`qa.config.json`:

```json
{
  "visualUrls": [
    "/wp-admin/admin.php?page=my-plugin",
    "/wp-admin/admin.php?page=my-plugin-settings",
    "/wp-admin/admin.php?page=my-plugin-tools"
  ]
}
```

Playwright generates one snapshot per URL × per project. Add a URL → next run captures it as a new baseline.

---

## Pre-release visual diff vs previous tag

```bash
PLUGIN_PREV_TAG=v1.5.0 \
PLUGIN_VISUAL_URLS='["/wp-admin/admin.php?page=my-plugin"]' \
  npx playwright test --project=visual-release
```

This:
1. `git checkout v1.5.0` → captures baselines from old version
2. `git checkout main` → captures new screenshots
3. Diffs them
4. Restores HEAD

If diff > 2% on any page = unintended visual regression → block release until reviewed.

---

## Common false positives (and how to handle)

### Anti-aliasing differences across machines
```js
await expect(page).toHaveScreenshot('x.png', {
  threshold: 0.2,                  // per-pixel sensitivity (0-1)
  maxDiffPixelRatio: 0.02,         // global tolerance
});
```

### Animations
```js
await expect(page).toHaveScreenshot('x.png', {
  animations: 'disabled',          // freezes ALL CSS + JS animations
});
```

### Fonts loading async
```js
await page.evaluate(() => document.fonts.ready);  // wait for fonts
await expect(page).toHaveScreenshot('x.png');
```

### Date / time / random in UI
```js
// Mock Date.now before screenshot
await page.evaluate(() => { window.Date.now = () => 1714387200000; });
```

### Carousel / auto-rotating content
```js
// Pause it
await page.evaluate(() => window.myCarousel?.pause());
```

---

## When to update snapshots

| Trigger | Update? |
|---|---|
| Designer shipped a redesign | ✅ Yes — `--update-snapshots` + commit with the design rationale |
| Bug fix that changed UI by accident | ❌ No — fix the bug instead |
| Browser engine update changed anti-aliasing | ✅ Yes — note the engine version in the commit |
| Random pixel drift on CI vs local | Investigate first — usually a font / OS difference. Pin Docker image to fix permanently. |
| Test failed — "looks the same to me" | Open the diff in the report, zoom in. Pixels never lie. |

---

## Report

After every run:
- HTML: `reports/playwright-html/index.html` — pass/fail with diff images
- Raw: `tests/playwright/visual/__screenshots__/<test>-actual.png` (current run)
- Baseline: `tests/playwright/visual/__screenshots__/<test>-<browser>.png`
- Diff: `tests/playwright/visual/__screenshots__/<test>-diff.png`

For PMs, run `/orbit-reports` after to get a master HTML index.

---

## CI

```yaml
- run: npx playwright test --project=visual
- if: failure()
  uses: actions/upload-artifact@v4
  with:
    name: visual-failures
    path: tests/playwright/visual/__screenshots__/
```

On a CI failure, download the artefact and diff manually. Then either:
- Fix the bug → push, CI passes
- Confirm the change is intentional → run `--update-snapshots` locally, commit, push

Never blindly accept CI snapshot changes.

---

## Pair with `/orbit-accessibility`

Visual regression catches "did the UI change". Accessibility catches "is the UI usable for keyboard / screen reader". They overlap on **0%** — run both before any UI change.
