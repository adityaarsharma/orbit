# Orbit — Complete Role-by-Role Guide

> Every command. Every script. Every test file. Every report. Nothing skipped.
> Find your role, follow your section. 20 minutes to fully operational.

---

## Understanding the Two Core Tools First

Before roles — two things power everything. You need to understand both.

---

### What is the Gauntlet?

`bash scripts/gauntlet.sh` is the **master pipeline**. It's a single command that runs 12 automated checks in sequence, one after another, and hands you a complete report at the end.

Think of it like this: you're a pilot about to take off. The gauntlet is the pre-flight checklist — except instead of you manually checking 40 items, a machine checks all 12 layers automatically in ~15 minutes.

```
bash scripts/gauntlet.sh --plugin ~/plugins/your-plugin
    │
    ├─ Step 1   PHP Lint          → every .php file, zero syntax errors required
    ├─ Step 1a  Release Metadata  → plugin header, readme.txt, version parity, license
    ├─ Step 1b  Zip Hygiene       → no eval(), no error_log(), no dev files in zip
    ├─ Step 2   PHPCS             → WordPress + VIP coding standards, security rules
    ├─ Step 3   PHPStan           → static analysis, type safety, undefined vars
    ├─ Step 4   Asset Weight      → JS/CSS bundle sizes, regression vs last release
    ├─ Step 5   i18n / POT        → translatable strings, text-domain check
    ├─ Step 6   Playwright        → real browser: functional + visual + a11y tests
    ├─ Step 7   Lighthouse        → performance score (target 80+), Core Web Vitals
    ├─ Step 8   DB Profiling      → query count, slow queries >100ms, N+1 patterns
    ├─ Step 9   Competitor        → downloads + analyzes your competitor plugins
    ├─ Step 10  UI Performance    → Elementor/Gutenberg editor load + widget insert time
    ├─ Step 11  Claude Skills     → 6 AI agents read your code (security, perf, a11y...)
    └─ Step 12  PM UX Audit       → spell-check + guided experience score + label audit
         │
         ▼
reports/
├── qa-report-TIMESTAMP.md           ← full summary (Dev + QA read this)
├── playwright-html/index.html       ← visual test report (QA + Designer)
├── skill-audits/index.html          ← AI audit report (Dev)
├── pm-ux/pm-ux-report-TIMESTAMP.html ← PM UX report (PM reads this)
├── uat-report-TIMESTAMP.html        ← UAT comparison report (PM)
└── lighthouse/lh-TIMESTAMP.json    ← performance data (PA)
```

**The gauntlet exits 0 (pass) or 1 (fail).** Exit 1 means: do not release.

**Three modes:**
```bash
# Quick — PHP lint + PHPCS + PHPStan + assets only. ~2 min. Use during development.
bash scripts/gauntlet.sh --plugin ~/plugins/your-plugin --mode quick

# Full — all 12 steps. ~15 min. Use before every release.
bash scripts/gauntlet.sh --plugin ~/plugins/your-plugin --mode full

# Release — full + stricter thresholds (zero warnings allowed). Use before tagging.
bash scripts/gauntlet.sh --plugin ~/plugins/your-plugin --mode release
```

---

### What is Playwright?

Playwright is a browser automation framework (made by Microsoft). It controls a real Chrome/Firefox/Safari browser from code. You write JavaScript test files that say: "go to this URL, click this button, check this text appears, take a screenshot." Playwright runs the real browser. It sees the real page.

**Playwright is Step 6 of the gauntlet — but you can also run it independently.**

```
Gauntlet = the full 12-step pre-flight checklist
Playwright = just the "test it in a real browser" step (Step 6)
```

When you run Playwright directly:
```bash
WP_TEST_URL=http://localhost:8881 \
npx playwright test tests/playwright/your-plugin/
```

It runs only the browser tests — no PHP lint, no PHPCS, no Lighthouse. Faster (2–3 min). Use this during development when you only want to check browser behavior.

**Four ways to watch Playwright run:**

| Mode | Command | When to Use |
|------|---------|-------------|
| UI Mode (interactive) | `npx playwright test --ui` | Daily testing — see DOM at every step |
| Headed (watch browser) | `npx playwright test --headed --slowMo=500` | Demo or visual verification |
| Debug (step by step) | `npx playwright test --debug` | Test is failing and you can't see why |
| Trace (post-mortem) | `npx playwright show-trace trace.zip` | Test failed on another machine or CI |

---

### The Test Site (Required for Playwright + DB Profiling)

Playwright needs a real WordPress site to test against. Orbit creates one in Docker:

```bash
# One command — creates WP + MySQL in Docker, installs your plugin, activates it
bash scripts/create-test-site.sh --plugin ~/plugins/your-plugin --port 8881

# For multisite testing (WP Network)
bash scripts/create-test-site.sh --plugin ~/plugins/your-plugin --port 8882 --multisite
```

Site lives at `http://localhost:8881` · Admin: `http://localhost:8881/wp-admin` · Login: `admin` / `password`

**Site lifecycle:**
```bash
wp-env stop                      # pause (keeps data)
wp-env start                     # resume
wp-env destroy                   # delete everything
wp-env clean all                 # reset DB to fresh state (keeps containers)
wp-env run cli wp <command>      # run any WP-CLI command inside the container
```

**Alternative — no Docker:**
```bash
cd ~/plugins/your-plugin
wp-now start                     # spins up WP in seconds, no Docker needed
# → http://localhost:8881 — plugin already active
```
Use `wp-now` for quick checks. Use `wp-env` for full gauntlet, DB profiling, and multisite.

---

## One-Time Setup (Everyone Does This Once)

```bash
# 1. Clone Orbit
git clone https://github.com/adityaarsharma/orbit
cd orbit

# 2. Interactive setup wizard — 9 questions, creates qa.config.json
bash setup/init.sh

# 3. Install all tools
bash scripts/install-power-tools.sh

# 4. Pre-flight check — verifies every tool is installed before you run anything
bash scripts/gauntlet-dry-run.sh
```

`qa.config.json` is created by `init.sh`. It stores your plugin path, type, admin slug, competitors, and more. Every subsequent command reads from it — you never repeat yourself.

---

## 🧑‍💻 ROLE 1: Developer

**Your job**: Catch bugs before QA. Code quality, security, compatibility, static analysis.

### Your Commands

```bash
# During development — fast iteration (PHP lint + PHPCS + PHPStan only, ~2 min)
bash scripts/gauntlet.sh --plugin ~/plugins/your-plugin --mode quick

# Before every PR — includes assets + i18n + Playwright (~8 min)
bash scripts/gauntlet.sh --plugin ~/plugins/your-plugin

# Before every release tag — all 12 steps, strict mode (~15 min)
bash scripts/gauntlet.sh --plugin ~/plugins/your-plugin --mode release
```

