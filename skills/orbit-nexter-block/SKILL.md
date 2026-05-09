---
name: orbit-nexter-block
description: Full automated block testing pipeline for Nexter Blocks — covers BOTH the free plugin (the-plus-addons-for-block-editor, 57 blocks) and the Pro plugin (the-plus-addons-for-block-editor-pro, 74 blocks). Auto-inserts every block into the Gutenberg editor via wp.data, randomises ALL attribute controls to stress-test the PHP renderer, runs a deterministic value-verification pass (confirms option values actually appear in frontend HTML), publishes each post, and checks for PHP fatal errors, JS console errors, and broken renders. Also includes a UI-driven spec that physically clicks every sidebar control. Use when the user says "test all blocks", "run block tests", "smoke test blocks", "check frontend render", "verify options applied", "test free version", "block controls test", or after fixing any block bug. Built with Playwright + wp.data store.
argument-hint: [--version free|pro|all] [--mode smoke|ui|all|quick] [--block tp-accordion] [--rounds 3]
---

# 🪐 orbit-nexter-block — Automated Block Testing Pipeline

Insert every block. Randomise every attribute. Verify option values appear on the frontend. Covers **both** the free and Pro versions of Nexter Blocks.

---

## Quick start

```bash
cd <nexter-blocks-pro-root>

# Test Pro blocks only (~12 min)
npm run test:blocks

# Test Free blocks only (~8 min)
PLUGIN_VERSION=free npm run test:blocks

# Test both Free + Pro (~20 min)
PLUGIN_VERSION=all npm run test:blocks

# Quick sanity check — 1 round, no value verify (~4 min)
SMOKE_ROUNDS=1 SKIP_VERIFY=1 npm run test:blocks

# Single block
npx playwright test --project=block-smoke --grep "tp-heading"

# Open the visual HTML dashboard
node scripts/generate-smoke-report.js
open tests/playwright/reports/smoke-report.html
```

---

## Plugin overview

| Plugin | Slug | Blocks | Textdomain | Namespace |
|---|---|---|---|---|
| **Free** | `the-plus-addons-for-block-editor` | 57 | `the-plus-addons-for-block-editor` | `tpgb/` |
| **Pro** | `the-plus-addons-for-block-editor-pro` | 74 | `tpgbp` | `tpgb/` |

Both plugins are loaded simultaneously in `wp-env` — blocks from both are registered under the same `tpgb/` namespace and are testable in the same editor session.

---

## Block inventory

### Free-only blocks (35 unique to free)
```
tp-blockquote       tp-breadcrumbs      tp-button
tp-button-core      tp-code-highlighter tp-dark-mode
tp-draw-svg         tp-empty-space      tp-external-form-styler
tp-heading          tp-heading-title    tp-hovercard
tp-icon-box         tp-image            tp-infobox
tp-interactive-circle-info              tp-messagebox
tp-number-counter   tp-post-author      tp-post-comment
tp-post-content     tp-post-image       tp-post-meta
tp-post-title       tp-pricing-list     tp-pro-paragraph
tp-progress-bar     tp-progress-tracker tp-search-bar
tp-site-logo        tp-smooth-scroll    tp-social-embed
tp-social-icons     tp-stylist-list     tp-video
```

### Pro-only blocks (36 unique to Pro)
```
tp-adv-typo         tp-advanced-buttons tp-advanced-chart
tp-animated-service-boxes               tp-anything-carousel
tp-audio-player     tp-before-after     tp-carousel-remote
tp-circle-menu      tp-coupon-code      tp-cta-banner
tp-dynamic-category tp-dynamic-device   tp-expand
tp-heading-animation tp-hotspot         tp-login-register
tp-lottiefiles      tp-mailchimp        tp-media-listing
tp-mobile-menu      tp-mouse-cursor     tp-popup-builder
tp-post-navigation  tp-preloader        tp-process-steps
tp-product-listing  tp-repeater-block   tp-scroll-navigation
tp-scroll-sequence  tp-social-sharing   tp-spline-3d-viewer
tp-table-content    tp-timeline         tp-timeline-inner
```

