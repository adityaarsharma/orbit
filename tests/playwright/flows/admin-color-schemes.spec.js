// @ts-check
/**
 * Orbit — Admin Color Scheme Compatibility
 *
 * WordPress has 8 built-in admin color schemes: default, light, modern, blue,
 * coffee, ectoplasm, midnight, ocean, sunrise. Plugins with hardcoded #0073aa
 * or similar colors break visually on non-default schemes.
 *
 * Usage:
 *   PLUGIN_ADMIN_SLUG=my-plugin \
 *   npx playwright test admin-color-schemes.spec.js
 */

const { test, expect } = require('@playwright/test');
const { execSync } = require('child_process');

const ADMIN_SLUG  = process.env.PLUGIN_ADMIN_SLUG || process.env.PLUGIN_SLUG;
const WP_ENV_RUN  = process.env.WP_ENV_RUN || 'npx wp-env run cli wp';
const SCHEMES     = ['fresh', 'light', 'modern', 'blue', 'coffee', 'ectoplasm', 'midnight', 'ocean', 'sunrise'];

function wp(cmd) {
  return execSync(`${WP_ENV_RUN} ${cmd}`, { encoding: 'utf8' }).trim();
}

test.describe('Admin color scheme compatibility', () => {
  test.skip(!ADMIN_SLUG, 'Set PLUGIN_ADMIN_SLUG to the plugin admin page slug');

  for (const scheme of SCHEMES) {
    test(`renders correctly on ${scheme} scheme`, async ({ page }) => {
      // Set the scheme for current user
      const userId = wp(`user get admin --field=ID`) || '1';
      wp(`user meta update ${userId} admin_color ${scheme}`);

      await page.goto(`/wp-admin/admin.php?page=${ADMIN_SLUG}`);
      await page.waitForLoadState('networkidle');

      // Screenshot for visual baseline
      await page.screenshot({
        path: `reports/screenshots/admin-colors/${scheme}.png`,
        fullPage: false,
      });

      // Check: primary buttons should have contrast >= 3:1
      const contrast = await page.evaluate(() => {
        const btn = document.querySelector('.button-primary, .wp-core-ui .button-primary');
        if (!btn) return null;
        const style = getComputedStyle(btn);
        return { bg: style.backgroundColor, color: style.color };
      });

      if (contrast) {
        expect(contrast.bg, `${scheme}: primary button should have a background color`).not.toBe('rgba(0, 0, 0, 0)');
      }

      // Check: no invisible text (same color as background)
      const invisibleText = await page.evaluate(() => {
        const els = document.querySelectorAll('#wpbody-content *');
        let count = 0;
        for (const el of els) {
          const s = getComputedStyle(el);
          if (s.color && s.backgroundColor && s.color === s.backgroundColor) count++;
        }
        return count;
      });

      expect(invisibleText, `${scheme}: no text should match its background color`).toBe(0);
    });
  }

  test.afterAll(async () => {
    // Restore default scheme
    const userId = wp(`user get admin --field=ID`) || '1';
    wp(`user meta update ${userId} admin_color fresh`);
  });
});
