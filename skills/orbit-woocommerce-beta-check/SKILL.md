---
name: orbit-woocommerce-beta-check
description: Install WooCommerce Beta Tester on a Docker/InstaWP site, switch WooCommerce to the latest beta release, then run a full site health sweep. Trigger phrases — "woocommerce beta", "test woo beta", "orbit-woocommerce-beta-check", "beta tester woo", "switch woo to beta", "latest woo beta", "check beta release". Works against a live Sprout MCP-connected site or a local wp-env Docker site.
---

# 🪐 orbit-woocommerce-beta-check — WooCommerce Beta Tester + Full-Site Sweep

Installs **WooCommerce Beta Tester**, switches WooCommerce to the latest **beta / RC channel**, then runs an automated health sweep across site health, REST API, WooCommerce system status, PHP error log, and all critical frontend + admin flows.

Use this skill:
- Before filing a WooCommerce bug to confirm it's a beta regression
- As a pre-release gate before shipping a WooCommerce extension
- On every WooCommerce RC/beta release day to catch breaking changes early

---

## Quick start

### Against a live Sprout MCP site (InstaWP / staging)
```
/orbit-woocommerce-beta-check
```
The skill uses the already-connected Sprout MCP tools automatically.

### Against a local Docker / wp-env site
```bash
bash scripts/woo-beta-check.sh --port 8881
```

Output: `reports/woo-beta-check-<timestamp>.md`

---

## Phase 1 — Environment setup

### 1a. Verify Docker site is running (local path only)

```bash
curl -sI http://localhost:8881/wp-admin | head -1
# → HTTP/1.1 302 Found  ← WP is up

wp-env run cli wp plugin list --status=active --fields=name,version
```

If site is not running:
```bash
bash scripts/create-test-site.sh --plugin ~/plugins/woocommerce --port 8881 --woo
```

### 1b. Verify WooCommerce is active

```php
// Via Sprout super-brain
return [
  'woo_active'    => class_exists('WooCommerce'),
  'woo_version'   => defined('WC_VERSION') ? WC_VERSION : 'not found',
  'php_version'   => PHP_VERSION,
  'wp_version'    => get_bloginfo('version'),
];
```

---

## Phase 2 — Install & configure WooCommerce Beta Tester

### 2a. Install plugin if missing

```php
// Check + install via Sprout super-brain
require_once ABSPATH . 'wp-admin/includes/file.php';
require_once ABSPATH . 'wp-admin/includes/plugin.php';

$slug        = 'woocommerce-beta-tester';
$plugin_file = 'woocommerce-beta-tester/woocommerce-beta-tester.php';
$is_installed = file_exists(WP_PLUGIN_DIR . '/' . $plugin_file);

if (!$is_installed) {
    // Download + extract manually (bypasses WP_TEMP_DIR restriction on InstaWP)
    $zip_url  = 'https://downloads.wordpress.org/plugin/woocommerce-beta-tester.zip';
    $zip_path = '/home/' . get_current_user() . '/tmp/woocommerce-beta-tester.zip';
    $extr_dir = '/home/' . get_current_user() . '/tmp/wbt_extract';

    wp_remote_get($zip_url, ['timeout' => 120, 'stream' => true, 'filename' => $zip_path]);

    $zip = new ZipArchive();
    $zip->open($zip_path);
    $zip->extractTo($extr_dir);
    $zip->close();
    unlink($zip_path);

    // rcopy() helper (see Phase upgrade script below)
    rcopy($extr_dir . '/woocommerce-beta-tester', WP_PLUGIN_DIR . '/woocommerce-beta-tester');
}

activate_plugin($plugin_file);
return ['installed' => $is_installed, 'now_active' => is_plugin_active($plugin_file)];
```

### 2b. Switch to beta / RC channel

