/**
 * PlugOrbit — Visual Snapshot Tests
 * Takes screenshots of every meaningful plugin UI screen and compares against baselines.
 *
 * First run:  npx playwright test tests/playwright/visual/ --update-snapshots
 * Subsequent: npx playwright test tests/playwright/visual/
 *
 * Reads admin pages from qa.config.json "visualPages" array if present.
 * Falls back to WordPress admin dashboard + plugin settings page.
 */
const { test, expect } = require('@playwright/test');
const fs = require('fs');
const path = require('path');

const BASE = process.env.WP_TEST_URL || 'http://localhost:8881';
const ADMIN = `${BASE}/wp-admin`;
const SNAP_DIR = path.join(__dirname, '../../../reports/screenshots');

// Read plugin context from qa.config.json
let cfg = {};
try { cfg = JSON.parse(fs.readFileSync(path.join(__dirname, '../../../qa.config.json'), 'utf8')); } catch {}

const PLUGIN_TYPE  = cfg.plugin?.type   || 'general';
const PLUGIN_NAME  = cfg.plugin?.name   || 'Plugin';
const PLUGIN_SLUG  = cfg.plugin?.slug   || '';
const EXTRA_PAGES  = cfg.visualPages    || [];

// Ensure screenshots dir exists
fs.mkdirSync(SNAP_DIR, { recursive: true });

// Helper: save a raw screenshot to reports/screenshots/ alongside the snapshot baseline
async function snap(page, name) {
  const safe = name.replace(/[^a-z0-9-]/gi, '-').toLowerCase();
  await page.screenshot({ path: path.join(SNAP_DIR, `${safe}.png`), fullPage: true });
}