### Shared blocks (22 in both plugins)
```
tp-accordion  tp-container  tp-countdown  tp-creative-image
tp-data-table tp-flipbox    tp-form-block tp-google-map
tp-tab        tp-team       tp-testimonial tp-toggle
tp-video-player tp-woo-listing tp-woo-single tp-woo-slider
```

> **Note:** When both plugins are active, the Pro version's `block.json` takes precedence for shared block names. Test the free version with the Pro plugin deactivated, or use the `PLUGIN_VERSION=free` flag.

---

## Free version testing

### Setup — test the free plugin in isolation

```bash
# Temporarily deactivate Pro plugin in wp-env
npx wp-env run cli wp plugin deactivate the-plus-addons-for-block-editor-pro

# Point the manifest generator at the free plugin
BLOCKS_DIR=../the-plus-addons-for-block-editor/classes/blocks \
  node scripts/generate-block-manifest.js

# Run smoke tests (free blocks only)
PLUGIN_VERSION=free npm run test:blocks

# Re-activate Pro after
npx wp-env run cli wp plugin activate the-plus-addons-for-block-editor-pro
```

### Free-specific checks

Beyond the standard crash / value verification checks, free version testing adds:

1. **No Pro leakage** — Free blocks must not call Pro-only PHP classes (`Tpgbp_Pro_Blocks_Helper`, `Tpgb_Pro_Library`, etc.)
2. **Textdomain consistency** — All `__()` calls in free blocks must use `'the-plus-addons-for-block-editor'`, not `'tpgbp'`
3. **Upsell UI** — Blocks that show upgrade prompts must not crash or produce empty output
4. **Shared block parity** — For blocks in both versions, the free `render.php` must produce valid HTML without Pro attributes

```bash
# Check for Pro class leakage in free plugin
grep -r "Tpgbp_" \
  "../the-plus-addons-for-block-editor/classes/blocks/" \
  --include="*.php" -l

# Check for wrong textdomain in free plugin
grep -r "'tpgbp'" \
  "../the-plus-addons-for-block-editor/" \
  --include="*.php"
```

### Free block manifest generation

```bash
# Generate manifest for free plugin
BLOCKS_DIR=../the-plus-addons-for-block-editor/classes/blocks \
  OUTPUT_FILE=tests/playwright/fixtures/block-manifest-free.json \
  node scripts/generate-block-manifest.js

# Run against free manifest
MANIFEST=block-manifest-free.json npm run test:blocks
```

---

## Prerequisites

| Tool | Version | Purpose |
|---|---|---|
| Node.js | 18+ | Playwright runner |
| Docker Desktop | 20+ | wp-env test site |
| wp-env | latest | WordPress at `http://localhost:8881` |
| Playwright | 1.59+ | Browser automation |

### One-time setup

```bash
# 1. Start the Docker test site (loads both free + Pro plugins)
npx wp-env start

# 2. Install Playwright + Chromium
npm install
npx playwright install chromium

# 3. Generate Pro block manifest
node scripts/generate-block-manifest.js

# 4. Save admin session (once per wp-env boot)
npx playwright test tests/playwright/auth.setup.js --project=setup
```

### `.wp-env.json` — both plugins loaded together

```json
{
  "core": null,
  "phpVersion": "8.2",
  "port": 8881,
  "plugins": [
    ".",
    "../the-plus-addons-for-block-editor",
    "https://downloads.wordpress.org/plugin/query-monitor.zip"
  ]
}
```

---

## What it tests — per block