### What Steps 1–5 Check (Your Territory)

**Step 1 — PHP Lint**
```bash
find ~/plugins/your-plugin -name "*.php" -exec php -l {} \;
```
Catches fatal syntax errors — the ones that white-screen the site. Every `.php` file. Zero errors allowed.

**Step 1a — Release Metadata** (runs `check-plugin-header.sh`, `check-readme-txt.sh`, `check-version-parity.sh`, `check-license.sh`, `check-wp-compat.sh`)
```bash
bash scripts/check-plugin-header.sh ~/plugins/your-plugin   # Plugin Name, Author, Version, requires
bash scripts/check-readme-txt.sh ~/plugins/your-plugin       # stable tag, tested up to, sections
bash scripts/check-version-parity.sh ~/plugins/your-plugin   # plugin header version == readme.txt stable tag
bash scripts/check-license.sh ~/plugins/your-plugin          # GPL-compatible license declared
bash scripts/check-wp-compat.sh ~/plugins/your-plugin        # Requires WP / Tested Up To headers valid
```

**Step 1b — Zip Hygiene** (runs `check-zip-hygiene.sh`)
```bash
bash scripts/check-zip-hygiene.sh ~/plugins/your-plugin
```
Catches: `eval()` usage, `error_log()` left in, `.DS_Store`, `node_modules/`, `composer.json` exposed, supply-chain indicators (unexpected remote URLs in PHP).

**Step 2 — PHPCS (WordPress + VIP Coding Standards)**
```bash
phpcs --standard=config/phpcs.xml ~/plugins/your-plugin
```
Catches: missing nonces on AJAX handlers, unescaped output (`echo $_GET['x']` → XSS), raw SQL without `$wpdb->prepare()`, wrong capability checks, direct `$_POST` access, `extract()` usage.

**Step 3 — PHPStan (Static Analysis)**
```bash
phpstan analyse ~/plugins/your-plugin --configuration=config/phpstan.neon
```
Catches: undefined variables, calling methods that don't exist, wrong parameter types, dead code paths, functions that can return `null` used without null check.

**Step 4 — Asset Weight**
```bash
# Auto-runs in gauntlet but can run standalone:
find ~/plugins/your-plugin/assets -name "*.js" -o -name "*.css" | xargs ls -lh
```
Baseline is set on first run. Every subsequent run diffs. If your JS bundle grows by 200KB, gauntlet warns.

**Step 5 — i18n / POT**
```bash
bash scripts/check-translation.sh ~/plugins/your-plugin
# Or directly:
wp i18n make-pot ~/plugins/your-plugin ~/plugins/your-plugin/languages/your-plugin.pot
```
Catches: strings not wrapped in `__()` / `esc_html__()`, wrong text domain (`'wordpress'` instead of your slug), missing `.pot` file.

### Security Deep-Dive (Run Before Every Release)

```bash
# Full OWASP audit via Claude Code
claude "/wordpress-penetration-testing Audit ~/plugins/your-plugin for all OWASP Top 10 vulnerabilities. Report by severity: critical → high → medium → low."

# Specific file audit
claude "/wordpress-penetration-testing Check ~/plugins/your-plugin/includes/ajax-handlers.php for SQL injection, CSRF, and privilege escalation vulnerabilities"

# WP-specific standards audit
claude "/wordpress-plugin-development Review ~/plugins/your-plugin for WP coding standards violations, missing escaping, nonce misuse, and improper capability checks"
```

### Live CVE Correlation (Unique to Orbit)

```bash
bash scripts/check-live-cve.sh ~/plugins/your-plugin
```

What it does: downloads the last 60 days of WordPress CVEs from NVD (NIST National Vulnerability Database) + Wordfence public feed. Extracts the vulnerable code patterns from each CVE. Greps your plugin code for matching patterns. Reports correlations with severity.

**Free, no API keys, 24-hour cache** — so it doesn't hammer the API on every run.

### Ownership Transfer Detection (First in WP Ecosystem)

```bash
bash scripts/check-ownership-transfer.sh ~/plugins/your-plugin
```

Reads the git history of your main plugin file. Flags if the `Author:`, `Author URI:`, or `Plugin Name:` header changed between commits. Defends against the April 2026 EssentialPlugin attack pattern: attacker buys a plugin → pushes backdoored "update" weeks later → users auto-update without noticing the author changed.

### PHP Compatibility Check

```bash
bash scripts/check-php-compat.sh ~/plugins/your-plugin
```

Tests your code against PHP 7.4, 8.0, 8.1, 8.2, 8.3 via `php -l` + PHPCompatibility sniffs. Catches: named arguments (PHP 8.0+ only), match expressions, nullsafe operator, `readonly` properties — all break on older PHP.

### Modern WordPress Patterns Check

```bash
bash scripts/check-modern-wp.sh ~/plugins/your-plugin    # WP 6.5+ APIs
bash scripts/check-block-json.sh ~/plugins/your-plugin   # block.json format (Gutenberg)
bash scripts/check-hpos-declaration.sh ~/plugins/your-plugin  # WooCommerce HPOS compat
bash scripts/check-object-cache.sh ~/plugins/your-plugin # proper transient/cache usage
bash scripts/check-gdpr-hooks.sh ~/plugins/your-plugin   # personal_data_exporter, eraser hooks
bash scripts/check-login-assets.sh ~/plugins/your-plugin # no assets loading on login page unnecessarily
```

### Changelog → Targeted Test Map

```bash
bash scripts/changelog-test.sh --changelog ~/plugins/your-plugin/CHANGELOG.md
```

Reads your changelog, generates a test plan per entry:
```
[NEW] Bulk export feature
  → Test: Export button visible in admin list table
  → Test: CSV downloads with correct column headers
  → Test: Export 1000 items completes under 30s timeout

[SECURITY] Added nonce to AJAX export handler
  → Run: /wordpress-penetration-testing on includes/ajax-export.php
  → Test: AJAX request without nonce returns 403
```

### Version Comparison

```bash
bash scripts/compare-versions.sh \
  --old ~/downloads/your-plugin-v1.3.zip \
  --new ~/downloads/your-plugin-v1.4.zip
```

Compares: PHPCS error count, JS bundle size (KB), CSS bundle size (KB). Shows if you regressed or improved.

### Pre-Commit Hook (Auto-Gauntlet on Every Commit)

```bash
# Run from inside your plugin's git repo
ORBIT_ROOT=~/orbit bash ~/orbit/scripts/install-pre-commit-hook.sh
```

After this: every `git commit` automatically runs the quick gauntlet. Fails the commit if issues found. Bypass with `git commit --no-verify` (use sparingly).

### Your Read After Gauntlet

