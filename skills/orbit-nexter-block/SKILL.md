---
name: orbit-nexter-block
description: Full automated block testing pipeline for Nexter Blocks — covers BOTH the free plugin (the-plus-addons-for-block-editor, 57 blocks) and the Pro plugin (the-plus-addons-for-block-editor-pro, 74 blocks). Auto-inserts every block into the Gutenberg editor via wp.data, randomises ALL attributes declared in block.json (98% coverage — 4082/4151 attrs), runs a deterministic value-verification pass, publishes each post, and checks for PHP fatal errors, JS console errors, and broken renders. Also includes a UI-driven spec that physically clicks every sidebar control. Use when the user says "test all blocks", "run block tests", "smoke test blocks", "check all attributes", "verify options applied", "test free version", or after fixing any block bug. Built with Playwright + wp.data store.
argument-hint: [--version free|pro|all] [--mode smoke|ui|all|quick] [--block tp-accordion] [--rounds 3]
---

# 🪐 orbit-nexter-block — Automated Block Testing Pipeline

Insert every block. Randomise **every attribute in block.json**. Verify option values appear on the frontend. Covers both the free and Pro versions of Nexter Blocks.

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

# Attribute coverage audit
node scripts/generate-block-manifest.js --report

# Open the visual HTML dashboard
node scripts/generate-smoke-report.js
open tests/playwright/reports/smoke-report.html
```

---

## Attribute coverage — all block.json attrs tested

The manifest generator reads **every attribute** from every `block.json` and classifies it into one of four test categories. Current coverage for Nexter Blocks Pro v4.7.3:

| Category | Count | How tested |
|---|---|---|
| **text-content** | ~600 | Sentinel string set → must appear in frontend HTML |
| **style-class** | ~200 | Known value (`style-1`) → must appear as CSS class |
| **boolean-flip** | ~800 | Set `true` → assert no PHP crash |
| **css-inject** (`scopy:true`) | 2704 | Valid hex colour → assert no CSS injection crash |
| **skip** (internal) | 69 | `block_id`, `className` — not randomised |
| **Total tested** | **4082 / 4151** | **98% attribute coverage** |

The only excluded attributes are `block_id`, `className`, `lock`, `anchor` — internal WordPress IDs that must not be randomised.

### Attribute categories explained

| Category | Key pattern | What it does | Verified how |
|---|---|---|---|
| `text-content` | `title`, `label`, `heading`, `btnText`, `daysText` | Renders as visible text | Sentinel `TpVfy_<key>` found in `body.innerText()` |
| `style-class` | `style` (default `style-1`), `skin`, `variant` | Becomes a CSS class modifier | Value found in `body.innerHTML()` as class |
| `boolean-flip` | Any `boolean` type | Toggles a feature on/off | Set `true` → no PHP crash |
| `css-inject` | Has `scopy:true` + `style` array | Injects CSS via `<style>` tag | Valid hex set → no crash, no broken `<style>` |
| `skip` | `block_id`, `className`, `anchor`, `lock` | Internal WordPress identifiers | Default value preserved |

### CSS-inject attributes (Nexter scopy system)

These are colour and style attributes unique to Nexter Blocks. Each stores a CSS value that is injected into a `<style>` tag at render time via the `scopy` engine:

```json
{
  "titleColor": {
    "type": "string",
    "default": "",
    "scopy": true,
    "style": [{ "selector": "{{PLUS_WRAP}} .title { color: {{titleColor}}; }" }]
  }
}
```

**Previous behaviour:** These were accidentally excluded from testing (filter bug — `default: ""` was treated as "no default").
**Current behaviour:** All 2704 `scopy` attrs are randomised with a valid hex colour (`#e74c3c`) and the renderer is asserted to produce no PHP fatals.

---

## Plugin overview

| Plugin | Slug | Blocks | Textdomain | Namespace |
|---|---|---|---|---|
| **Free** | `the-plus-addons-for-block-editor` | 57 | `the-plus-addons-for-block-editor` | `tpgb/` |
| **Pro** | `the-plus-addons-for-block-editor-pro` | 74 | `tpgbp` | `tpgb/` |

