---
name: orbit-host-kinsta
description: Kinsta compatibility audit — disallowed plugins, Cloudflare Enterprise edge caching, Kinsta CDN, object cache (Redis Pro available as add-on), staging push behaviour, MU plugin enforcement. Use when the user says "Kinsta", "managed WP Kinsta", "before customer hosts on Kinsta".
---

# 🪐 orbit-host-kinsta — Kinsta compat

Kinsta = Google Cloud + Cloudflare Enterprise + their own MU plugins. Their stack is more permissive than WPE but still has gotchas.

---

## What this skill checks

### 1. Disallowed plugins
Kinsta blocks select caching / monitoring plugins that conflict with their stack.

Current list (re-fetch from Kinsta docs on every audit):
- Caching: WP Rocket conflicts with Kinsta Cache (use one)
- Backup: BackupBuddy conflicts with native daily backups
- Some security plugins that try to write to wp-config

### 2. Cloudflare Enterprise edge caching
Kinsta runs Cloudflare Enterprise in front. Same cookie rules as WP Engine — your plugin's cookies bust edge cache for everyone unless excluded.

### 3. Object cache (Redis available as add-on)
**Whitepaper intent:** Redis isn't included in default plans. Plugins assuming `wp_cache_*` always hits a fast persistent cache will be slow on default-plan Kinsta sites.

```php
// Detect Redis availability
if ( wp_using_ext_object_cache() ) {
  // Persistent cache — safe to cache aggressively
} else {
  // No persistent — short TTLs only
}
```

### 4. MU plugin (`mu-plugins/kinsta-mu-plugins.php`)
Kinsta installs an MU plugin — your plugin can detect it:
```php
if ( defined( 'KINSTA_CACHE_ZONE' ) ) {
  // Running on Kinsta
}
```

### 5. Staging environment
Kinsta gives 1 staging environment per site. Your plugin should detect:
```php
if ( wp_get_environment_type() === 'staging' ) {
  // Disable production-only behaviour (analytics tracking, payment live mode)
}
```

### 6. PHP version flexibility
Kinsta supports PHP 7.4 / 8.0 / 8.1 / 8.2 / 8.3 — typically a release behind PHP main.

### 7. Disk write performance
Kinsta uses GCP persistent disks — slower than local SSD. Plugins that write large files frequently (logs) should batch.

---

## Output

```markdown
# Kinsta Compat — my-plugin

✓ Not on disallowed list
⚠ Plugin writes 1 log line per request — recommend batching (>100 writes/sec on busy site = perf hit)
✓ Detects KINSTA_CACHE_ZONE constant
✓ Uses wp_cache_set (works with Redis when available)
✓ Honours wp_get_environment_type for staging mode
```

---

## Pair with

- `/orbit-cache-compat` — Redis + edge caching
- `/orbit-host-wpengine` — similar concerns

---

## Sources & Evergreen References

### Canonical docs
- [Kinsta Help Center](https://kinsta.com/help/) — root
- [Banned Plugins](https://kinsta.com/blog/banned-plugins-kinsta/) — current list
- [Kinsta CDN + Edge](https://kinsta.com/help/edge-caching/) — caching layer
- [Redis Add-on](https://kinsta.com/help/redis-cache/) — when available

### Last reviewed
- 2026-04-29 — re-fetch banned-plugin list quarterly