```bash
cat reports/qa-report-*.md
```
Lines starting with `✗` = hard fail. Lines starting with `⚠` = warning. Lines starting with `✓` = passed.

### Your Checklists

```bash
open checklists/pre-release-checklist.md    # Dev section sign-off
open checklists/security-checklist.md       # XSS, CSRF, SQLi, auth checks
```

---

## 🧪 ROLE 2: QA Tester

**Your job**: Real browser. Real flows. Catch broken behavior, visual regressions, accessibility failures, edge cases.

### Setup (One-Time)

```bash
# Create test site
bash scripts/create-test-site.sh --plugin ~/plugins/your-plugin --port 8881

# Save admin cookies (do once — lasts until you destroy the site)
WP_TEST_URL=http://localhost:8881 \
npx playwright test tests/playwright/auth.setup.js --project=setup
```

### Your Daily Commands

```bash
# Run all tests for your plugin
WP_TEST_URL=http://localhost:8881 \
npx playwright test tests/playwright/your-plugin/

# Interactive UI mode — see DOM at every step (use this most of the time)
npx playwright test tests/playwright/your-plugin/ --ui

# One specific file
npx playwright test tests/playwright/your-plugin/core.spec.js

# Responsive — mobile + tablet + desktop in parallel
npx playwright test tests/playwright/your-plugin/ \
  --project=chromium --project=mobile-chrome --project=tablet
```

### Reading Results

```bash
# Open the visual HTML report after any run
npx playwright show-report reports/playwright-html
```

Every failed test shows: screenshot of failure, video of full run up to failure, trace file for step-by-step replay.

### The Complete Playwright Test Library

**Templates (copy one for your plugin):**
```
tests/playwright/templates/
├── generic-plugin/    ← for any WP plugin (admin page, no-error checks, a11y)
├── elementor-addon/   ← Elementor editor loads, widget in panel, widget renders
├── gutenberg-block/   ← block in inserter, block renders, no console errors
├── seo-plugin/        ← side-by-side UAT comparison (your plugin vs competitor)
├── woocommerce/       ← cart, checkout, gateway, order flow
└── theme/             ← template hierarchy, FSE, theme.json, customizer
```

**PM Checks (Step 12 — run via gauntlet or standalone):**
```
tests/playwright/pm/
├── spell-check.spec.js   ← all UI text: labels, buttons, tooltips, notices, headings
├── guided-ux.spec.js     ← onboarding quality score 0-10 vs 7 competitors
└── label-audit.spec.js   ← labels/buttons vs WooCommerce, Yoast, RankMath standards
```

**Flow Tests (real user scenarios — ready to use with env vars):**

| File | What It Tests | Env Vars Required |
|------|--------------|-------------------|
| `flows/onboarding-ftue.spec.js` | First 60 seconds post-activation: redirect, wizard reachable, skip doesn't break plugin, core feature in ≤3 clicks | `PLUGIN_SLUG`, `PLUGIN_CORE_FEATURE_URL` |
| `flows/user-journey.spec.js` | Full path: install → activate → configure → use feature → measure | `PLUGIN_SLUG`, `PLUGIN_USER_JOURNEY` (JSON) |
| `flows/uninstall-cleanup.spec.js` | Plugin deactivate+delete removes all options, tables, transients, cron events (WP.org compliance) | `PLUGIN_SLUG`, `PLUGIN_PREFIX`, `PLUGIN_CUSTOM_TABLES` |
| `flows/update-path.spec.js` | v1 → v2 upgrade preserves settings, runs DB migrations cleanly | `PLUGIN_SLUG`, `PLUGIN_V1_ZIP`, `PLUGIN_V2_ZIP`, `PLUGIN_TEST_OPTION` |
| `flows/plugin-conflict.spec.js` | Your plugin + top 20 most-installed WP plugins active simultaneously — no fatals, no UI breaks | `PLUGIN_SLUG` |
| `flows/multisite-activation.spec.js` | Network activate across all subsites, correct capability checks | `PLUGIN_SLUG`, `MULTISITE=1` |
| `flows/rtl-layout.spec.js` | Arabic/Hebrew locale: no overflow, correct text direction, icons pointing right | `PLUGIN_ADMIN_SLUG` |
| `flows/empty-states.spec.js` | Fresh install / zero items: plugin shows guidance, not a blank panel | `PLUGIN_ADMIN_SLUG`, `PLUGIN_EMPTY_PAGES` |
| `flows/error-states.spec.js` | AJAX 500, REST WP_Error, network offline: user sees an error message, not frozen UI | `PLUGIN_ADMIN_SLUG`, `PLUGIN_AJAX_ACTION` |
| `flows/form-validation.spec.js` | Invalid inputs, empty required fields, max-length edge cases | `PLUGIN_ADMIN_SLUG` |
| `flows/loading-states.spec.js` | Spinner appears, skeleton screens visible, no layout jump during load | `PLUGIN_ADMIN_SLUG` |
| `flows/keyboard-nav.spec.js` | Tab order, Enter/Space on buttons, Escape to close modals, focus traps | `PLUGIN_ADMIN_SLUG` |
| `flows/analytics-events.spec.js` | Intercepts network requests, verifies your tracking events fire on correct actions | `PLUGIN_ADMIN_SLUG`, `ANALYTICS_ENDPOINT` |
| `flows/bundle-size.spec.js` | JS/CSS file sizes are under your defined thresholds | `PLUGIN_SLUG`, `MAX_JS_KB`, `MAX_CSS_KB` |
| `flows/block-deprecation.spec.js` | Old saved block markup still renders (Gutenberg backwards compat) | `PLUGIN_SLUG` |
| `flows/wp7-connectors.spec.js` | WP 7.0 Connectors API compatibility | `PLUGIN_SLUG` |
| `flows/admin-color-schemes.spec.js` | Plugin UI correct on all 9 WP admin color schemes (Default, Light, Blue, Sunrise, etc.) | `PLUGIN_ADMIN_SLUG` |
| `flows/app-passwords.spec.js` | REST API auth via WP Application Passwords works | `PLUGIN_SLUG` |
| `flows/visual-regression-release.spec.js` | Full-page diffs of every admin screen between two releases | `PLUGIN_SLUG` |

**Visual Tests:**
```
tests/playwright/visual/
├── ui-audit.spec.js        ← overflow, missing labels, broken images, empty containers, font size leaks
└── visual-snapshots.spec.js ← full-page screenshot baseline for all admin screens
```

**Editor Performance Tests:**
```
tests/playwright/editor-perf/   ← Elementor/Gutenberg editor load time + widget insert timing
```

### Running Flow Tests (With Env Vars)

