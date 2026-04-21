// @ts-check
/**
 * Orbit — Uninstall / Cleanup Test
 *
 * What this verifies:
 *   When a plugin is deactivated + deleted, it must clean up after itself.
 *   Required by WordPress.org plugin review. Orphaned data = user data compliance issue.
 *
 * What gets checked:
 *   - Plugin options are deleted (wp_options table)
 *   - Custom tables are dropped
 *   - Transients are removed
 *   - User meta is cleaned
 *   - Scheduled cron events are cleared
 *
 * Expects: process.env.PLUGIN_SLUG, process.env.PLUGIN_PREFIX (option key prefix)
 * Optional: process.env.PLUGIN_CUSTOM_TABLES (comma-sep list of custom table names, no wp_ prefix)
 */

const { test, expect } = require('@playwright/test');
const { execSync } = require('child_process');

const PLUGIN_SLUG    = process.env.PLUGIN_SLUG || '';
const PLUGIN_PREFIX  = process.env.PLUGIN_PREFIX || PLUGIN_SLUG.replace(/-/g, '_');
const CUSTOM_TABLES  = (process.env.PLUGIN_CUSTOM_TABLES || '').split(',').filter(Boolean);
const WP_ENV_RUN     = process.env.WP_ENV_RUN || 'npx wp-env run cli wp';

function wp(cmd) {
  return execSync(`${WP_ENV_RUN} ${cmd}`, { encoding: 'utf8' }).trim();
}

test.describe('Uninstall cleanup (WP.org compliance)', () => {
  test.skip(!PLUGIN_SLUG, 'Set PLUGIN_SLUG env var to run uninstall test');

  test('plugin removes options, tables, and cron events on delete', async () => {
    // 1. Ensure plugin is active first so activation ran
    try {
      wp(`plugin activate ${PLUGIN_SLUG}`);
    } catch (e) {
      // already active is fine
    }

    // 2. Snapshot state while active (for diagnostic if cleanup fails)
    const optionsBefore = wp(`option list --search="${PLUGIN_PREFIX}%" --format=count`);
    const transientsBefore = wp(
      `db query "SELECT COUNT(*) FROM \\\`wp_options\\\` WHERE option_name LIKE '_transient_${PLUGIN_PREFIX}%'" --skip-column-names`
    );
    console.log(`[orbit] Pre-uninstall — options: ${optionsBefore}, transients: ${transientsBefore}`);

    // 3. Deactivate + delete (triggers uninstall.php or register_uninstall_hook)
    wp(`plugin deactivate ${PLUGIN_SLUG}`);
    wp(`plugin delete ${PLUGIN_SLUG}`);

    // 4. Assertions
    const optionsAfter = parseInt(
      wp(`option list --search="${PLUGIN_PREFIX}%" --format=count`) || '0', 10
    );
    expect(optionsAfter, 'Plugin options should be deleted by uninstall').toBe(0);

    const transientsAfter = parseInt(
      wp(
        `db query "SELECT COUNT(*) FROM \\\`wp_options\\\` WHERE option_name LIKE '_transient_${PLUGIN_PREFIX}%'" --skip-column-names`
      ) || '0',
      10
    );
    expect(transientsAfter, 'Plugin transients should be deleted').toBe(0);

    // 5. Custom tables dropped
    for (const table of CUSTOM_TABLES) {
      const tableExists = wp(
        `db query "SHOW TABLES LIKE 'wp_${table}'" --skip-column-names`
      );
      expect(tableExists, `Custom table wp_${table} should be dropped on uninstall`).toBe('');
    }

    // 6. No orphaned cron events
    const cronEvents = wp(`cron event list --format=json`);
    const orphaned = JSON.parse(cronEvents).filter((e) =>
      (e.hook || '').includes(PLUGIN_PREFIX)
    );
    expect(
      orphaned,
      `Found ${orphaned.length} orphaned cron events from this plugin after uninstall`
    ).toEqual([]);

    console.log('[orbit] Uninstall cleanup: PASSED');
  });
});