```
1. Open Gutenberg editor      →  post-new.php + autosave to get post ID
2. Insert block               →  wp.blocks.createBlock() via wp.data
3. Randomise attributes × N   →  wp.data.dispatch(…).updateBlockAttributes()
4. Verification pass          →  set sentinel text values ("TpVfy_title" etc.)
5. Publish                    →  wp.data.dispatch('core/editor').savePost()
6. Visit frontend             →  new browser context (no admin cookies)
7. Assert — crash check       →  zero PHP fatals | no JS errors | screenshot saved
8. Assert — value check       →  sentinel values confirmed in rendered HTML
```

---

## Test suites

### `block-smoke.spec.js` — attribute randomisation + value verification

- Inserts each block via `wp.blocks.createBlock()`
- Applies **N rounds** of fully-randomised attribute sets (default `SMOKE_ROUNDS=3`)
- Runs one **deterministic verification pass** with sentinel values on text/label/title attributes
- Publishes and checks the frontend
- **Hard assertion:** zero PHP fatals
- **Soft check:** sentinel text values appear in the page (misses logged, not failures)

### `block-controls.spec.js` — sidebar UI interaction

- Inserts each block and **physically clicks** every visible control in the inspector sidebar
- Expands all panels, touches every toggle / select / slider / color-hex / button-group / radio
- Takes an editor screenshot, publishes, checks the frontend

---

## Attribute value verification

`helpers/attribute-verifier.js` answers: **"Does setting this option actually change the frontend output?"**

| Category | Key pattern | Sentinel | Verification |
|---|---|---|---|
| `text-content` | `title`, `label`, `heading`, `btnText` | `TpVfy_<key>` | Must appear in `body.innerText()` |
| `style-class` | `style` (default `style-1`), `skin` | `style-1` | Must appear in `body.innerHTML()` as CSS class |
| `boolean-flip` | Any `boolean` attribute | `true` | No crash = pass |
| `skip` | `url`, `color`, `size`, `image`, dates | Default value | Not verified |

### Terminal output per block

```
  ✓ tpgb/tp-accordion  value-verify: 3/3 text attrs confirmed
  ~ tpgb/tp-heading    value-verify: 1/2 text attrs confirmed (missed: subTitle)
  ⚠ tpgb/tp-flipbox    value-verify: 0/2 text attrs confirmed (missed: frontTitle)
```

---

## Run commands

| Command | What it does | Time |
|---|---|---|
| `npm run test:blocks` | Smoke — Pro blocks, random + value verify | ~12 min |
| `PLUGIN_VERSION=free npm run test:blocks` | Smoke — Free blocks only | ~8 min |
| `PLUGIN_VERSION=all npm run test:blocks` | Smoke — Free + Pro blocks | ~20 min |
| `npm run test:blocks:ui` | Controls suite — sidebar click-through | ~25 min |
| `npm run test:blocks:all` | Smoke + controls suites | ~40 min |
| `npm run generate-manifest` | Rebuild Pro block manifest | 2s |

### Environment variables

| Variable | Default | Purpose |
|---|---|---|
| `PLUGIN_VERSION` | `pro` | `free` / `pro` / `all` — which blocks to test |
| `SMOKE_ROUNDS` | `3` | Randomisation passes per block |
| `SKIP_VERIFY` | `0` | Set `1` to skip value-verification (faster) |
| `WP_BASE_URL` | `http://localhost:8881` | WordPress site URL |

---

## Block manifest counts

| Version | Total | Testable | Child blocks | API-skip |
|---|---|---|---|---|
| **Free** | 57 | ~35 | ~18 | 2 |
| **Pro** | 74 | 48 | 22 | 4 |
| **Combined** | ~107 unique | ~75 | ~30 | 5 |

---

## File structure

