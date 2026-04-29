---
name: orbit-host-shared
description: Audit a WordPress plugin for low-tier shared-hosting compatibility — memory limits (64MB common), execution-time limits (30s), disk-quota limits (1-5GB), no SSH, no shell exec, no Redis, slow disk I/O. Most "broken plugin" reports come from shared-hosting users hitting silent limits. Use when the user says "shared hosting", "Bluehost / GoDaddy / Hostinger compat", "low-tier hosting".
---

# 🪐 orbit-host-shared — Shared hosting compat

Shared hosting is where 60% of WP sites still live. Plugins that work on the dev's M2 Pro break on a 64MB shared plan. This skill catches the patterns.

---

## What this skill checks

### 1. Memory budget
**Whitepaper intent:** Shared hosts default to 64MB or 128MB PHP memory. WP core takes ~30MB at idle. That leaves ~30-90MB for the entire plugin stack. A plugin allocating 200MB of objects on activation kills the site.

```php
// Detect available memory
$limit = ini_get( 'memory_limit' );
$bytes = wp_convert_hr_to_bytes( $limit );
if ( $bytes < 128 * MB_IN_BYTES ) {
  // Low-memory mode: smaller batch sizes, no in-memory caching
}
```

### 2. Execution-time budget
30s default `max_execution_time`. Long-running operations (mass migrations, big DB queries) MUST chunk.

```php
// ❌ Process all 50,000 users in one request
foreach ( get_users() as $u ) { ... }   // 60 sec — dies

// ✅ Chunk via cron
wp_schedule_single_event( time(), 'my_plugin_process_chunk', [ 0, 500 ] );
```

### 3. No `exec()` / `shell_exec()`
Shared hosts disable these via `disable_functions`. Plugins using them break silently.

```php
// ❌ Will fail on most shared hosts
exec( 'gzip ' . $file );

// ✅ Use PHP-native or wp_remote
$gzipped = gzencode( file_get_contents( $file ) );
file_put_contents( $file . '.gz', $gzipped );
```

### 4. No Redis / Memcached
Default shared hosting = no persistent object cache. `wp_cache_*` falls back to in-process only. If your plugin assumes persistent cache to avoid heavy queries, every request is the heavy query.

### 5. No SSH
Can't run WP-CLI directly. Your plugin's CLI commands are inaccessible to most shared-hosting customers. Provide WP-Admin alternatives for everything CLI does.

### 6. Disk I/O is slow
Shared spinning-disk hosts have IOPS far below SSD. Plugins writing files frequently (logs, cache files) feel slow.

### 7. Quota limits
Some shared hosts cap WP_DEBUG log size, disk usage, DB rows. Plugins that grow `wp_options` or write 1000-row log tables can hit quotas mid-traffic.

### 8. Mod_security false positives
Shared hosts use mod_security WAF. Common patterns it blocks:
- POST bodies > 1MB
- URLs with `.git/` or `wp-config` in the query string
- `--`, `union select`, or other SQL-ish substrings in form fields

Your plugin's legitimate URL patterns shouldn't include these.

---

## Output

```markdown
# Shared Hosting Compat — my-plugin

## Memory
- ⚠ activate_plugin allocates ~150MB on first run — fails on 64MB hosts
- Recommendation: stream the data instead of loading into memory

## Execution time
- ⚠ Bulk-import accepts CSV up to 50K rows in one request
- Recommendation: process in 500-row chunks via cron

## Forbidden functions
- ✓ No exec() / shell_exec() detected
- ✓ No proc_open

## Cache assumption
- ⚠ Plugin assumes wp_cache_get returns same value across requests
- Reality: shared hosting often has no persistent cache
- Add fallback: re-query DB if cache miss; use transients (DB-backed) for cross-request

## Disk
- ⚠ 1 log line per request → grows unbounded
- Add log rotation OR write to error_log() OR add admin "clear log" button
```

---

## Pair with

- `/orbit-cache-compat` — cache assumptions
- `/orbit-wp-database` — DB query budget
- `/orbit-bundle-analysis` — frontend asset weight

---

## Sources & Evergreen References

### Canonical docs
- [WP Memory Limits](https://wordpress.org/documentation/article/editing-wp-config-php/#increasing-memory-allocated-to-php) — WP_MEMORY_LIMIT
- [PHP — disable_functions](https://www.php.net/manual/en/ini.core.php#ini.disable-functions) — host security
- [WP — Background Processing](https://github.com/A5hleyRich/wp-background-processing) — chunked patterns

### Last reviewed
- 2026-04-29
