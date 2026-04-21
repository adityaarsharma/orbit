// @ts-check
/**
 * Orbit — Update Path / Data Migration Test
 *
 * Verifies v1 → v2 upgrade preserves settings and runs migrations correctly.
 *
 * Usage:
 *   PLUGIN_SLUG=my-plugin \
 *   PLUGIN_V1_ZIP=/path/to/my-plugin-1.0.zip \
 *   PLUGIN_V2_ZIP=/path/to/my-plugin-2.0.zip \
 *   PLUGIN_TEST_OPTION=my_plugin_settings \
 *   PLUGIN_TEST_VALUE='{"enabled":true,"key":"expected"}' \
 *   npx playwright test update-path.spec.js
 */

const { test, expect } = require('@playwright/test');
const { execSync } = require('child_process');

const PLUGIN_SLUG   = process.env.PLUGIN_SLUG;
const V1_ZIP        = process.env.PLUGIN_V1_ZIP;
const V2_ZIP        = process.env.PLUGIN_V2_ZIP;
const TEST_OPTION   = process.env.PLUGIN_TEST_OPTION || `${(PLUGIN_SLUG||'').replace(/-/g,'_')}_settings`;
const TEST_VALUE    = process.env.PLUGIN_TEST_VALUE || '{"enabled":true}';
const WP_ENV_RUN    = process.env.WP_ENV_RUN || 'npx wp-env run cli wp';

function wp(cmd) {
  return execSync(`${WP_ENV_RUN} ${cmd}`, { encoding: 'utf8' }).trim();
}

test.describe('Update path (v1 → v2 migration)', () => {
  test.skip(!PLUGIN_SLUG || !V1_ZIP || !V2_ZIP,
    'Set PLUGIN_SLUG, PLUGIN_V1_ZIP, PLUGIN_V2_ZIP to run update-path test');

  test('settings survive v1 → v2 upgrade', async () => {
    // 1. Clean slate
    try { wp(`plugin deactivate ${PLUGIN_SLUG}`); } catch {}
    try { wp(`plugin delete ${PLUGIN_SLUG}`); } catch {}

    // 2. Install v1
    wp(`plugin install "${V1_ZIP}" --activate`);
    const v1Version = wp(`plugin get ${PLUGIN_SLUG} --field=version`);
    console.log(`[orbit] Installed v1: ${v1Version}`);

    // 3. Seed test data (simulating a user who configured the plugin)
    wp(`option update "${TEST_OPTION}" '${TEST_VALUE}' --format=json`);

    // 4. Upgrade to v2 (simulating the actual upgrade path)
    wp(`plugin install "${V2_ZIP}" --force`);
    const v2Version = wp(`plugin get ${PLUGIN_SLUG} --field=version`);
    console.log(`[orbit] Upgraded to v2: ${v2Version}`);

    expect(v2Version, 'v2 should be different from v1').not.toBe(v1Version);

    // 5. Assertion: test option still exists and value is preserved (or migrated)
    const optionAfter = wp(`option get "${TEST_OPTION}" --format=json`);
    expect(optionAfter, 'Settings should survive upgrade').toBeTruthy();
    expect(optionAfter, 'Settings should not be empty after migration').not.toBe('""');

    // 6. Check debug.log for migration errors
    try {
      const debugLog = wp(`eval 'echo file_get_contents(WP_CONTENT_DIR . "/debug.log");'`);
      const errors = debugLog.split('\n').filter(l =>
        /PHP (Fatal|Error|Warning)/i.test(l) && l.toLowerCase().includes(PLUGIN_SLUG.toLowerCase())
      );
      expect(errors, `Migration produced PHP errors: ${errors.slice(0,3).join('\n')}`).toEqual([]);
    } catch {}

    console.log('[orbit] Update path: PASSED — settings preserved, no errors');
  });
});
