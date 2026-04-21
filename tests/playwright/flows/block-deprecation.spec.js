// @ts-check
/**
 * Orbit — Gutenberg Block Deprecation Test
 *
 * Verifies existing block content doesn't throw "block validation error" after
 * an update. If a block's attribute schema changed without a `deprecated` entry,
 * existing posts containing that block show "this block contains unexpected
 * or invalid content" — effectively corrupts user data.
 *
 * Usage:
 *   PLUGIN_SLUG=my-blocks \
 *   BLOCK_POST_ID=42   # a post containing your block
 *   npx playwright test block-deprecation.spec.js
 */

const { test, expect } = require('@playwright/test');

const BLOCK_POST_ID = process.env.BLOCK_POST_ID;
const PLUGIN_SLUG   = process.env.PLUGIN_SLUG;

test.describe('Gutenberg block deprecation compatibility', () => {
  test.skip(!BLOCK_POST_ID, 'Set BLOCK_POST_ID to a post containing the plugin\'s blocks');

  test('existing block content loads without validation errors', async ({ page }) => {
    const consoleErrors = [];
    page.on('console', msg => {
      if (msg.type() === 'error') consoleErrors.push(msg.text());
    });

    await page.goto(`/wp-admin/post.php?post=${BLOCK_POST_ID}&action=edit`);
    await page.waitForSelector('.edit-post-visual-editor, .editor-styles-wrapper', { timeout: 30_000 });

    // Wait for block editor to hydrate
    await page.waitForTimeout(3000);

    // Check 1: No "block validation error" notices in the editor UI
    const invalidBlocks = await page.locator('.block-editor-warning, [class*="block-invalid"]').count();
    expect(invalidBlocks,
      `Block validation errors found — existing post content is now invalid. Add a 'deprecated' entry to the block definition.`
    ).toBe(0);

    // Check 2: No "unexpected content" error text
    const bodyText = await page.locator('body').innerText();
    expect(bodyText.toLowerCase(),
      'Editor shows "unexpected or invalid content" — block attributes changed without deprecation'
    ).not.toMatch(/this block contains unexpected|invalid content/);

    // Check 3: No console errors mentioning block validation
    const blockErrors = consoleErrors.filter(e =>
      /block.*validation|invalid.*block/i.test(e)
    );
    expect(blockErrors, `Block validation errors in console: ${blockErrors.slice(0,3).join('\n')}`).toEqual([]);

    console.log('[orbit] Block deprecation: PASSED — existing content loads cleanly');
  });
});
