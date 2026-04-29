---
name: orbit-perf-memory-leak
description: Detect PHP memory leaks in a WordPress plugin — runs the plugin's hot path N times in a single PHP process, measures `memory_get_usage()` after each iteration, flags linear growth (= leak). Catches plugins that grow memory across requests until OOM. Use when the user says "memory leak", "OOM", "memory grows", "PHP fatal: allowed memory exhausted".
---

# 🪐 orbit-perf-memory-leak — Memory leak detection

PHP-FPM workers stay alive across hundreds of requests. A small leak per request adds up to OOM by the end of the day.

---

## Quick start

```bash
php ~/Claude/orbit/scripts/leak-detector.php \
  --plugin ~/plugins/my-plugin \
  --iterations 100 \
  --hot-path "do_action('init'); apply_filters('the_content', '...');"
```

---

## How it works

1. Bootstrap WordPress in a CLI script
2. Activate the plugin
3. Run the "hot path" (e.g. `the_content` filter, REST endpoint logic, AJAX handler) N times
4. Record `memory_get_usage(true)` after each iteration
5. Plot growth curve

```
Iteration 1:    14.2 MB
Iteration 10:   14.5 MB
Iteration 50:   16.8 MB
Iteration 100:  19.4 MB

Linear regression: +51 KB per iteration ❌
```

51KB per request × 1000 requests = 50MB grown. Worker OOMs.

---

## Common leak causes

### Static caches that never evict
**Whitepaper intent:** A static array that holds "things we've fetched" sounds smart but never frees. Across 1000 requests it eats memory.

```php
// ❌
class Cache {
  private static $items = [];
  public static function get( $key ) {
    if ( ! isset( self::$items[ $key ] ) ) {
      self::$items[ $key ] = expensive_fetch( $key );
    }
    return self::$items[ $key ];
  }
}
// 1000 different keys × 1KB each = 1MB grown for the worker's lifetime

// ✅ Use WP transients (DB-backed, evicted by TTL)
function get_thing( $key ) {
  $cached = get_transient( "thing_$key" );
  if ( $cached !== false ) return $cached;
  $val = expensive_fetch( $key );
  set_transient( "thing_$key", $val, HOUR_IN_SECONDS );
  return $val;
}
```

### Event listeners not cleaned
```php
// ❌ Adds listener every call
function my_thing() {
  add_action( 'init', 'my_callback' );  // accumulates
}

// ✅ Add once on plugin load
add_action( 'plugins_loaded', function() {
  add_action( 'init', 'my_callback' );
});
```

### Circular references
PHP's GC handles most circular references but slowly. Build-up can be visible.

### Resource handles not closed
```php
// ❌
$ch = curl_init();
// ... never call curl_close()

// ✅
curl_close( $ch );
```

### Database connection leaks (rare in WP, common in custom code)
Don't manually create new mysqli connections — use `$wpdb`.

---

## Output

```markdown
# Memory Leak — my-plugin

## Test: 1000 iterations of hot path

Memory at iteration 1:    14.2 MB
Memory at iteration 1000: 64.8 MB
Growth: +51 KB / iteration

## Severity: HIGH (ATM the worker OOMs after ~3000 requests)

## Top suspects (heap diff)
- includes/class-cache.php:42 — static $items grows 47KB/iter
   → Replace with WP transient
- includes/class-listener.php:18 — add_action called inside hot path
   → Move registration to plugins_loaded
```

---

## Pair with

- `/orbit-perf-stress-test` — leak surfaces under sustained load
- `/orbit-wp-database` — many leaks correlate with DB query bloat
- `/orbit-bundle-analysis` — JS-side memory leaks (different tool)

---

## Sources & Evergreen References

### Canonical docs
- [PHP — memory_get_usage](https://www.php.net/manual/en/function.memory-get-usage.php) — primitive
- [Xhprof](https://github.com/longxinH/xhprof) — heap profiling
- [Tideways](https://tideways.com/) — production profiler (paid)

### Last reviewed
- 2026-04-29
