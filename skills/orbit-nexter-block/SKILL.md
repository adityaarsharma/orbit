---
name: orbit-nexter-block
description: Full automated block testing pipeline for Nexter Blocks Pro (the-plus-addons-for-block-editor-pro) — auto-inserts every block into the Gutenberg editor via wp.data, randomises ALL attribute controls to stress-test the PHP renderer, runs a deterministic value-verification pass (confirms option values actually appear in frontend HTML), publishes each post, and checks for PHP fatal errors, JS console errors, and broken renders. Also includes a UI-driven spec that physically clicks every sidebar control. Use when the user says "test all blocks", "run block tests", "smoke test blocks", "check frontend render", "verify options applied", "block controls test", or after fixing any block bug. Built with Playwright + wp.data store for Nexter Blocks Pro.
argument-hint: [--mode smoke|ui|all|quick] [--block tp-accordion] [--rounds 3] [--report]
---

# 🪐 orbit-nexter-block — Automated Block Testing Pipeline

Insert every block. Randomise every attribute. Verify option values appear on the frontend. Find crashes before users do.

---

## Quick start

```bash
cd <nexter-blocks-pro-root>

# Full suite — all 48 testable blocks (~12 min)
npm run test:blocks

# Quick sanity check — 1 round, no value verify (~4 min)
SMOKE_ROUNDS=1 SKIP_VERIFY=1 npm run test:blocks

# Single block
npx playwright test --project=block-smoke --grep "tp-accordion"

# Open the visual HTML dashboard
node scripts/generate-smoke-report.js
open tests/playwright/reports/smoke-report.html
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
# 1. Start the Docker test site
npx wp-env start

# 2. Install Playwright + Chromium
npm install
npx playwright install chromium

# 3. Generate block manifest (scans all block.json files)
node scripts/generate-block-manifest.js

# 4. Save admin session (once per wp-env boot)
npx playwright test tests/playwright/auth.setup.js --project=setup
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

**Why wp.data instead of clicking controls?**
The data-store approach hits the PHP render path with every possible attribute combination — 10× faster than UI clicking and tests every code path regardless of sidebar visibility.

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

### Attribute categories

| Category | Key pattern | Sentinel | Verification |
|---|---|---|---|
| `text-content` | `title`, `label`, `heading`, `btnText`, `daysText` | `TpVfy_<key>` | Must appear in `body.innerText()` |
| `style-class` | `style` (default `style-1`), `skin`, `variant` | `style-1` | Must appear in `body.innerHTML()` as CSS class |
| `boolean-flip` | Any `boolean` attribute | `true` | No crash = pass |
| `skip` | `url`, `color`, `size`, `image`, dates, API params | Default value | Not verified |

### Terminal output per block

```
  ✓ tpgb/tp-accordion   value-verify: 3/3 text attrs confirmed
  ~ tpgb/tp-cta-banner  value-verify: 1/2 text attrs confirmed (missed: subHeading)
  ⚠ tpgb/tp-flip-box    value-verify: 0/2 text attrs confirmed (missed: frontTitle, backTitle)
```

A **miss** is not a test failure — it means the attribute may require other conditions to render (inner blocks, JS hydration, sibling attributes).

---

## Run commands

| Command | What it does | Time |
|---|---|---|
| `npm run test:blocks` | Smoke suite — all 48 blocks, random attrs + value verify | ~12 min |
| `npm run test:blocks:ui` | Controls suite — sidebar click-through | ~25 min |
| `npm run test:blocks:all` | Both suites sequentially | ~40 min |
| `npm run test:report` | Open Playwright HTML report | instant |
| `npm run generate-manifest` | Rebuild block manifest from block.json files | 2s |

### Environment variables

| Variable | Default | Purpose |
|---|---|---|
| `SMOKE_ROUNDS` | `3` | Randomisation passes per block |
| `SKIP_VERIFY` | `0` | Set `1` to skip value-verification (faster) |
| `WP_BASE_URL` | `http://localhost:8881` | WordPress site URL |
| `WP_ADMIN_USER` | `admin` | Admin username |
| `WP_ADMIN_PASS` | `password` | Admin password |

---

## Block manifest

`scripts/generate-block-manifest.js` scans every `block.json` in `classes/blocks/` and outputs `tests/playwright/fixtures/block-manifest.json`.

### Manifest counts (Nexter Blocks Pro v4.7.3)

| Category | Count |
|---|---|
| Total blocks | 74 |
| Testable (top-level) | 48 |
| Child blocks (skipped — need parent) | 22 |
| Skipped (require API credentials) | 4 |

Child blocks are detected via the `parent` field in `block.json`. API-key blocks (Google Maps, Social Feed, Mailchimp, Social Reviews) are in the `SKIP_BLOCKS` set.

---

## File structure