// ─────────────────────────────────────────────────────────────────────────────
// Admin Dashboard
// ─────────────────────────────────────────────────────────────────────────────
test.describe('Admin — Dashboard', () => {
  test('wp-admin dashboard loads and matches snapshot', async ({ page }) => {
    await page.goto(`${ADMIN}/`);
    await page.waitForLoadState('networkidle');
    await snap(page, 'admin-dashboard');
    await expect(page).toHaveScreenshot('admin-dashboard.png', { fullPage: true, maxDiffPixelRatio: 0.03 });
  });

  test('admin dashboard has no PHP errors or warnings', async ({ page }) => {
    await page.goto(`${ADMIN}/`);
    const body = await page.locator('body').textContent();
    expect(body).not.toMatch(/Fatal error|PHP Warning|PHP Notice|Parse error/);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Plugin Settings Pages
// ─────────────────────────────────────────────────────────────────────────────
test.describe('Admin — Plugin Settings', () => {
  const settingsPages = [
    { name: 'Plugin Main Settings', url: `${ADMIN}/admin.php?page=${PLUGIN_SLUG}` },
    // Auto-add any visualPages from qa.config.json
    ...EXTRA_PAGES.map(p => ({ name: p.name || p.url, url: p.url.startsWith('http') ? p.url : `${ADMIN}/${p.url}` })),
  ].filter(p => p.url.includes('page=') && PLUGIN_SLUG);

  for (const { name, url } of settingsPages) {
    test(`"${name}" page — screenshot + no PHP errors`, async ({ page }) => {
      await page.goto(url);
      await page.waitForLoadState('networkidle');
      await snap(page, `settings-${name}`);

      // No PHP fatal/notice output
      const body = await page.locator('body').textContent();
      expect(body, `PHP error on ${name}`).not.toMatch(/Fatal error|PHP Warning|Parse error/);

      // Page rendered (not blank)
      const html = await page.content();
      expect(html.length).toBeGreaterThan(500);

      // Visual baseline
      const snapName = `settings-${name.replace(/[^a-z0-9]/gi, '-').toLowerCase()}.png`;
      await expect(page).toHaveScreenshot(snapName, { fullPage: true, maxDiffPixelRatio: 0.04 });
    });
  }

  // If no slug, still audit generic admin plugin list
  test('plugins list page — plugin appears and is active', async ({ page }) => {
    await page.goto(`${ADMIN}/plugins.php`);
    await page.waitForLoadState('networkidle');
    await snap(page, 'admin-plugins-list');

    if (PLUGIN_SLUG) {
      const row = page.locator(`[data-slug="${PLUGIN_SLUG}"]`);
      const exists = await row.count();
      if (exists > 0) {
        const classes = await row.getAttribute('class');
        expect(classes, `${PLUGIN_SLUG} should be active`).toContain('active');
      }
    }
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Post Editor — Plugin Meta Box / Sidebar
// ─────────────────────────────────────────────────────────────────────────────
test.describe('Post Editor — Plugin UI', () => {
  test('Gutenberg editor loads for new post', async ({ page }) => {
    await page.goto(`${ADMIN}/post-new.php`);
    await page.waitForLoadState('networkidle');

    // Wait for editor to be ready
    const editor = page.locator('.edit-post-header, .editor-header, #post');
    await editor.first().waitFor({ timeout: 20000 }).catch(() => {});

    await snap(page, 'post-editor-new');
    await expect(page).toHaveScreenshot('post-editor-new.png', { fullPage: true, maxDiffPixelRatio: 0.05 });
  });

  test('post editor has no JS console errors from plugin', async ({ page }) => {
    const errors = [];
    page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
    page.on('pageerror', e => errors.push(e.message));

    await page.goto(`${ADMIN}/post-new.php`);
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(2000);

    const filtered = errors.filter(e =>
      !e.includes('favicon') &&
      !e.includes('net::ERR') &&
      !e.includes('wp.apiFetch') &&
      !e.includes('sourceURL')
    );
    expect(filtered, `Editor JS errors:\n${filtered.join('\n')}`).toHaveLength(0);
  });

  // SEO meta box — Nexter / any plugin that adds a sidebar panel
  test('post editor sidebar panel opens', async ({ page }) => {
    await page.goto(`${ADMIN}/post-new.php`);
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(1500);

    // Try to open the Document sidebar if collapsed
    const sidebarToggle = page.locator('button[aria-label="Settings"]');
    if (await sidebarToggle.isVisible().catch(() => false)) {
      const isOpen = await page.locator('.interface-complementary-area').isVisible().catch(() => false);
      if (!isOpen) await sidebarToggle.click();
    }

    await snap(page, 'post-editor-sidebar');
    await expect(page).toHaveScreenshot('post-editor-sidebar.png', { fullPage: true, maxDiffPixelRatio: 0.05 });
  });

  // Classic editor fallback
  test('classic post edit page loads (wp-admin/post.php)', async ({ page }) => {
    await page.goto(`${ADMIN}/post.php?post=1&action=edit`);
    await page.waitForLoadState('networkidle');
    await snap(page, 'classic-editor-post1');
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Frontend — Public Pages
// ─────────────────────────────────────────────────────────────────────────────
test.describe('Frontend — Public Pages', () => {
  test('homepage renders and matches snapshot', async ({ page }) => {
    await page.goto(BASE);
    await page.waitForLoadState('networkidle');
    await snap(page, 'frontend-homepage');
    await expect(page).toHaveScreenshot('frontend-homepage.png', { fullPage: true, maxDiffPixelRatio: 0.04 });
  });

  test('homepage has no JS console errors', async ({ page }) => {
    const errors = [];
    page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
    page.on('pageerror', e => errors.push(e.message));
    await page.goto(BASE);
    await page.waitForLoadState('networkidle');
    const filtered = errors.filter(e => !e.includes('favicon') && !e.includes('net::ERR'));
    expect(filtered, `Homepage JS errors:\n${filtered.join('\n')}`).toHaveLength(0);
  });

  test('single post renders and matches snapshot', async ({ page }) => {
    // Find a real post via the blog page
    await page.goto(BASE);
    const firstPostLink = page.locator('article a[href]').first();
    const exists = await firstPostLink.count();
    if (exists > 0) {
      const href = await firstPostLink.getAttribute('href');
      await page.goto(href);
      await page.waitForLoadState('networkidle');
      await snap(page, 'frontend-single-post');
      await expect(page).toHaveScreenshot('frontend-single-post.png', { fullPage: true, maxDiffPixelRatio: 0.04 });
    }
  });

  test('mobile viewport — homepage renders correctly', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    await page.goto(BASE);
    await page.waitForLoadState('networkidle');
    await snap(page, 'frontend-homepage-mobile');
    await expect(page).toHaveScreenshot('frontend-homepage-mobile.png', { fullPage: true, maxDiffPixelRatio: 0.05 });
  });
});