Both plugins are loaded simultaneously in `wp-env`. Both share the `tpgb/` namespace.

---

## Block inventory

### Free-only blocks (35)
```
tp-blockquote  tp-breadcrumbs  tp-button  tp-button-core  tp-code-highlighter
tp-dark-mode   tp-draw-svg     tp-empty-space  tp-external-form-styler
tp-heading     tp-heading-title  tp-hovercard  tp-icon-box  tp-image
tp-infobox     tp-interactive-circle-info  tp-messagebox  tp-number-counter
tp-post-author tp-post-comment  tp-post-content  tp-post-image  tp-post-meta
tp-post-title  tp-pricing-list  tp-pro-paragraph  tp-progress-bar
tp-progress-tracker  tp-search-bar  tp-site-logo  tp-smooth-scroll
tp-social-embed  tp-social-icons  tp-stylist-list  tp-video
```

### Pro-only blocks (36)
```
tp-adv-typo  tp-advanced-buttons  tp-advanced-chart  tp-animated-service-boxes
tp-anything-carousel  tp-audio-player  tp-before-after  tp-carousel-remote
tp-circle-menu  tp-coupon-code  tp-cta-banner  tp-dynamic-category
tp-dynamic-device  tp-expand  tp-heading-animation  tp-hotspot  tp-login-register
tp-lottiefiles  tp-mailchimp  tp-media-listing  tp-mobile-menu  tp-mouse-cursor
tp-popup-builder  tp-post-navigation  tp-preloader  tp-process-steps
tp-product-listing  tp-repeater-block  tp-scroll-navigation  tp-scroll-sequence
tp-social-sharing  tp-spline-3d-viewer  tp-table-content  tp-timeline  tp-timeline-inner
```

### Shared blocks (22 in both)
```
tp-accordion  tp-container  tp-countdown  tp-creative-image  tp-data-table
tp-flipbox    tp-form-block  tp-google-map  tp-tab  tp-team  tp-testimonial
tp-toggle  tp-video-player  tp-woo-listing  tp-woo-single  tp-woo-slider
```

> When both plugins are active, the Pro version's `block.json` takes precedence for shared blocks. Test the free version with the Pro plugin deactivated, or use `PLUGIN_VERSION=free`.

---

## Free version testing

### Isolate and test the free plugin

```bash
# Deactivate Pro
npx wp-env run cli wp plugin deactivate the-plus-addons-for-block-editor-pro

# Generate free manifest
BLOCKS_DIR=../the-plus-addons-for-block-editor/classes/blocks \
  OUTPUT_FILE=tests/playwright/fixtures/block-manifest-free.json \
  node scripts/generate-block-manifest.js

# Run smoke tests against free manifest
PLUGIN_VERSION=free MANIFEST=block-manifest-free.json npm run test:blocks

# Re-activate Pro
npx wp-env run cli wp plugin activate the-plus-addons-for-block-editor-pro
```

### Free-specific checks

1. **No Pro leakage** — Free blocks must not call Pro-only PHP classes
2. **Textdomain** — All `__()` calls must use `'the-plus-addons-for-block-editor'`, not `'tpgbp'`
3. **Upsell UI safety** — Blocks with upgrade prompts must not crash or show empty output
4. **Shared block parity** — Free `render.php` must produce valid HTML without Pro attributes

```bash
# Check for Pro class leakage in free plugin
grep -r "Tpgbp_" "../the-plus-addons-for-block-editor/classes/blocks/" --include="*.php" -l

# Check for wrong textdomain
grep -r "'tpgbp'" "../the-plus-addons-for-block-editor/" --include="*.php"
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
npx wp-env start
npm install && npx playwright install chromium
node scripts/generate-block-manifest.js
npx playwright test tests/playwright/auth.setup.js --project=setup
```

---

## What it tests — per block