```php
// WooCommerce Beta Tester stores its channel in a WP option
$channel = 'beta';   // values: 'beta' | 'rc' | 'stable'

update_option('woocommerce_beta_tester_channel', $channel);

// Confirm
return [
  'channel_set' => get_option('woocommerce_beta_tester_channel'),
  'current_woo' => WC_VERSION,
];
```

### 2c. Fetch latest beta version info

```php
wp_update_plugins();
$transient = get_site_transient('update_plugins');
$woo_file  = 'woocommerce/woocommerce.php';

$update = $transient->response[$woo_file] ?? $transient->no_update[$woo_file] ?? null;
return [
  'current_version' => WC_VERSION,
  'available_beta'  => $update ? $update->new_version : 'none found',
  'channel'         => get_option('woocommerce_beta_tester_channel'),
];
```

---

## Phase 3 — Upgrade WooCommerce to latest beta

```php
// Full manual upgrade (works around WP_TEMP_DIR open_basedir on InstaWP)
require_once ABSPATH . 'wp-admin/includes/file.php';
require_once ABSPATH . 'wp-admin/includes/plugin.php';

function rcopy($src, $dst) {
    if (!is_dir($dst)) mkdir($dst, 0755, true);
    foreach (scandir($src) as $item) {
        if ($item === '.' || $item === '..') continue;
        $s = $src . '/' . $item; $d = $dst . '/' . $item;
        is_dir($s) ? rcopy($s, $d) : copy($s, $d);
    }
}
function rrmdir($dir) {
    if (!is_dir($dir)) return;
    $it = new RecursiveDirectoryIterator($dir, RecursiveDirectoryIterator::SKIP_DOTS);
    foreach (new RecursiveIteratorIterator($it, RecursiveIteratorIterator::CHILD_FIRST) as $f) {
        $f->isDir() ? rmdir($f->getRealPath()) : unlink($f->getRealPath());
    }
    rmdir($dir);
}

// Get beta download URL from Beta Tester update checker
$transient = get_site_transient('update_plugins');
$woo_file  = 'woocommerce/woocommerce.php';
$update    = $transient->response[$woo_file] ?? null;

if (!$update) return ['skipped' => true, 'reason' => 'No beta update available in transient'];

$tmp    = sys_get_temp_dir();
$zip    = $tmp . '/woocommerce-beta.zip';
$extr   = $tmp . '/woo_beta_extract';

$resp = wp_remote_get($update->package, ['timeout' => 300, 'stream' => true, 'filename' => $zip]);
if (is_wp_error($resp)) return ['error' => $resp->get_error_message()];

if (is_dir($extr)) rrmdir($extr);
mkdir($extr, 0755, true);

$z = new ZipArchive();
$z->open($zip); $z->extractTo($extr); $z->close();
unlink($zip);

$src = glob($extr . '/woocommerce*', GLOB_ONLYDIR)[0] ?? null;
if (!$src) { rrmdir($extr); return ['error' => 'Extracted dir not found']; }

rcopy($src, WP_PLUGIN_DIR . '/woocommerce');
rrmdir($extr);

// Reload plugin data
$data = get_plugin_data(WP_PLUGIN_DIR . '/woocommerce/woocommerce.php', false, false);
return ['success' => true, 'new_version' => $data['Version']];
```

---

## Phase 4 — Full-site health sweep

Run all checks after the upgrade. Each returns a pass/fail + notes.

### 4a. PHP fatal error check

```php
$log_path = WP_CONTENT_DIR . '/debug.log';
if (!file_exists($log_path)) return ['fatals' => 0, 'log' => 'no debug.log'];

$lines  = file($log_path);
$fatals = array_filter($lines, fn($l) => stripos($l, 'Fatal error') !== false);
$woo    = array_filter($fatals, fn($l) => stripos($l, 'woocommerce') !== false);

return [
  'total_fatals'     => count($fatals),
  'woo_fatals'       => count($woo),
  'last_5_woo_fatals' => array_slice(array_values($woo), -5),
];
```

### 4b. WooCommerce system status