```bash
# Uninstall cleanup test
PLUGIN_SLUG=my-plugin \
PLUGIN_PREFIX=my_plugin \
PLUGIN_CUSTOM_TABLES=my_plugin_logs,my_plugin_sessions \
WP_TEST_URL=http://localhost:8881 \
npx playwright test tests/playwright/flows/uninstall-cleanup.spec.js

# Update path (v1 → v2 migration)
PLUGIN_SLUG=my-plugin \
PLUGIN_V1_ZIP=~/downloads/my-plugin-1.0.zip \
PLUGIN_V2_ZIP=~/downloads/my-plugin-2.0.zip \
PLUGIN_TEST_OPTION=my_plugin_settings \
npx playwright test tests/playwright/flows/update-path.spec.js

# Plugin conflict matrix (activates top 20 plugins one by one)
PLUGIN_SLUG=my-plugin \
WP_TEST_URL=http://localhost:8881 \
npx playwright test tests/playwright/flows/plugin-conflict.spec.js

# RTL layout (Arabic/Hebrew users)
PLUGIN_ADMIN_SLUG=my-plugin \
WP_TEST_URL=http://localhost:8881 \
npx playwright test tests/playwright/flows/rtl-layout.spec.js --project=rtl

# Multisite (requires multisite wp-env)
bash scripts/create-test-site.sh --plugin ~/plugins/your-plugin --multisite
PLUGIN_SLUG=my-plugin MULTISITE=1 \
npx playwright test tests/playwright/flows/multisite-activation.spec.js

# FTUE (first-time user experience)
PLUGIN_SLUG=my-plugin \
PLUGIN_CORE_FEATURE_URL=/wp-admin/admin.php?page=my-plugin-main \
npx playwright test tests/playwright/flows/onboarding-ftue.spec.js
```

### Creating a New Test From a Template

```bash
# 1. Copy the template for your plugin type
cp -r tests/playwright/templates/elementor-addon/ tests/playwright/my-plugin/

# 2. Edit core.spec.js — replace the admin URLs and CSS selectors with your plugin's

# 3. Create your visual baseline (first run only)
WP_TEST_URL=http://localhost:8881 \
npx playwright test tests/playwright/my-plugin/ --update-snapshots

# 4. Every run after compares against baseline
WP_TEST_URL=http://localhost:8881 \
npx playwright test tests/playwright/my-plugin/
```

In a test file, the minimum you need:
```js
const { test, expect } = require('@playwright/test');

test('plugin admin page loads without errors', async ({ page }) => {
  const errors = [];
  page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });

  await page.goto('/wp-admin/admin.php?page=my-plugin');
  await page.waitForLoadState('networkidle');

  // No PHP fatal errors
  await expect(page.locator('body')).not.toContainText('Fatal error');
  // No broken images
  const brokenImages = await page.evaluate(() =>
    Array.from(document.images).filter(i => !i.complete || i.naturalWidth === 0).length
  );
  expect(brokenImages).toBe(0);
  // No JS errors from your plugin
  expect(errors.filter(e => e.includes('my-plugin'))).toHaveLength(0);
  // Visual snapshot — diffs on every run
  await expect(page).toHaveScreenshot('admin-main.png', { maxDiffPixelRatio: 0.02 });
});
```

### Scale Testing (Does Your Plugin Break at 10,000 Items?)

```bash
# Seed large dataset (1000 posts, 500 users, 100 terms by default)
bash scripts/seed-large-dataset.sh

# Or custom volumes
bash scripts/seed-large-dataset.sh 5000 1000 200

# Then run your tests — does pagination work? Do list tables load in time?
WP_TEST_URL=http://localhost:8881 \
npx playwright test tests/playwright/your-plugin/
```

### Debug a Failing Test

```bash
# Option 1: Playwright Inspector (step line by line)
npx playwright test tests/playwright/your-plugin/core.spec.js --debug

# Option 2: Trace viewer (full forensic replay)
# Traces auto-save on failure when trace: 'on-first-retry' is set in playwright.config.js
npx playwright show-trace test-results/your-test/trace.zip

# Option 3: Run just the failing test, headed + slow
npx playwright test tests/playwright/your-plugin/core.spec.js --headed --slowMo=800
```

### Your Sign-Off Checklist

```bash
open checklists/pre-release-checklist.md   # QA section
```

QA signs off when: all tests pass, visual diffs reviewed and approved, a11y score ≥ 85, zero console errors from the plugin.

---

## 📊 ROLE 3: Product Manager

**Your job**: You don't run commands. You read three reports and make the release call.

### The Three Reports You Read

**1. Main gauntlet summary** — ask Dev/QA to send you this file after every release candidate:
```
reports/qa-report-TIMESTAMP.md
```
Open it in any text editor or Notion. Each line is `✓ passed`, `⚠ warning`, or `✗ failed`. You decide if warnings block release.

**2. PM UX Report** (HTML, opens in browser):
```bash
open reports/pm-ux/pm-ux-report-*.html
```
Three sections:
- **Spell-Check** — every typo across all admin pages. Where it was found, what it says, what it should say.
- **Guided Experience Score** — your product scored 0–10 vs Yoast SEO (8/10), RankMath (9/10), WooCommerce (8/10), WPForms (9/10), Gravity Forms (8/10), Jetpack (7/10), AIOSEO (8/10). Missing signals listed with: "add X to gain +Y points."
- **Label Audit** — non-standard labels, vague buttons, PHP jargon exposed to users, illogically ordered option groups. Each flag shows which competitor uses the correct term.

**3. UAT Comparison Report** (HTML, opens in browser):
```bash
open reports/uat-report-*.html
```
Side-by-side screenshots and videos of your plugin vs competitor doing the same task. PM analysis column. RICE-scored backlog. Feature comparison table.

### Asking the Team to Run PM Checks

```bash
# They run this — you just read the HTML output
bash scripts/pm-ux-audit.sh --url http://localhost:8881 --slug your-plugin-slug
```

### Competitor Analysis Report

```bash
# Team runs this
bash scripts/competitor-compare.sh
cat reports/competitor-*.md
```

Shows: your plugin vs each competitor on bundle size, PHPCS errors, security pattern coverage, active installs, last updated, star rating.

### Flow Map + Click-Depth Scoring

Orbit measures clicks to reach key features (lower = better). Find this in `reports/uat-report-*.html` in the "Click Depth" column:
```
Yoast SEO: 2 clicks to main settings
Your plugin: 4 clicks to equivalent settings → needs streamlining
```

### What to Do With Each Finding

| Finding | PM Action |
|---------|-----------|
| Any `✗ FAIL` in gauntlet | Must be fixed. No release. |
| Typos found | Fix before release — typos = 1-star review risk |
| Guidance score < 5 | Immediate backlog: users will churn. PM priority. |
| Guidance score 5–7 | Next sprint. Growth opportunity. |
| Guidance score ≥ competitor avg | Ship. |
| High-severity label issues | Fix before release |
| Medium label issues | Backlog |
| Competitor analysis gaps | Roadmap planning input |

