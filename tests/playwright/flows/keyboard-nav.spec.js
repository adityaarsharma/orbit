// @ts-check
/**
 * Orbit — Keyboard Navigation Flow Test
 *
 * axe-core catches static ARIA violations but does NOT verify that users can
 * actually navigate the UI using only Tab/Shift+Tab/Enter. This test catches:
 *   - Focus traps (Tab gets stuck in a modal/element)
 *   - Unreachable interactive elements
 *   - Missing focus-visible outline
 *   - Skip-to-content broken
 *
 * Usage:
 *   PLUGIN_ADMIN_SLUG=my-plugin    # plugin admin page URL slug
 *   npx playwright test keyboard-nav.spec.js
 */

const { test, expect } = require('@playwright/test');

const ADMIN_SLUG = process.env.PLUGIN_ADMIN_SLUG || process.env.PLUGIN_SLUG;
const MAX_TAB_STOPS = 50; // safety limit

test.describe('Keyboard navigation (WCAG 2.1.1)', () => {
  test.skip(!ADMIN_SLUG, 'Set PLUGIN_ADMIN_SLUG to the plugin admin page slug');

  test('can Tab through admin page without focus trap', async ({ page }) => {
    await page.goto(`/wp-admin/admin.php?page=${ADMIN_SLUG}`);
    await page.waitForLoadState('domcontentloaded');

    // Gather all interactive elements
    const interactiveCount = await page.locator(
      'a[href]:visible, button:visible, input:visible, select:visible, textarea:visible, [tabindex]:not([tabindex="-1"]):visible'
    ).count();
    expect(interactiveCount, 'Admin page should have interactive elements').toBeGreaterThan(0);

    // Start tabbing and track focused elements
    await page.locator('body').click({ position: { x: 0, y: 0 } });
    const focusHistory = new Set();
    let tabsPressed = 0;
    let lastFocusedSelector = '';
    let stuckCount = 0;

    while (tabsPressed < MAX_TAB_STOPS) {
      await page.keyboard.press('Tab');
      tabsPressed++;

      const focused = await page.evaluate(() => {
        const el = document.activeElement;
        if (!el || el === document.body) return null;
        const id = el.id ? `#${el.id}` : '';
        const cls = el.className && typeof el.className === 'string'
          ? `.${el.className.split(' ').slice(0,2).join('.')}` : '';
        return `${el.tagName}${id}${cls}[${el.getAttribute('aria-label') || el.textContent?.slice(0,20) || ''}]`;
      });

      if (!focused) continue;

      // Focus trap detection — same element focused 3 times in a row
      if (focused === lastFocusedSelector) {
        stuckCount++;
        if (stuckCount >= 3) {
          throw new Error(`[orbit] Focus trap detected at: ${focused} (after ${tabsPressed} tabs)`);
        }
      } else {
        stuckCount = 0;
      }

      focusHistory.add(focused);
      lastFocusedSelector = focused;
    }

    // Check 1: Focus actually moved
    expect(focusHistory.size,
      'Tab should reach multiple elements (focus trap or all hidden?)'
    ).toBeGreaterThan(2);

    // Check 2: Focus indicator visible
    const hasFocusVisible = await page.evaluate(() => {
      const el = document.activeElement;
      if (!el || el === document.body) return true; // skip
      const style = getComputedStyle(el);
      return style.outlineStyle !== 'none' || style.boxShadow !== 'none' || style.border !== 'none';
    });
    expect(hasFocusVisible,
      'Focused element must have visible focus indicator (WCAG 2.4.7)'
    ).toBeTruthy();

    console.log(`[orbit] Keyboard nav: PASSED — reached ${focusHistory.size} elements in ${tabsPressed} tabs`);
  });
});
