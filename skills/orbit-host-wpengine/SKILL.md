---
name: orbit-host-wpengine
description: WP Engine compatibility audit — disallowed plugins list, file-system locks, mu-plugins enforcement, page cache (NGINX FastCGI), object cache (Memcached), staging-vs-production environment detection, EverCache. Use when the user says "WP Engine", "WPE", "managed WP", "before customer hosts on WP Engine".
---

# 🪐 orbit-host-wpengine — WP Engine compat

WP Engine is the largest managed-WP host. Their environment has hard-coded restrictions plugins must respect.

---

## What this skill checks

### 1. Disallowed plugins list
WP Engine bans certain plugins (caching plugins that conflict with EverCache, backup plugins that conflict with their snapshots, etc.). If your plugin tries to set up its own caching → flagged in WPE customer audits.

```
Disallowed list (subset, current as of 2026-04):
- Caching: W3 Total Cache, WP Super Cache, WP Rocket (uses EverCache instead)
- Backup: BackupBuddy, BackUpWordPress (uses native snapshots)
- Hit counter: WP Postviews, etc.

Full list: https://wpengine.com/support/disallowed-plugins/
```

### 2. File-system writes restricted
WP Engine locks certain directories. Plugins writing to those break.

```php
// ❌ Will fail silently on WPE
file_put_contents( WP_CONTENT_DIR . '/cache/my-plugin/foo.txt', $data );

// ✅ Use uploads dir (always writable)
$uploads = wp_upload_dir();
file_put_contents( $uploads['basedir'] . '/my-plugin/foo.txt', $data );
```

### 3. Object cache (Memcached) awareness
WPE provides Memcached. Use it via `wp_cache_*`:
```php
wp_cache_set( 'my_key', $value, 'my-plugin', HOUR_IN_SECONDS );
$value = wp_cache_get( 'my_key', 'my-plugin' );
```

### 4. Page cache (EverCache) busting cookies
WPE's NGINX cache respects `wp_*` and `wordpress_*` cookies. Custom plugin cookies bust the cache for ALL visitors unless declared.

**Whitepaper intent:** A `my_plugin_visitor_id` cookie set on every page kills the page-cache hit rate, dropping a site's frontend perf 80%+.

```php
// Customer needs to add to WPE's User Portal → Cache → Cache exclusion:
//   Cookie: my_plugin_visitor_id (don't bust cache for this)

// Or only set the cookie for logged-in users (cache isn't used for them anyway):
if ( is_user_logged_in() ) setcookie( 'my_plugin_visitor_id', ... );
```

### 5. Environment detection
```php
if ( defined( 'WPE_APIKEY' ) || defined( 'IS_WPE' ) ) {
  // Running on WP Engine
}

// Detect staging vs production
$env = wp_get_environment_type();  // 'production', 'staging', 'development'
```

### 6. PHP / WP version constraints
WPE typically supports:
- PHP 7.4 / 8.0 / 8.1 / 8.2 / 8.3 (configurable per-environment)
- Latest WP + 1 prior major

If your plugin requires PHP 8.4+, customers on WPE can't use it yet (as of 2026).

### 7. WP-CLI access (yes, available)
WPE supports SSH gateway → WP-CLI. Plugins shipping CLI commands work fine.

---

## Output

```markdown
# WP Engine Compat — my-plugin

✓ Plugin not on WPE disallowed list
⚠ Writes to wp-content/cache/my-plugin/ — relocate to wp-uploads/
✓ Uses wp_cache_set/get for Memcached
❌ Sets `my_plugin_visitor_id` cookie on every visit — busts EverCache for all visitors
   → Either restrict to logged-in users, or document for WPE customers
✓ Detects WPE via IS_WPE constant
✓ Compatible with PHP 7.4 → 8.3
```

---

## Pair with

- `/orbit-cache-compat` — broader cache compat (WPE EverCache + others)
- `/orbit-host-kinsta` — similar managed-host concerns

---

## Sources & Evergreen References

### Canonical docs
- [WP Engine Support](https://wpengine.com/support/) — root
- [Disallowed Plugins](https://wpengine.com/support/disallowed-plugins/) — current list (re-fetch monthly)
- [WP Engine for Developers](https://wpengine.com/developers/) — environment specs
- [Cache Exclusions](https://wpengine.com/support/cache/) — cookie/header rules

### Last reviewed
- 2026-04-29 — re-fetch the disallowed-plugins list monthly (changes)