### Your Sign-Off Checklist

```bash
open checklists/pre-release-checklist.md   # PM section
open checklists/ui-ux-checklist.md         # 40-point design quality
```

---

## 📈 ROLE 4: Product Analyst (PA)

**Your job**: Performance metrics, event verification, data across versions and competitors.

### Verify Analytics Events Fire Correctly

```bash
# Run tests with network capture
WP_TEST_URL=http://localhost:8881 \
ANALYTICS_ENDPOINT=stats.posimyth.com \
npx playwright test tests/playwright/flows/analytics-events.spec.js
```

Or add to any test:
```js
const analyticsHits = [];
page.on('request', req => {
  if (req.url().includes('your-analytics-domain')) {
    analyticsHits.push({ url: req.url(), method: req.method() });
  }
});

await page.click('.your-feature-button');
expect(analyticsHits.length, 'Analytics event should fire on feature use').toBeGreaterThan(0);
```

### Performance Scoring — Before and After Every Release

```bash
# Full Lighthouse report (opens in browser)
lighthouse http://localhost:8881 \
  --output=html \
  --output-path=reports/lighthouse/report.html \
  --chrome-flags="--headless"
open reports/lighthouse/report.html

# Quick score to terminal
lighthouse http://localhost:8881 --output=json --quiet \
  | python3 -c "
import json,sys
d=json.load(sys.stdin)
cats=d['categories']
print('Performance:', int(cats['performance']['score']*100),
      '| A11y:', int(cats['accessibility']['score']*100),
      '| Best Practices:', int(cats['best-practices']['score']*100),
      '| SEO:', int(cats['seo']['score']*100))"
```

Run before and after a release candidate. Record the delta.

### Core Web Vitals Targets

| Metric | Target | What It Means |
|--------|--------|--------------|
| Performance score | ≥ 80 | Overall weighted score |
| LCP (Largest Contentful Paint) | < 2.5s | When main content loads |
| FCP (First Contentful Paint) | < 1.8s | When first content appears |
| TBT (Total Blocking Time) | < 200ms | JS blocking the main thread |
| CLS (Cumulative Layout Shift) | < 0.1 | No content jumping around |
| TTI (Time to Interactive) | < 3.8s | Page responds to user input |

### DB Query Count Per Page

```bash
bash scripts/db-profile.sh
cat reports/db-profile-*.txt
```

Track this number across releases. Flags: query count >60/page, any query >100ms, N+1 patterns (same query repeated in a loop). If it goes up between releases, flag before shipping.

### Editor Performance Data

```bash
bash scripts/editor-perf.sh
cat reports/editor-perf-*.json
```

Measures: editor ready time (target <3s), widget panel load (<500ms), widget insert → render (<300ms per widget), memory growth after 20 widgets (<100MB). Your baseline for before/after comparisons.

### Competitor Benchmarking Data

```bash
bash scripts/competitor-compare.sh --competitors "rankmath,yoast,aioseo,essential-addons-for-elementor-free"
cat reports/competitor-*.md
```

Structured data per competitor: version, active installs, rating, JS bundle size (KB), CSS bundle size (KB), PHPCS error count, last updated date. Track quarterly in a spreadsheet.

### Version Delta Report

```bash
bash scripts/compare-versions.sh \
  --old ~/downloads/your-plugin-v1.3.zip \
  --new ~/downloads/your-plugin-v1.4.zip
```

Side-by-side: PHPCS errors, JS bundle KB, CSS bundle KB. Chart your regression or improvement.

### Bundle Size Tracking

```bash
# Assert JS/CSS sizes stay under thresholds
MAX_JS_KB=500 \
MAX_CSS_KB=100 \
PLUGIN_SLUG=your-plugin \
WP_TEST_URL=http://localhost:8881 \
npx playwright test tests/playwright/flows/bundle-size.spec.js
```

---

## 🎨 ROLE 5: Designer

**Your job**: Visual regressions, UI quality, responsive breaks, accessibility — caught before users see them.

### Setup (Same as QA)

```bash
bash scripts/create-test-site.sh --plugin ~/plugins/your-plugin --port 8881
WP_TEST_URL=http://localhost:8881 \
npx playwright test tests/playwright/auth.setup.js --project=setup
```

### Your Core Command: Visual Regression

```bash
# First run — creates baseline (golden screenshots)
WP_TEST_URL=http://localhost:8881 \
npx playwright test tests/playwright/your-plugin/ --update-snapshots

# Every run after — diffs against baseline, reports pixel changes
WP_TEST_URL=http://localhost:8881 \
npx playwright test tests/playwright/your-plugin/

# View the visual diff report
npx playwright show-report reports/playwright-html
```

In the HTML report, failed visual tests show: left = baseline, middle = red diff highlights (what changed), right = current. You approve or reject.

### Full Visual Snapshot Suite

```bash
# Snapshots of every admin screen across all viewports
WP_TEST_URL=http://localhost:8881 \
PLUGIN_ADMIN_SLUG=your-plugin \
npx playwright test tests/playwright/visual/visual-snapshots.spec.js

# UI quality audit — overflow, broken images, empty containers, font size leaks
WP_TEST_URL=http://localhost:8881 \
npx playwright test tests/playwright/visual/ui-audit.spec.js
```

UI audit catches:
- Elements wider than their container (horizontal scroll on admin)
- Images returning 404
- Empty containers (blank panel/box)
- Buttons or inputs without labels
- Inconsistent font sizes (styling leak from WP core or another plugin)
- Admin notices still showing after they should auto-dismiss

### Responsive Testing

```bash
# Test at mobile (375px), tablet (768px), and desktop (1440px) simultaneously
npx playwright test tests/playwright/your-plugin/ \
  --project=chromium \
  --project=mobile-chrome \
  --project=tablet

# What it checks at mobile:
# → No horizontal scroll (overflow-x)
# → All tap targets ≥ 44×44px
# → No text truncation by container edges
# → No elements overlapping
```

### Adding Visual Snapshots to Any Test

```js
// Full page screenshot — diffs on every run
await expect(page).toHaveScreenshot('settings-page.png', {
  maxDiffPixelRatio: 0.02   // 2% pixel difference allowed (anti-aliasing, fonts)
});

// Screenshot of one element only
await expect(page.locator('.my-plugin-widget')).toHaveScreenshot('widget.png');

// Screenshot at specific viewport
await page.setViewportSize({ width: 375, height: 812 });
await expect(page).toHaveScreenshot('settings-mobile.png');
```

### Admin Color Scheme Compatibility