```php
return WC()->api->get_endpoint_data('/wc/v3/system_status');
// OR via REST:
// GET /wp-json/wc/v3/system_status (with auth)
```

Key fields to check:
| Field | Pass condition |
|---|---|
| `environment.wp_version` | ≥ WC minimum |
| `environment.wc_version` | matches installed beta |
| `database.wc_database_version` | matches `wc_db_version` option |
| `active_plugins` | no missing dependencies |
| `theme.has_woocommerce_support` | `true` |

### 4c. WordPress site health

```php
require_once ABSPATH . 'wp-admin/includes/class-wp-site-health.php';
$health = WP_Site_Health::get_instance();
$issues = $health->get_test_results();

$critical = array_filter($issues['tests']['direct'] ?? [], fn($t) => $t['status'] === 'critical');
$recommended = array_filter($issues['tests']['direct'] ?? [], fn($t) => $t['status'] === 'recommended');

return [
  'critical_count'     => count($critical),
  'recommended_count'  => count($recommended),
  'critical_labels'    => array_column($critical, 'label'),
];
```

### 4d. WooCommerce REST API health

```php
$response = wp_remote_get(home_url('/wp-json/wc/v3/products?per_page=1'), [
  'headers' => [
    'Authorization' => 'Basic ' . base64_encode('admin:password'),
  ],
  'timeout' => 15,
]);

return [
  'status_code'  => wp_remote_retrieve_response_code($response),
  'api_ok'       => wp_remote_retrieve_response_code($response) === 200,
  'woo_version'  => json_decode(wp_remote_retrieve_body($response), true)[0]['id'] ?? 'empty',
];
```

### 4e. WooCommerce Store API (no auth)

```php
$response = wp_remote_get(home_url('/wp-json/wc/store/v1/cart'), ['timeout' => 10]);
return [
  'status_code' => wp_remote_retrieve_response_code($response),
  'store_api_ok' => wp_remote_retrieve_response_code($response) === 200,
];
```

### 4f. Frontend smoke test (Playwright — local Docker path)

```js
// tests/playwright/woo-beta-smoke.spec.js
import { test, expect } from '@playwright/test';

const BASE = process.env.WP_TEST_URL || 'http://localhost:8881';

test.describe('WooCommerce Beta Smoke', () => {

  test('Shop page loads', async ({ page }) => {
    await page.goto(`${BASE}/shop/`);
    await expect(page.locator('.woocommerce-products-header, ul.products')).toBeVisible();
    await expect(page).toHaveTitle(/shop/i);
  });

  test('Single product page loads', async ({ page }) => {
    // Grab first product from Store API
    const res  = await page.request.get(`${BASE}/wp-json/wc/store/v1/products?per_page=1`);
    const prod = (await res.json())[0];
    await page.goto(prod.permalink);
    await expect(page.locator('button[name="add-to-cart"]')).toBeVisible();
  });

  test('Add to cart + cart page', async ({ page }) => {
    const res  = await page.request.get(`${BASE}/wp-json/wc/store/v1/products?per_page=1`);
    const prod = (await res.json())[0];
    await page.goto(prod.permalink);
    await page.click('button[name="add-to-cart"]');
    await page.goto(`${BASE}/cart/`);
    await expect(page.locator('.cart_item, .wp-block-woocommerce-cart')).toBeVisible();
  });

  test('Checkout page renders (Block Checkout)', async ({ page }) => {
    // Add item first
    const res  = await page.request.get(`${BASE}/wp-json/wc/store/v1/products?per_page=1`);
    const prod = (await res.json())[0];
    await page.goto(prod.permalink);
    await page.click('button[name="add-to-cart"]');
    await page.goto(`${BASE}/checkout/`);
    // Both classic and block checkout selectors
    const checkout = page.locator('.woocommerce-checkout, .wp-block-woocommerce-checkout');
    await expect(checkout).toBeVisible();
  });

  test('WP Admin — WooCommerce dashboard', async ({ page }) => {
    await page.goto(`${BASE}/wp-admin/admin.php?page=wc-admin`);
    // redirects to login if not authed — handled by auth.setup.js
    await expect(page.locator('.woocommerce-layout__header, .woocommerce-homescreen')).toBeVisible();
  });

  test('WP Admin — Orders list', async ({ page }) => {
    await page.goto(`${BASE}/wp-admin/admin.php?page=wc-orders`);
    await expect(page.locator('.wp-list-table, .woocommerce-layout__header')).toBeVisible();
  });

  test('No JS console errors on shop', async ({ page }) => {
    const errors = [];
    page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });
    await page.goto(`${BASE}/shop/`);
    await page.waitForLoadState('networkidle');
    expect(errors.filter(e => !e.includes('favicon'))).toHaveLength(0);
  });

});
```

