---
name: orbit-plugin-check
description: Run the official WordPress.org `plugin-check` tool against your plugin — mirrors the exact checks the WP.org review team runs at submission. Catches: forbidden functions, security gaps, i18n issues, readme.txt format, plugin header completeness, and 50+ other rules. Use when the user says "WP.org submission", "plugin-check", "official checks", or before any release destined for the WordPress.org repo.
---

# 🪐 orbit-plugin-check — Official WP.org submission checker

WP.org's official `plugin-check` tool — the one their review team uses. Run it BEFORE submitting and you skip 80% of submission rejections.

---

## Quick start

```bash
# Install (one-time)
wp plugin install plugin-check --activate

# Run via WP-CLI inside wp-env
wp-env run cli wp plugin check my-plugin

# Or via the admin UI
open http://localhost:8881/wp-admin/admin.php?page=plugin-check
```

Or via gauntlet (Step 11, in `--mode release`):
```bash
bash scripts/gauntlet.sh --plugin . --mode release
```

---

## What it checks (the 50+ rules)

### Forbidden functions
- `eval()`
- `assert()` with string arg
- `create_function()`
- `proc_open()`, `popen()`, `shell_exec()`, `passthru()`, `system()`
- `mysql_*` (use `$wpdb`)
- `mysqli_*` direct
- `curl_init` (use `wp_remote_get`)
- `file_get_contents` with URL (use `wp_remote_get`)
- `error_reporting`, `ini_set('display_errors', ...)`

### Security
- Direct `$_GET` / `$_POST` / `$_REQUEST` use without sanitization
- Missing `wp_nonce_field` on forms
- Missing `wp_verify_nonce` on form handlers
- Missing capability checks
- `wp_kses_post` on output of unsafe sources
- Hardcoded passwords / API keys

### i18n
- Strings not wrapped in `__()` / `_e()` / etc.
- Text domain mismatch with plugin folder
- POT file missing or stale

### readme.txt
- Required fields present (Stable tag, Tested up to, Requires PHP, License)
- Tags max 12, no trademarks
- Changelog includes entry for current Stable tag
- Description / Installation sections non-empty

### Plugin header
- All required fields (see `/orbit-release-meta`)
- License GPL-compatible
- Plugin Name doesn't start with "WordPress"
- Plugin Name doesn't contain trademarks (Yoast, Elementor, WooCommerce, etc.) unless you own them

### Code quality
- File-level `<?php` opening tag (no leading whitespace)
- Closing `?>` not present (or only at end with no trailing whitespace)
- No BOM (byte-order mark) in PHP files
- Files end with newline
- No accidental `.DS_Store` / IDE artefacts

### Block-specific (if Gutenberg blocks)
- Every `block.json` valid
- `block.json` referenced files exist
- Block names follow `namespace/name` format
- Server-side render preferred over client-side `save`

---

## Severity model

| Type | Severity | Action |
|---|---|---|
| ERROR | **Block submission** | Must fix |
| WARNING | Should fix | Strongly recommended |
| INFO | Nice to have | Often ignored |

WP.org review team rejects on any ERROR. Some WARNINGs they wave through; others they push back on inconsistently. Treat warnings as fix-required to be safe.

---

## Common findings + fixes

### `eval()` detected
You're using `eval`. Stop. Refactor to a switch / match statement. WP.org rejects on this 100% of the time.

### `Plugin name conflicts with trademark`
Your plugin is named "Best Yoast SEO Helper". Rename to remove "Yoast". Use generic terms like "SEO Helper" or your own brand.

### `Stable tag does not match latest version in changelog`
```
Stable tag: 2.3.0
== Changelog ==
= 2.4.0 =                ← changelog has a newer version, but Stable tag points old
```
Either bump Stable tag to 2.4.0 or remove the 2.4.0 changelog entry.

### `File contains BOM`
A UTF-8 BOM (3 bytes: `EF BB BF`) at start of a PHP file breaks output. Strip it:
```bash
sed -i '1s/^\xEF\xBB\xBF//' path/to/file.php
```

### `Direct DB query without prepare`
```php
// ❌
$wpdb->query( "SELECT * FROM wp_my_table WHERE id = $id" );

// ✅
$wpdb->query( $wpdb->prepare( "SELECT * FROM wp_my_table WHERE id = %d", $id ) );
```

### `Hardcoded API key`
Don't ship API keys in source code. Use a settings option that the user fills in:
```php
$key = get_option( 'my_plugin_api_key' );
```

---

## When to run

- **Before any WP.org submission** — non-negotiable. Plugin-check catches what review will flag.
- **Before tagging a release** — even non-WP.org plugins benefit
- **After a major refactor** — verify no new violations slipped in
- **CI** — fail the build on any ERROR

---

## CI

```yaml
- name: Plugin Check
  run: |
    cd wordpress
    wp plugin install plugin-check --activate --allow-root
    wp plugin check my-plugin --allow-root --format=json > pc.json
    jq '.errors | length' pc.json | grep -q '^0$' || exit 1
```

---

## Configure exclusions (sparingly)

`.plugin-check-config.json` in plugin root:
```json
{
  "exclusions": [
    "vendor/",
    "tests/",
    "build/"
  ],
  "skip": [
    "Internationalization",  // skip whole category
    "Plugin_Header_Tested_Up_To"  // skip specific check
  ]
}
```

**Don't skip security or forbidden-function checks.** Those exist for good reason.

---

## Pair with `/orbit-release-meta` and `/orbit-zip-hygiene`

Three layers of release validation:
- `/orbit-release-meta` — plugin header + readme.txt + version parity
- `/orbit-plugin-check` — official WP.org rules (this skill)
- `/orbit-zip-hygiene` — what's in the actual release zip

All three must pass for a clean WP.org submission. `/orbit-release-gate` runs all three.