Your plugin's UI must work on all 9 WordPress admin color schemes:

```bash
PLUGIN_ADMIN_SLUG=your-plugin \
WP_TEST_URL=http://localhost:8881 \
npx playwright test tests/playwright/flows/admin-color-schemes.spec.js
```

Tests on: Default (gray), Light, Blue, Coffee, Ectoplasm, Midnight, Ocean, Sunrise, and Modern.

### RTL Layout

```bash
PLUGIN_ADMIN_SLUG=your-plugin \
WP_TEST_URL=http://localhost:8881 \
npx playwright test tests/playwright/flows/rtl-layout.spec.js --project=rtl
```

Switches WP to Arabic locale, runs your admin pages, checks: no horizontal overflow, no text cut off, icons/arrows in correct direction. Arabic + Hebrew users represent ~5% of the WordPress market.

### AI UI Polish Audit

```bash
# Design quality — 44px hit areas, spacing consistency, visual weight, icon quality
claude "/antigravity-design-expert Review admin UI in ~/plugins/your-plugin/admin/ for visual polish issues. Check: touch target sizes (44px minimum), label alignment, spacing rhythm, empty states, loading states, icon quality."

# Accessibility — WCAG 2.1 AA
claude "/accessibility-compliance-accessibility-audit Audit ~/plugins/your-plugin admin pages for WCAG 2.1 AA. Check: color contrast ratios, keyboard navigation, focus indicators, ARIA labels, form field accessibility."
```

### The UI/UX Checklist (40 Points)

```bash
open checklists/ui-ux-checklist.md
```

Based on `make-interfaces-feel-better` principles. Covers: spacing, typography, form design, empty states, loading states, error states, color use, iconography, touch targets. Designer reviews and signs off before release.

### What to Look at in the PM UX HTML Report

```bash
open reports/pm-ux/pm-ux-report-*.html
```

Directly relevant to you:
- **Spell-check findings** — typos in the UI
- **Label issues flagged as** `all_caps_abuse`, `truncated_label` — visual design problems
- **Option ordering** — selects/radio groups with illogical sequence

---

## 👤 ROLE 6: End User (Beta Tester / UAT)

**Your job**: Walk through flows as a first-time user. No terminal needed. Someone on the dev team runs commands — you watch and give feedback.

### What the Team Runs (You Just Watch)

```bash
# Records video of every user flow
WP_TEST_URL=http://localhost:8881 \
npx playwright test tests/playwright/your-plugin/ --headed --video=on

# Generates the full UAT report for you to review
open reports/uat-report-*.html
```

### What to Watch For When Reviewing Videos

1. **First-time setup** — Is there a wizard? A welcome screen? Any guidance? Or does it drop you into settings with no explanation?
2. **Task completion** — Can you find the main feature without searching? Count the clicks.
3. **Error messages** — When something goes wrong, does the message tell you how to fix it?
4. **Labels** — Does "Submit" actually save something? Is "Config" the settings page? Does the button name match what it does?
5. **Option groups** — Do dropdowns make sense in their order? (Never → Low → Medium → High is logical. Monthly → Never → Daily is not.)

### The FTUE Test (First-Time User Experience)

This test specifically measures the first 60 seconds after activation:

```
✓ Activation redirected to a useful page (not the default plugins list)
✓ Onboarding wizard is reachable and skippable
✓ Skipping wizard does not leave plugin in a broken state
✓ Core feature reachable within 3 clicks
```

If any of those fail — that's a user who bounced before they saw the value.

### Feedback Format (Tell the Team)

When you find something:
```
Screen: [which page or flow]
What I did: [clicked X, tried to do Y]
What happened: [what I saw]
What I expected: [what I thought would happen]
Severity: confused me / annoyed me / completely blocked me
```

---

## 🔁 Batch Testing (Testing Multiple Plugins at Once)

```bash
# Test 3 plugins in parallel (each gets its own Docker site on its own port)
bash scripts/batch-test.sh --plugins "plugin-a,plugin-b,plugin-c"

# Test every plugin in a directory
bash scripts/batch-test.sh --plugins-dir ~/plugins

# Limit parallel count (auto-scales to half your CPU cores by default)
bash scripts/batch-test.sh --plugins-dir ~/plugins --concurrency 2
```

Orbit auto-scales to half your CPU cores (capped at 4) to avoid burning your Mac. Each plugin gets its own wp-env site, its own port, its own report.

---

## 🛡️ Pre-Flight Check (Run Before Your First Gauntlet)

```bash
bash scripts/gauntlet-dry-run.sh
```

Validates that every tool the gauntlet needs is installed — without running the heavy checks. Catches "command not found" in 5 seconds instead of 5 minutes into a run. Shows: ✓ installed tools, ✗ missing critical tools with install command, ⚠ missing optional tools.

---

## 📋 Complete Command Reference Card

### Setup
```bash
git clone https://github.com/adityaarsharma/orbit && cd orbit
bash setup/init.sh                                           # first-time config wizard
bash scripts/install-power-tools.sh                          # install all tools
bash scripts/gauntlet-dry-run.sh                             # verify tools before first run
bash scripts/create-test-site.sh --plugin ~/plugins/p --port 8881
bash scripts/create-test-site.sh --plugin ~/plugins/p --multisite  # multisite
```

### Gauntlet
```bash
bash scripts/gauntlet.sh                                     # uses qa.config.json
bash scripts/gauntlet.sh --plugin ~/plugins/your-plugin --mode quick     # ~2 min
bash scripts/gauntlet.sh --plugin ~/plugins/your-plugin                  # ~8 min
bash scripts/gauntlet.sh --plugin ~/plugins/your-plugin --mode full      # ~15 min
bash scripts/gauntlet.sh --plugin ~/plugins/your-plugin --mode release   # strict
bash scripts/batch-test.sh --plugins-dir ~/plugins           # all plugins in parallel
```

### Individual Checks (Run Without Gauntlet)
```bash
bash scripts/check-plugin-header.sh ~/plugins/your-plugin    # plugin header metadata
bash scripts/check-readme-txt.sh ~/plugins/your-plugin       # readme.txt format
bash scripts/check-version-parity.sh ~/plugins/your-plugin   # header version = readme version
bash scripts/check-license.sh ~/plugins/your-plugin          # GPL-compatible license
bash scripts/check-wp-compat.sh ~/plugins/your-plugin        # WP requires headers
bash scripts/check-php-compat.sh ~/plugins/your-plugin       # PHP 7.4–8.3 compat
bash scripts/check-zip-hygiene.sh ~/plugins/your-plugin      # no dev files, no eval()
bash scripts/check-block-json.sh ~/plugins/your-plugin       # block.json validation
bash scripts/check-gdpr-hooks.sh ~/plugins/your-plugin       # GDPR export/erase hooks
bash scripts/check-hpos-declaration.sh ~/plugins/your-plugin # WooCommerce HPOS compat
bash scripts/check-object-cache.sh ~/plugins/your-plugin     # transient/cache patterns
bash scripts/check-login-assets.sh ~/plugins/your-plugin     # no unnecessary login page assets
bash scripts/check-modern-wp.sh ~/plugins/your-plugin        # WP 6.5+ API usage
bash scripts/check-translation.sh ~/plugins/your-plugin      # i18n completeness
bash scripts/check-live-cve.sh ~/plugins/your-plugin         # live CVE correlation (NVD + WPScan)
bash scripts/check-ownership-transfer.sh ~/plugins/your-plugin # author header drift in git history
```