Run:
```bash
WP_TEST_URL=http://localhost:8881 npx playwright test tests/playwright/woo-beta-smoke.spec.js
```

### 4g. HPOS compatibility check

```php
$hpos_enabled = get_option('woocommerce_custom_orders_table_enabled') === 'yes';
$declared = class_exists('\Automattic\WooCommerce\Utilities\FeaturesUtil')
  ? \Automattic\WooCommerce\Utilities\FeaturesUtil::feature_is_enabled('custom_order_tables')
  : false;

return [
  'hpos_active'   => $hpos_enabled,
  'hpos_declared' => $declared,
  'warning'       => ($hpos_enabled && !$declared) ? 'Plugin not declared HPOS compatible' : null,
];
```

### 4h. Database version check

```php
global $wpdb;
$db_version   = get_option('woocommerce_db_version');
$code_version = WC_VERSION;
$in_sync      = version_compare($db_version, $code_version, '==');

// Check for pending migrations
$pending = \Automattic\WooCommerce\Internal\Updates\UpdateCallbacks::get_pending_db_updates();

return [
  'db_version'      => $db_version,
  'code_version'    => $code_version,
  'versions_match'  => $in_sync,
  'pending_updates' => count($pending ?? []),
];
```

---

## Output format

```markdown
# WooCommerce Beta Check — jigarposimyth.instawp.xyz
Generated: 2026-06-30 09:00 UTC

## Environment
| | |
|---|---|
| WordPress | 6.8.1 |
| WooCommerce (before) | 10.9.1 |
| WooCommerce (after) | 10.10.0-beta.1 |
| PHP | 8.3.8 |
| Channel | beta |

## Phase Results
| Phase | Status | Notes |
|---|---|---|
| Beta Tester install | ✅ Pass | Already active |
| Channel → beta | ✅ Pass | Set to beta |
| WooCommerce upgrade | ✅ Pass | 10.9.1 → 10.10.0-beta.1 |
| PHP fatal errors | ✅ Pass | 0 WC fatals in debug.log |
| WC System Status | ✅ Pass | DB version in sync |
| WP Site Health | ⚠️ Warn | 2 recommended fixes |
| REST API `/wc/v3` | ✅ Pass | HTTP 200 |
| Store API `/wc/store/v1` | ✅ Pass | HTTP 200 |
| Shop page | ✅ Pass | Renders OK |
| Single product | ✅ Pass | Add-to-cart visible |
| Cart page | ✅ Pass | Item visible |
| Block Checkout | ✅ Pass | Renders OK |
| WC Admin | ✅ Pass | Dashboard loads |
| Orders list | ✅ Pass | HPOS table renders |
| JS console errors | ✅ Pass | 0 errors on /shop/ |
| HPOS compat | ✅ Pass | Declared compatible |
| DB version | ✅ Pass | In sync, 0 pending |

## Findings
[list any Critical / High / Medium issues here]

## Recommendation
[PASS / FAIL / INVESTIGATE]
```

---

## Common findings + fixes

