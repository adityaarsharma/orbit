# What's New — Orbit v2 (Day-1 Pro QA Release)

> **For the dev team call.** This doc is the single source of truth for what
> changed in the major Orbit upgrade. Every item here is implemented, committed,
> and ready to run today.

---

## TL;DR — The Three Big Changes

1. **The 4 broken core skills are replaced.** Orbit was invoking an attacker
   tool for code review, a Kubernetes skill for WP performance, and a
   PostgreSQL DBA skill for `$wpdb` review. Four new Orbit-specific skills
   now do the right job.

2. **9 brand-new gauntlet steps** catch bugs real users hit that the old
   gauntlet didn't see: uninstall cleanup, update path, block deprecation,
   focus traps, admin color schemes, RTL, login-page asset leaks, GDPR
   hooks, translation runtime errors.

3. **`plugin-check` (the official WP.org tool)** now runs as Step 2b.
   If it rejects your plugin, WordPress.org will too.

---

## New gauntlet steps (in order)

| Step | What it checks | Catches |
|------|----------------|---------|
| **2b** | `wp plugin check` (official WP.org) | 40+ WP.org rejection reasons |
| **6c** | PHP deprecation log scan | Runtime `PHP Deprecated:` notices PHPStan misses |
| **8b** | Peak memory profiling | Plugins that crash 64MB shared hosting |
| **8c** | WP-Cron event verification | Silent cron failures, orphaned events |
| **8d** | GDPR / Privacy API hooks | Missing `wp_privacy_personal_data_*` hooks |
| **8e** | Login page asset leak | Plugin enqueueing on wp-login.php |
| **8f** | Translation runtime test | mistranslated `sprintf` crashes |
| **8g** | Lifecycle (uninstall / update / blocks) | Orphaned data, broken upgrades, block validation errors |
| **8h** | Keyboard nav + admin colors + RTL | Focus traps, color scheme breaks, RTL overflow |
| **8i** | REST Application Password auth | IDOR, broken permission_callback |
| **11** | AI skill audits (now with correct skills) | WP-specific security, performance, DB, standards |

---

## New Playwright test projects

```
npx playwright test --project=<name>
```

| Project | Spec | Use case |
|---------|------|----------|
| `lifecycle` | uninstall-cleanup + update-path + block-deprecation | Before every release |
| `keyboard` | keyboard-nav | WCAG 2.1.1 focus trap detection |
| `admin-colors` | admin-color-schemes | All 9 WP admin color schemes |
| `rtl` | rtl-layout | Arabic/Hebrew/Farsi users |
| `multisite` | multisite-activation | Network admin bugs |
| `rest-apppass` | app-passwords | REST permission_callback IDOR |

---

## New helper scripts

| Script | Purpose |
|--------|---------|
| `scripts/check-gdpr-hooks.sh <plugin-path>` | Scans for user data indicators, flags missing Privacy API hooks |
| `scripts/check-login-assets.sh <slug>` | Fetches wp-login.php, flags plugin assets that leaked |
| `scripts/check-translation.sh <plugin-path>` | Generates pseudo-locale `.mo`, loads it, scans for errors |
| `scripts/check-object-cache.sh <plugin-path>` | Activates Redis object cache, flags transient bypass bugs |
| `scripts/seed-large-dataset.sh [posts] [users]` | Creates 1,000+ posts/users for scale testing |

---

## New wp-env configs

| Config | Use case |
|--------|----------|
| `config/.wp-env.multisite.json` | Multisite (network + 2 subsites, auto-created on start) |
| `config/.wp-env.redis.json` | Persistent object cache via redis-cache plugin |

Use them by symlinking to `.wp-env.json`:
```bash
ln -sf config/.wp-env.multisite.json .wp-env.json
npx wp-env start
```

---

## New AI skills (custom, replace community skills)

Installed at `~/.claude/skills/`:

| Skill | Replaces | What it reviews |
|-------|----------|-----------------|
| `/orbit-wp-security` | `/wordpress-penetration-testing` | PHP source for 10 WP-specific vuln patterns |
| `/orbit-wp-performance` | `/performance-engineer` | WP hook weight, N+1 queries, transient misuse |
| `/orbit-wp-database` | `/database-optimizer` | `$wpdb` patterns, autoload bloat, uninstall cleanup |
| `/orbit-wp-standards` | `/wordpress-plugin-development` | Code reviewer for WP coding standards (not scaffolder) |