### Playwright
```bash
# Auth setup (once)
WP_TEST_URL=http://localhost:8881 npx playwright test tests/playwright/auth.setup.js --project=setup

# Run tests
WP_TEST_URL=http://localhost:8881 npx playwright test tests/playwright/your-plugin/
WP_TEST_URL=http://localhost:8881 npx playwright test tests/playwright/your-plugin/core.spec.js
npx playwright test --ui                                     # interactive mode
npx playwright test --headed --slowMo=500                   # watch browser
npx playwright test --debug                                  # step-through debugger
npx playwright test --update-snapshots                       # update visual baselines
npx playwright show-report reports/playwright-html           # HTML report

# Responsive
npx playwright test tests/playwright/your-plugin/ \
  --project=chromium --project=mobile-chrome --project=tablet
```

### Flow Tests (Full Commands)
```bash
# FTUE
PLUGIN_SLUG=my-plugin PLUGIN_CORE_FEATURE_URL=/wp-admin/admin.php?page=my-plugin \
WP_TEST_URL=http://localhost:8881 npx playwright test flows/onboarding-ftue.spec.js

# Uninstall cleanup
PLUGIN_SLUG=my-plugin PLUGIN_PREFIX=my_plugin PLUGIN_CUSTOM_TABLES=my_plugin_logs \
WP_TEST_URL=http://localhost:8881 npx playwright test flows/uninstall-cleanup.spec.js

# Update path
PLUGIN_SLUG=my-plugin PLUGIN_V1_ZIP=~/v1.zip PLUGIN_V2_ZIP=~/v2.zip \
WP_TEST_URL=http://localhost:8881 npx playwright test flows/update-path.spec.js

# Plugin conflict
PLUGIN_SLUG=my-plugin WP_TEST_URL=http://localhost:8881 \
npx playwright test flows/plugin-conflict.spec.js

# RTL
PLUGIN_ADMIN_SLUG=my-plugin WP_TEST_URL=http://localhost:8881 \
npx playwright test flows/rtl-layout.spec.js --project=rtl

# Multisite
PLUGIN_SLUG=my-plugin MULTISITE=1 WP_TEST_URL=http://localhost:8882 \
npx playwright test flows/multisite-activation.spec.js

# Admin color schemes
PLUGIN_ADMIN_SLUG=my-plugin WP_TEST_URL=http://localhost:8881 \
npx playwright test flows/admin-color-schemes.spec.js

# Bundle size guard
PLUGIN_SLUG=my-plugin MAX_JS_KB=500 MAX_CSS_KB=100 WP_TEST_URL=http://localhost:8881 \
npx playwright test flows/bundle-size.spec.js
```

### PM UX Checks
```bash
bash scripts/pm-ux-audit.sh --url http://localhost:8881 --slug your-plugin-slug
open reports/pm-ux/pm-ux-report-*.html
```

### Performance
```bash
bash scripts/db-profile.sh                                   # DB query profiling
bash scripts/editor-perf.sh                                  # Elementor/Gutenberg editor perf
lighthouse http://localhost:8881 --output=html --chrome-flags="--headless"
```

### Competitor + Version Analysis
```bash
bash scripts/competitor-compare.sh                           # uses qa.config.json
bash scripts/competitor-compare.sh --competitors "rankmath,yoast"
bash scripts/compare-versions.sh --old v1.3.zip --new v1.4.zip
bash scripts/pull-plugins.sh                                 # download competitor zips
bash scripts/changelog-test.sh --changelog ~/plugins/p/CHANGELOG.md
```

### Scale Testing
```bash
bash scripts/seed-large-dataset.sh                           # 1000 posts, 500 users, 100 terms
bash scripts/seed-large-dataset.sh 5000 1000 200             # custom volumes
```

### Auto-Generate Tests From Code
```bash
bash scripts/scaffold-tests.sh ~/plugins/your-plugin         # reads code, outputs test scaffold
bash scripts/scaffold-tests.sh ~/plugins/your-plugin --deep  # + AI writes business logic scenarios
```

### Git Hook
```bash
ORBIT_ROOT=~/orbit bash ~/orbit/scripts/install-pre-commit-hook.sh
```

### AI Skill Audits (Claude Code)
```bash
claude "/wordpress-penetration-testing Audit ~/plugins/your-plugin"
claude "/wordpress-plugin-development Review ~/plugins/your-plugin for WP standards"
claude "/performance-engineer Find all N+1 queries in ~/plugins/your-plugin/includes/"
claude "/database-optimizer Review ~/plugins/your-plugin for query patterns"
claude "/accessibility-compliance-accessibility-audit Audit ~/plugins/your-plugin"
claude "/antigravity-design-expert Review admin UI in ~/plugins/your-plugin/admin/"
claude "/code-review-excellence Review ~/plugins/your-plugin for code quality"
# WooCommerce-specific
claude "/wordpress-woocommerce-development Audit ~/plugins/your-plugin for WC compatibility"
# Theme-specific
claude "/wordpress-theme-development Review ~/plugins/your-plugin for FSE and theme.json patterns"
# REST API
claude "/api-security-testing Audit every register_rest_route in ~/plugins/your-plugin"
```

### Reports
```bash
cat reports/qa-report-*.md                                   # main gauntlet report
open reports/pm-ux/pm-ux-report-*.html                      # PM UX report
npx playwright show-report reports/playwright-html           # Playwright HTML report
open reports/uat-report-*.html                               # UAT comparison report
open reports/skill-audits/index.html                         # AI audit tab report
cat reports/db-profile-*.txt                                 # DB profiling
cat reports/competitor-*.md                                  # competitor analysis
cat reports/editor-perf-*.json                               # editor performance
open reports/lighthouse/report.html                          # Lighthouse report
```

### Checklists
```bash
open checklists/pre-release-checklist.md                     # full 3-role sign-off
open checklists/ui-ux-checklist.md                           # 40-point design quality
open checklists/security-checklist.md                        # XSS, CSRF, SQLi, auth
open checklists/performance-checklist.md                     # Core Web Vitals, assets, DB
```