```
<plugin-root>/
├── playwright.config.js
├── package.json
├── scripts/
│   ├── generate-block-manifest.js    ← Scans block.json → manifest
│   └── generate-smoke-report.js      ← JSON → visual HTML dashboard
└── tests/playwright/
    ├── auth.setup.js
    ├── block-smoke.spec.js           ← Random attrs + value verification
    ├── block-controls.spec.js        ← Sidebar click-through
    ├── helpers/
    │   ├── randomizer.js             ← Type-safe random value generator
    │   ├── wp-editor.js              ← createDraftPost / insertBlock / publishPost
    │   ├── frontend-checker.js       ← PHP fatal / JS error / screenshots
    │   ├── attribute-verifier.js     ← Sentinel value verification
    │   └── sidebar-controls.js       ← Clicks toggles, selects, sliders
    ├── fixtures/
    │   ├── block-manifest.json       ← Pro blocks (auto-generated)
    │   ├── block-manifest-free.json  ← Free blocks (auto-generated)
    │   └── auth.json
    └── reports/
        ├── smoke-summary.json
        ├── smoke-report.html
        └── screenshots/
```

---

## Frontend checker — failure modes

### Hard failures (fail the test)
- `Fatal error:` / `Parse error:` / `Uncaught Exception:` in page body
- `Call to undefined function/method` in page body
- `Allowed memory size` in page body

### Free-version specific warnings
- `class 'Tpgbp_Pro_Blocks_Helper' not found` — Pro class called from free block
- `undefined function tpgbp_` — Pro helper called from free render

---

## Real bugs found by this pipeline

### `tp-countdown` — `DateTime::__construct` crashes on non-date string
```
Uncaught Exception: Failed to parse time string (Heading Test) at position 0 (H)
in classes/blocks/tp-countdown/index.php on line 29
```
**Fix:** Wrapped `new DateTime()` and `new DateTimeZone()` in `try/catch`, fallback to UTC.
**Affects:** Both free and Pro versions.

### Display Rules — `is_array()` fails on JSON-encoded string attributes
**Root cause:** 10 check functions received JSON-encoded strings but tested `is_array()` — always false, breaking all display conditions.
**Fix:** Added `json_decode()` guard at the start of each check function.
**Affects:** Pro version only.

---

## Common errors + fixes

| Error | Cause | Fix |
|---|---|---|
| `Auth 401` / session expired | wp-env restarted | Re-run `auth.setup.js` |
| `block-manifest.json not found` | Manifest not generated | `node scripts/generate-block-manifest.js` |
| `Block "tpgb/x" not registered` | Block loads on specific page only | Add to `SKIP_BLOCKS` |
| `class 'Tpgbp_...' not found` | Free block calling Pro class | Add `class_exists()` guard |
| `Test timeout 120000ms` | `blocks.js` (8MB) parse time | Generate `blocks.min.js` |
| `port 8881 in use` | Previous wp-env container | `lsof -ti:8881 \| xargs kill -9` |

---

## Pair with other Orbit skills

| Need | Skill |
|---|---|
| Full QA pipeline (lint + PHPCS + PHPStan + tests) | `/orbit-gauntlet` |
| Security audit (REST, IDOR, XSS) | `/orbit-wp-security` |
| block.json schema validation | `/orbit-block-json-validate` |
| Block render.php coverage | `/orbit-block-render-test` |
| i18n / textdomain audit | `/orbit-i18n` |
| Release readiness | `/orbit-release-gate` |

---

## Sources & Evergreen References

- [wp.data dispatch API](https://developer.wordpress.org/block-editor/reference-guides/packages/packages-data/)
- [wp.blocks.createBlock](https://developer.wordpress.org/block-editor/reference-guides/packages/packages-blocks/#createblock)
- [block.json attribute schema](https://developer.wordpress.org/block-editor/reference-guides/block-api/block-metadata/#attributes)
- [wp-env documentation](https://developer.wordpress.org/block-editor/reference-guides/packages/packages-env/)
- [Playwright — storageState + fixtures](https://playwright.dev/docs/auth)
- [Gutenberg E2E tests](https://github.com/WordPress/gutenberg/tree/trunk/test/e2e)

### Last reviewed
2026-05-09 — Free v1.x / Pro v4.7.3, WP 6.9.4, PHP 8.2.30, Playwright 1.59.1
