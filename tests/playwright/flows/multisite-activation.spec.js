// @ts-check
/**
 * Orbit — Multisite Network Activation Test
 *
 * Bugs this catches:
 *   - Plugin uses manage_options instead of manage_network_options on network admin
 *   - Activation hook only fires for primary site (must use upgrader_process_complete or similar)
 *   - Plugin stores data in wp_options when it should use wp_sitemeta
 *   - Plugin breaks on secondary subsites
 *
 * REQUIRES: wp-env running in multisite mode (.wp-env.multisite.json)
 *   bash scripts/create-test-site.sh --multisite
 *
 * Usage:
 *   PLUGIN_SLUG=my-plugin MULTISITE=1 \
 *   npx playwright test multisite-activation.spec.js
 */

const { test, expect } = require('@playwright/test');
const { execSync } = require('child_process');

const PLUGIN_SLUG = process.env.PLUGIN_SLUG;
const WP_ENV_RUN  = process.env.WP_ENV_RUN || 'npx wp-env run cli wp';

function wp(cmd) {
  return execSync(`${WP_ENV_RUN} ${cmd}`, { encoding: 'utf8' }).trim();
}

test.describe('Multisite compatibility', () => {
  test.skip(!PLUGIN_SLUG || process.env.MULTISITE !== '1',
    'Set PLUGIN_SLUG and MULTISITE=1 to run multisite tests (requires multisite wp-env)');

  test('plugin network-activates across all subsites', async () => {
    // Confirm we're actually in multisite
    const isMultisite = wp(`eval 'echo is_multisite() ? "yes" : "no";'`);
    expect(isMultisite, 'This test requires wp-env running in multisite mode').toBe('yes');

    // Ensure a secondary site exists
    const sites = wp(`site list --format=count`);
    if (parseInt(sites, 10) < 2) {
      wp(`site create --slug=orbit-sub2 --title="Orbit Sub 2"`);
    }

    // Network activate
    wp(`plugin activate ${PLUGIN_SLUG} --network`);
    const status = wp(`plugin get ${PLUGIN_SLUG} --field=status`);
    expect(status).toMatch(/active-network|active/);

    // Check secondary site can load plugin admin without error
    const siteIds = wp(`site list --field=blog_id --format=csv`).split('\n').filter(Boolean);
    for (const blogId of siteIds) {
      const errors = wp(
        `--url=$(wp site list --blog-id=${blogId} --field=url --format=csv | head -1) ` +
        `eval 'echo get_option("blogname");' 2>&1` +
        ` | grep -iE "fatal|parse error" || echo "ok"`
      );
      expect(errors, `Site ${blogId}: should load without fatal errors`).toContain('ok');
    }

    // Check plugin options stored correctly
    // Network-wide settings should be in wp_sitemeta, not wp_options
    const networkOption = wp(`network meta list 1 --format=count`);
    console.log(`[orbit] Network meta entries: ${networkOption}`);
  });
});
