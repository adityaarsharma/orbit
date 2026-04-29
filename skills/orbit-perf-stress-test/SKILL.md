---
name: orbit-perf-stress-test
description: Stress-test a WordPress plugin's hot endpoints with k6 / JMeter — concurrent users hitting login / cart / form-submit / REST endpoint, measuring p50 / p95 / p99 latency, error rate, throughput. Catches plugins that look fast on a single request but melt under 100 concurrent. Use when the user says "stress test", "load test", "k6", "JMeter", "100 concurrent users".
---

# 🪐 orbit-perf-stress-test — Hot-endpoint stress testing

Lighthouse measures a single page load. Real users come in waves. This skill catches the bottlenecks that only appear under concurrent load.

---

## Quick start (k6)

```bash
# Install k6 once
brew install k6   # macOS
# or: https://k6.io/docs/getting-started/installation/

# Run a stress test
k6 run ~/Claude/orbit/scripts/k6/stress-frontend.js
```

Output: per-endpoint latency, throughput, error rate.

---

## What to test

### 1. Frontend page load (anonymous)
```js
// stress-frontend.js
import http from 'k6/http';
import { check } from 'k6';

export const options = {
  vus: 100,                  // 100 concurrent virtual users
  duration: '5m',            // for 5 minutes
  thresholds: {
    http_req_duration: ['p(95)<500'],   // 95% under 500ms
    http_req_failed: ['rate<0.01'],     // <1% errors
  },
};

export default function() {
  const res = http.get('http://localhost:8881/');
  check(res, { 'status 200': r => r.status === 200 });
}
```

### 2. REST endpoint (with rate limit awareness)
```js
export default function() {
  const res = http.get('http://localhost:8881/wp-json/my-plugin/v1/items');
  check(res, { '200 OK': r => r.status === 200 });
}
```

### 3. Form submission (state-mutating)
```js
export default function() {
  const res = http.post('http://localhost:8881/?form=contact', {
    name: 'k6 user', email: 'k6@example.com', message: 'load test',
  });
  check(res, { 'submission OK': r => r.status === 200 });
}
```

**Whitepaper intent:** Stress-test state-mutating endpoints carefully. They write to DB. Drain the DB after the run.

### 4. Cart / checkout (WooCommerce)
```js
export default function() {
  const session = http.cookieJar();
  http.get('http://localhost:8881/?p=' + productId);  // view product
  http.post('http://localhost:8881/?wc-ajax=add_to_cart', { product_id: productId });
  http.get('http://localhost:8881/cart/');
}
```

### 5. Editor performance (admin-side)
For Elementor/Gutenberg, simulate 50 widget inserts in 30 seconds — see if memory / queries grow linearly or quadratically.

---

## Targets

| Metric | Target | Bad |
|---|---|---|
| p50 latency (frontend) | < 200ms | > 500ms |
| p95 latency | < 800ms | > 2s |
| p99 latency | < 2s | > 5s |
| Error rate | < 0.1% | > 1% |
| Throughput | > 50 req/s | < 10 req/s |

---

## What "fails" mean

### Latency spikes mid-test
Likely DB lock or autoload growth. Check `wp_options` size + slow query log.

### Error rate climbs after N seconds
Connection pool exhaustion. Either: too many DB connections per request, or PHP-FPM children saturated.

### Throughput plateaus despite more VUs
Bottleneck found. Profile with Xdebug to find where time is spent.

### Memory growth across the run
Memory leak — see `/orbit-perf-memory-leak`.

---

## Output

```markdown
# Stress Test — my-plugin

## Test: 100 VUs × 5 min on /products/

p50: 280ms ✓
p95: 1,240ms ❌ (target < 800ms)
p99: 4,200ms ❌
Error rate: 0.4% ❌
Throughput: 38 req/s ⚠

## Findings
- Latency degrades from 200ms (start) to 1,800ms (end)
   → Likely DB lock contention. Check autoload growth.
- 0.4% errors are 502 Bad Gateway after 4 minutes
   → PHP-FPM saturation. Plugin uses `sleep()` somewhere?
```

---

## Pair with

- `/orbit-perf-memory-leak` — long-running memory issues
- `/orbit-db-profile` — DB-side bottleneck
- `/orbit-lighthouse` — single-load scoring

---

## Sources & Evergreen References

### Canonical docs
- [k6 Documentation](https://k6.io/docs/) — root
- [Apache JMeter](https://jmeter.apache.org/) — alternative tool
- [WP-CLI for Load Testing](https://make.wordpress.org/core/2018/02/15/wp-cli-improvements-in-wordpress-4-9/) — CLI primitives

### Rule lineage
- k6 — modern (Grafana-owned), JS-based, recommended over JMeter for new tests

### Last reviewed
- 2026-04-29