```
<plugin-root>/
├── playwright.config.js              ← 3 projects: setup / block-smoke / block-controls
├── package.json                      ← npm scripts
│
├── scripts/
│   ├── generate-block-manifest.js    ← Scans block.json → fixtures/block-manifest.json
│   └── generate-smoke-report.js      ← JSON results → visual HTML dashboard
│
└── tests/playwright/
    ├── auth.setup.js                 ← Login once → fixtures/auth.json
    ├── block-smoke.spec.js           ← Main spec: random attrs + value verification
    ├── block-controls.spec.js        ← UI spec: sidebar click-through
    │
    ├── helpers/
    │   ├── randomizer.js             ← Type-safe random value generator
    │   ├── wp-editor.js              ← createDraftPost / insertBlock / publishPost
    │   ├── frontend-checker.js       ← PHP fatal / JS error detection / screenshots
    │   ├── attribute-verifier.js     ← Sentinel value verification
    │   └── sidebar-controls.js       ← Clicks toggles, selects, sliders, color pickers
    │
    ├── fixtures/
    │   ├── block-manifest.json       ← Auto-generated (74 blocks + attributes)
    │   └── auth.json                 ← Saved admin session
    │
    └── reports/
        ├── smoke-summary.json        ← Machine-readable results
        ├── smoke-report.html         ← Visual dashboard
        └── screenshots/              ← Frontend screenshot per block
```

---

## Randomiser strategy

`helpers/randomizer.js` generates type-safe random values for every attribute:

| Attribute type | Strategy |
|---|---|
| `string` (color key) | Random `#RRGGBB` hex |
| `string` (style selector) | `style-1` / `style-2` / `style-3` |
| `string` (date key) | Valid future ISO date |
| `string` (count/speed key) | `"1"` – `"20"` |
| `boolean` | `Math.random() > 0.5` |
| `number` / `integer` | `randInt(1, 20)` |
| `object` `{ md, sm, xs }` | `{ md: "24", sm: "", xs: "" }` |
| `object` `{ md, unit }` | `{ md: "16", unit: "px" }` |
| `array` | Default first item duplicated |
| `enum` | `pick(enumValues)` |

---

## Frontend checker — what counts as a failure

### Hard failures (block the test)
- `Fatal error:` in page body
- `Parse error:` in page body
- `Uncaught Error:` / `Uncaught Exception:` in page body
- `Call to undefined function/method` in page body
- `Allowed memory size` in page body

### Warnings (logged, non-fatal)
- JS `console.error` messages (filtered for plugin-origin)
- Block wrapper `<div class="tpgb-*">` not found in DOM
- HTTP 404 for plugin assets on localhost

---

## HTML report

```bash
node scripts/generate-smoke-report.js
open tests/playwright/reports/smoke-report.html
```

Report columns: Status | Block | Rounds passed | Block present | **Value verify %** | Console errors | Error messages | Frontend screenshot

The **Value verify %** column shows per-block verification scores with expandable detail of which attribute keys were confirmed vs missed in the frontend DOM.

---

## Real bugs found by this pipeline

### `tp-countdown` — `DateTime::__construct` crashes on non-date string
```
Uncaught Exception: Failed to parse time string (Heading Test) at position 0 (H)
in classes/blocks/tp-countdown/index.php on line 29
```
**Root cause:** `new DateTime( $attributes['datetime'] )` — no validation before constructor.
**Fix:** Wrapped in `try/catch`, wrapped `new DateTimeZone()` in `try/catch`, fallback to UTC.

### Pattern to watch for
- `new DateTime( $attr )` — always validate date format first
- `new DateTimeZone( $attr )` — always wrap in try/catch
- `array_keys( $attr )` — attribute may be a JSON string, decode first
- `is_array( $attr )` on Display Rules — block.json `string` type sends JSON string, not array

---

## Common errors + fixes

| Error | Cause | Fix |
|---|---|---|
| `Auth 401` / session expired | wp-env restarted | Re-run `auth.setup.js` |
| `block-manifest.json not found` | Manifest not generated | `node scripts/generate-block-manifest.js` |
| `Block "tpgb/x" not registered` | Block loads on specific page only | Add to `SKIP_BLOCKS` in manifest script |
| `PHP fatal on frontend` | Block crashes with random attribute value | Check screenshot → fix `render.php` |
| `Test timeout 120000ms` | `blocks.js` (8MB) parse time | Generate `blocks.min.js` |
| `port 8881 in use` | Previous wp-env container running | `lsof -ti:8881 \| xargs kill -9` |

---

## Pair with other Orbit skills

| Need | Skill |
|---|---|
| Full QA pipeline (lint + PHPCS + PHPStan + tests) | `/orbit-gauntlet` |
| Security audit (REST, IDOR, XSS) | `/orbit-wp-security` |
| block.json schema validation | `/orbit-block-json-validate` |
| Block render.php coverage | `/orbit-block-render-test` |
| Release readiness | `/orbit-release-gate` |
| Frontend performance + Lighthouse | `/orbit-wp-performance` |

---

## Sources & Evergreen References

- [wp.data dispatch API](https://developer.wordpress.org/block-editor/reference-guides/packages/packages-data/) — `dispatch('core/block-editor').updateBlockAttributes()`
- [wp.blocks.createBlock](https://developer.wordpress.org/block-editor/reference-guides/packages/packages-blocks/#createblock) — programmatic block insertion
- [block.json attribute schema](https://developer.wordpress.org/block-editor/reference-guides/block-api/block-metadata/#attributes) — attribute type reference
- [Playwright docs — storageState + fixtures](https://playwright.dev/docs/auth) — session reuse pattern
- [WP REST API — Posts](https://developer.wordpress.org/rest-api/reference/posts/) — post lifecycle
- [Gutenberg E2E tests](https://github.com/WordPress/gutenberg/tree/trunk/test/e2e) — upstream Playwright patterns

### Last reviewed
2026-05-08 — Nexter Blocks Pro v4.7.3, WP 6.9.4, PHP 8.2.30, Playwright 1.59.1