Each skill has its own SKILL.md with 10+ bad/good code pattern examples.

---

## How to configure a plugin for the new tests

Add these optional fields to `qa.config.json`:

```json
{
  "plugin": {
    "path": "/path/to/plugin",
    "slug": "my-plugin",
    "prefix": "my_plugin",
    "type": "general",
    "admin_slug": "my-plugin-settings",
    "rest_admin_endpoint": "/wp-json/my-plugin/v1/settings",
    "rest_public_endpoint": "/wp-json/my-plugin/v1/public",
    "custom_tables": ["my_plugin_log", "my_plugin_data"],
    "block_post_id": 42,
    "v1_zip": "/path/to/my-plugin-1.0.zip",
    "v2_zip": "/path/to/my-plugin-2.0.zip",
    "cron_hooks": ["my_plugin_daily", "my_plugin_cleanup"]
  }
}
```

Only the ones relevant to your plugin need to be set. Missing ones skip that test automatically.

---

## Running the full upgraded gauntlet

```bash
# Full gauntlet with all new checks
bash scripts/gauntlet.sh --plugin /path/to/plugin --mode full

# Just the new lifecycle tests
PLUGIN_SLUG=my-plugin PLUGIN_PREFIX=my_plugin \
  npx playwright test --project=lifecycle

# Redis object cache test
bash scripts/check-object-cache.sh /path/to/plugin

# Seed 1000 posts then run gauntlet at scale
bash scripts/seed-large-dataset.sh 1000
bash scripts/gauntlet.sh --plugin /path/to/plugin
```

---

## Demo talking points for the dev team call

1. **"Our skills were wrong."** Show the before/after in AGENTS.md — one
   was an attacker tool, one was Kubernetes. Now replaced with 4 custom
   WP-specific reviewers.

2. **"WordPress.org review now runs in CI."** Step 2b is `plugin-check`
   — exact same tool as the WP.org review team.

3. **"Uninstall cleanup is automated."** No more "plugin left orphaned
   data" complaints. Test fails the release if options/tables/cron survive
   deletion.

4. **"We now catch bugs you hit only in production."** Scale (1,000+
   posts), Redis object cache, multisite, RTL, all 9 admin color schemes,
   PHP 8.x runtime deprecations.

5. **"Per-plugin config, one file."** `qa.config.json` defines the whole
   plugin. Gauntlet auto-skips irrelevant tests.

---

## What's NOT automated (intentional)

Per the original decision, these stay manual:
- Custom JavaScript behavior tests (plugin-specific)
- Business-logic edge cases (needs product context)
- Manual UAT of visual design feedback

Everything else is in the gauntlet.

---

## Files changed in this upgrade

**New documentation:**
- `docs/16-master-audit.md` — full gap analysis + action plan
- `docs/17-whats-new.md` — this file

**New Playwright specs:**
- `tests/playwright/flows/uninstall-cleanup.spec.js`
- `tests/playwright/flows/update-path.spec.js`
- `tests/playwright/flows/block-deprecation.spec.js`
- `tests/playwright/flows/keyboard-nav.spec.js`
- `tests/playwright/flows/admin-color-schemes.spec.js`
- `tests/playwright/flows/app-passwords.spec.js`
- `tests/playwright/flows/rtl-layout.spec.js`
- `tests/playwright/flows/multisite-activation.spec.js`

**New scripts:**
- `scripts/check-gdpr-hooks.sh`
- `scripts/check-login-assets.sh`
- `scripts/check-translation.sh`
- `scripts/seed-large-dataset.sh`
- `scripts/check-object-cache.sh`

**New configs:**
- `config/.wp-env.multisite.json`
- `config/.wp-env.redis.json`

**Updated:**
- `AGENTS.md` — skill deduplication with corrected mappings
- `scripts/gauntlet.sh` — 9 new steps wired in
- `tests/playwright/playwright.config.js` — 6 new projects added

**New local custom skills (not in repo):**
- `~/.claude/skills/orbit-wp-security/SKILL.md`
- `~/.claude/skills/orbit-wp-performance/SKILL.md`
- `~/.claude/skills/orbit-wp-database/SKILL.md`
- `~/.claude/skills/orbit-wp-standards/SKILL.md`