---

## Release Gate — Who Signs Off on What

Before any release ships, three people read three things:

| Role | Reads | Signs Off When |
|------|-------|---------------|
| **Developer** | `reports/qa-report-*.md` — Steps 1–5 | Zero `✗ FAIL`. All security warnings triaged. |
| **QA Tester** | `reports/playwright-html/index.html` | All tests pass. Visual diffs reviewed and approved. A11y score ≥ 85. |
| **Product Manager** | `reports/pm-ux/pm-ux-report-*.html` + pre-release checklist | UX issues triaged. Guidance score reviewed. Release risk acceptable. |

All three → ship.

---

## Everything Orbit Can Do — One-Page Summary

| Capability | Script / Command | Role |
|-----------|-----------------|------|
| PHP syntax errors | `gauntlet.sh` Step 1 | Dev |
| Plugin header + readme.txt validation | `check-plugin-header.sh`, `check-readme-txt.sh` | Dev |
| Version parity check | `check-version-parity.sh` | Dev |
| License validation | `check-license.sh` | Dev |
| WordPress Coding Standards | `gauntlet.sh` Step 2 (PHPCS) | Dev |
| Static analysis (PHPStan) | `gauntlet.sh` Step 3 | Dev |
| Asset weight tracking | `gauntlet.sh` Step 4 | Dev/PA |
| i18n / POT check | `gauntlet.sh` Step 5 | Dev |
| PHP 7.4–8.3 compatibility | `check-php-compat.sh` | Dev |
| Zip hygiene (no eval, dev files) | `check-zip-hygiene.sh` | Dev |
| Live CVE correlation (NVD + WPScan) | `check-live-cve.sh` | Dev |
| Plugin ownership transfer detection | `check-ownership-transfer.sh` | Dev |
| Block.json validation | `check-block-json.sh` | Dev |
| GDPR hook coverage | `check-gdpr-hooks.sh` | Dev |
| WooCommerce HPOS compatibility | `check-hpos-declaration.sh` | Dev |
| Object cache patterns | `check-object-cache.sh` | Dev |
| Login page asset check | `check-login-assets.sh` | Dev |
| Modern WP API usage | `check-modern-wp.sh` | Dev |
| WP compatibility headers | `check-wp-compat.sh` | Dev |
| Pre-commit hook | `install-pre-commit-hook.sh` | Dev |
| Functional browser tests | Playwright `tests/playwright/your-plugin/` | QA |
| Visual regression | Playwright `--update-snapshots` | QA/Designer |
| Responsive testing | Playwright `--project=mobile-chrome` | QA/Designer |
| Accessibility (axe-core WCAG 2.1 AA) | Playwright `core.spec.js` | QA/Designer |
| First-time user experience (FTUE) | `flows/onboarding-ftue.spec.js` | QA/PM |
| Full user journey | `flows/user-journey.spec.js` | QA/PM |
| Uninstall cleanup (WP.org compliance) | `flows/uninstall-cleanup.spec.js` | QA |
| Version upgrade migration | `flows/update-path.spec.js` | QA |
| Plugin conflict matrix (top 20 plugins) | `flows/plugin-conflict.spec.js` | QA |
| Multisite compatibility | `flows/multisite-activation.spec.js` | QA |
| RTL layout (Arabic/Hebrew) | `flows/rtl-layout.spec.js` | QA/Designer |
| Empty state UX | `flows/empty-states.spec.js` | QA/PM |
| Error state handling | `flows/error-states.spec.js` | QA |
| Form validation edge cases | `flows/form-validation.spec.js` | QA |
| Loading state behavior | `flows/loading-states.spec.js` | QA/Designer |
| Keyboard navigation | `flows/keyboard-nav.spec.js` | QA |
| Analytics event verification | `flows/analytics-events.spec.js` | PA |
| Bundle size assertion | `flows/bundle-size.spec.js` | Dev/PA |
| Gutenberg block deprecation | `flows/block-deprecation.spec.js` | Dev/QA |
| WP 7.0 Connectors compatibility | `flows/wp7-connectors.spec.js` | Dev/QA |
| Admin color scheme compatibility | `flows/admin-color-schemes.spec.js` | Designer |
| Application Passwords (REST auth) | `flows/app-passwords.spec.js` | Dev/QA |
| Visual regression between releases | `flows/visual-regression-release.spec.js` | Designer |
| UI quality audit (overflow, broken images) | `visual/ui-audit.spec.js` | Designer |
| Full visual snapshot suite | `visual/visual-snapshots.spec.js` | Designer |
| Spell-check across all admin UI | `pm/spell-check.spec.js` | PM |
| Guided experience score (0–10) | `pm/guided-ux.spec.js` | PM |
| Label + terminology audit | `pm/label-audit.spec.js` | PM |
| Lighthouse performance | `gauntlet.sh` Step 7 | PA |
| DB query profiling | `db-profile.sh` | Dev/PA |
| Editor load performance | `editor-perf.sh` | Dev/PA |
| Competitor analysis | `competitor-compare.sh` | PM/PA |
| Version comparison | `compare-versions.sh` | Dev/PA |
| Scale testing (10,000 items) | `seed-large-dataset.sh` | QA |
| Batch test multiple plugins | `batch-test.sh` | Dev/QA |
| Auto-scaffold tests from code | `scaffold-tests.sh` | Dev/QA |
| Changelog → test map | `changelog-test.sh` | QA |
| AI security audit | `/wordpress-penetration-testing` | Dev |
| AI performance audit | `/performance-engineer` | Dev/PA |
| AI database audit | `/database-optimizer` | Dev/PA |
| AI accessibility audit | `/accessibility-compliance-accessibility-audit` | Designer |
| AI design quality audit | `/antigravity-design-expert` | Designer |
| AI WP standards audit | `/wordpress-plugin-development` | Dev |
| AI code quality audit | `/code-review-excellence` | Dev |
| AI WooCommerce audit | `/wordpress-woocommerce-development` | Dev |
| AI theme audit | `/wordpress-theme-development` | Dev |
| AI REST API security | `/api-security-testing` | Dev |
| PM UX HTML report | `pm-ux-audit.sh` + `generate-pm-ux-report.py` | PM |
| UAT comparison report | `generate-uat-report.py` | PM |
| Pre-release checklist | `checklists/pre-release-checklist.md` | All |
| UI/UX checklist | `checklists/ui-ux-checklist.md` | Designer/PM |
| Security checklist | `checklists/security-checklist.md` | Dev |
| Performance checklist | `checklists/performance-checklist.md` | Dev/PA |

---

*Orbit v2.4.0 · [github.com/adityaarsharma/orbit](https://github.com/adityaarsharma/orbit)*
