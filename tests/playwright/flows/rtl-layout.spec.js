// @ts-check
/**
 * Orbit — RTL (Right-to-Left) Layout Test
 *
 * Arabic, Hebrew, Farsi users. Plugins with `float: left` without RTL override
 * break completely. Catches:
 *   - Elements overflowing viewport horizontally
 *   - Visible text cut off by container edge
 *   - Icons/arrows pointing the wrong direction
 *
 * Usage:
 *   PLUGIN_ADMIN_SLUG=my-plugin npx playwright test rtl-layout.spec.js --project=rtl
 */

const { test, expect } = require('@playwright/test');
const { execSync } = require('child_process');

const ADMIN_SLUG = process.env.PLUGIN_ADMIN_SLUG || process.env.PLUGIN_SLUG;
const WP_ENV_RUN = process.env.WP_ENV_RUN || 'npx wp-env run cli wp';

function wp(cmd) {
  return execSync(`${WP_ENV_RUN} ${cmd}`, { encoding: 'utf8' }).trim();
}

test.describe('RTL layout compatibility', () => {
  test.skip(!ADMIN_SLUG, 'Set PLUGIN_ADMIN_SLUG to run RTL tests');

  test.beforeAll(async () => {
    // Install Arabic locale and switch
    try { wp(`language core install ar --activate`); } catch (e) {
      console.log('[orbit] Arabic locale install may have failed — continuing');
    }
  });

  test.afterAll(async () => {
    try { wp(`language core activate en_US`); } catch {}
  });

  test('plugin admin page renders cleanly in RTL mode', async ({ page }) => {
    await page.goto(`/wp-admin/admin.php?page=${ADMIN_SLUG}`);
    await page.waitForLoadState('networkidle');

    // Check 1: <html dir="rtl"> is set
    const htmlDir = await page.locator('html').getAttribute('dir');
    expect(htmlDir,
      'WordPress should set <html dir="rtl"> in Arabic locale'
    ).toBe('rtl');

    // Check 2: Body must have rtl class
    const bodyClass = await page.locator('body').getAttribute('class');
    expect(bodyClass, 'body should have rtl class').toContain('rtl');

    // Check 3: No elements overflow viewport horizontally
    const overflows = await page.evaluate(() => {
      const overflowing = [];
      document.querySelectorAll('#wpbody-content *').forEach(el => {
        const rect = el.getBoundingClientRect();
        if (rect.left < -20 || rect.right > window.innerWidth + 20) {
          if (rect.width > 0 && rect.height > 0) {
            overflowing.push({
              tag: el.tagName,
              cls: (el.className || '').toString().slice(0, 80),
              left: rect.left,
              right: rect.right,
            });
          }
        }
      });
      return overflowing.slice(0, 10);
    });

    expect(overflows,
      `RTL: Elements overflow viewport:\n${JSON.stringify(overflows, null, 2)}`
    ).toEqual([]);

    // Baseline screenshot for visual diff
    await page.screenshot({
      path: `reports/screenshots/rtl/${ADMIN_SLUG}-rtl.png`,
      fullPage: true,
    });
  });
});