| Finding | Cause | Fix |
|---|---|---|
| `PHP Fatal: Call to undefined method` | Beta removed or renamed a WC method | Check WC changelog; use `method_exists()` guard |
| `DB version mismatch` | Beta added DB migrations that haven't run | Navigate to WP Admin — WooCommerce will auto-run migrations on next load |
| `HPOS not declared` | Plugin missing compat declaration | Add `FeaturesUtil::declare_compatibility('custom_order_tables', __FILE__, true)` |
| `Block Checkout missing` | Beta changed block registration hook | Check `woocommerce_blocks_loaded` hook timing |
| `Store API 404` | Beta renamed endpoint | Check WC REST API changelog |
| `JS console errors` | Beta changed asset handles or enqueue order | Enable `SCRIPT_DEBUG` and trace the failing asset |
| `WP_TEMP_DIR blocked` | InstaWP open_basedir restriction | Use manual zip download to `/home/<user>/tmp` (see Phase 3 above) |

---

## Pair with

- `/orbit-docker-site` — spin up a clean local wp-env site before running this check
- `/orbit-uat-woo` — full WooCommerce UAT with Playwright specs
- `/orbit-wp-performance` — catch perf regressions introduced by the beta
- `/orbit-wp-database` — verify HPOS query patterns still work post-upgrade
- `/orbit-conflict-matrix` — test beta WooCommerce against other active plugins

---

## Full automation script (wp-env / Docker)

```bash
#!/usr/bin/env bash
# scripts/woo-beta-check.sh
# Usage: bash scripts/woo-beta-check.sh --port 8881
set -euo pipefail

PORT=8881
while [[ $# -gt 0 ]]; do
  case $1 in --port) PORT=$2; shift 2;; *) shift;; esac
done

WP="wp-env run cli wp --url=http://localhost:${PORT}"
REPORT="reports/woo-beta-check-$(date +%Y%m%d-%H%M%S).md"
mkdir -p reports

echo "# WooCommerce Beta Check" > "$REPORT"
echo "Generated: $(date -u)" >> "$REPORT"

# 1. Install Beta Tester
echo "→ Installing WooCommerce Beta Tester..."
$WP plugin install woocommerce-beta-tester --activate 2>&1 | tee -a "$REPORT"

# 2. Set beta channel
echo "→ Setting channel to beta..."
$WP option update woocommerce_beta_tester_channel beta

# 3. Check for update
echo "→ Checking for beta update..."
$WP transient delete --all
$WP plugin update woocommerce 2>&1 | tee -a "$REPORT"

# 4. Verify new version
echo "→ WooCommerce version after update:"
$WP plugin get woocommerce --field=version 2>&1 | tee -a "$REPORT"

# 5. Run DB upgrades
echo "→ Running WC DB upgrades..."
$WP wc update 2>/dev/null || true

# 6. Site health
echo "→ Running WP site health..."
$WP site health check 2>&1 | tee -a "$REPORT" || true

# 7. Playwright smoke
echo "→ Running Playwright smoke tests..."
WP_TEST_URL="http://localhost:${PORT}" \
  npx playwright test tests/playwright/woo-beta-smoke.spec.js \
  --reporter=line 2>&1 | tee -a "$REPORT"

echo ""
echo "✅ Report saved: $REPORT"
```

---

## When to run

- On every WooCommerce beta / RC release announcement
- Before submitting a WooCommerce.com extension update
- After adding WooCommerce hooks to a plugin, to confirm they still fire in the beta
- As a scheduled weekly check against the `beta` channel to catch regressions early

---

## Hard rules

- ❌ Never run against a live production store — beta WooCommerce can corrupt order data
- ❌ Never commit WooCommerce beta to a production site without full UAT pass
- ❌ Never skip Phase 4d (DB version check) — silent DB mismatches break HPOS silently
- ✅ Always run against a clean DB snapshot or staging/test site
- ✅ Always revert to stable (`woocommerce_beta_tester_channel = stable`) if any Critical finding
- ✅ Always clear WP transients after changing channel — stale update cache returns wrong version