```
1. Open Gutenberg editor      →  post-new.php + autosave to get post ID
2. Insert block               →  wp.blocks.createBlock() via wp.data
3. Randomise ALL attributes   →  text→random text, bool→random bool,
                                  css-inject→valid hex, style→style-N
4. Verification pass          →  sentinel text values ("TpVfy_title" etc.)
5. Publish                    →  wp.data.dispatch('core/editor').savePost()
6. Visit frontend             →  new browser context (no admin cookies)
7. Assert — crash check       →  zero PHP fatals | no JS errors | screenshot saved
8. Assert — value check       →  sentinel text appears in rendered HTML
```

---

## Run commands

| Command | Time | What it does |
|---|---|---|
| `npm run test:blocks` | ~12 min | Smoke — Pro blocks, all attrs randomised + value verify |
| `PLUGIN_VERSION=free npm run test:blocks` | ~8 min | Smoke — Free blocks only |
| `PLUGIN_VERSION=all npm run test:blocks` | ~20 min | Smoke — Free + Pro |
| `npm run test:blocks:ui` | ~25 min | Controls — sidebar click-through |
| `npm run test:blocks:all` | ~40 min | Both suites |
| `npm run generate-manifest` | 2s | Rebuild manifest (re-runs attribute coverage audit) |

### Environment variables

| Variable | Default | Purpose |
|---|---|---|
| `PLUGIN_VERSION` | `pro` | `free` / `pro` / `all` — which blocks to test |
| `SMOKE_ROUNDS` | `3` | Randomisation passes per block |
| `SKIP_VERIFY` | `0` | `1` = skip value-verification (faster) |
| `WP_BASE_URL` | `http://localhost:8881` | WordPress site URL |

---

## File structure

```
<plugin-root>/
├── scripts/
│   ├── generate-block-manifest.js    ← Scans ALL block.json attrs → manifest
│   └── generate-smoke-report.js      ← JSON → visual HTML dashboard
└── tests/playwright/
    ├── block-smoke.spec.js           ← Random attrs + value verification
    ├── block-controls.spec.js        ← Sidebar click-through
    ├── helpers/
    │   ├── randomizer.js             ← Type-safe random values (incl. css-inject)
    │   ├── wp-editor.js              ← createDraftPost / insertBlock / publishPost
    │   ├── frontend-checker.js       ← PHP fatal / JS error / screenshots
    │   ├── attribute-verifier.js     ← Sentinel value + css-inject verification
    │   └── sidebar-controls.js       ← Clicks toggles, selects, sliders
    └── fixtures/
        ├── block-manifest.json       ← Pro blocks — 4082 attrs (98% coverage)
        └── block-manifest-free.json  ← Free blocks
```

---

## Frontend checker — failure modes

### Hard failures (fail the test)
- `Fatal error:` / `Parse error:` / `Uncaught Exception:` in page body
- `Call to undefined function/method` in page body
- `Allowed memory size` in page body

### Free-version specific
- `class 'Tpgbp_Pro_Blocks_Helper' not found` — Pro class called from free block
- `undefined function tpgbp_` — Pro helper called from free render

---

## Real bugs found by this pipeline

### `tp-countdown` — `DateTime::__construct` crashes on non-date string
**Root cause:** `new DateTime( $attributes['datetime'] )` — randomiser set `datetime` to `"Heading Test"`.
**Fix:** Wrapped in `try/catch`, fallback to UTC. Affected both free and Pro.

### Display Rules — `is_array()` always false on JSON-encoded string attributes
**Root cause:** 10 check functions received JSON-encoded strings (`"[{\"value\":\"post\"}]"`) but tested `is_array()`.
**Fix:** Added `json_decode()` guard. Pro only.

### 755 CSS-injection attrs silently excluded from testing (manifest bug)
**Root cause:** `if (def.style && !def.default)` treated `default: ""` as "no default", excluding all `scopy` colour attrs.
**Fix:** Changed filter to detect only WP style-binding objects (`!Array.isArray(def.style)`). Coverage: 80% → 98%.

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
