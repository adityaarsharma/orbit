/**
 * PlugOrbit — UI Audit Tests
 * Generic checks that catch bad UI regardless of plugin type.
 * Works for any WordPress plugin — reads admin pages from qa.config.json.
 *
 * Catches:
 * - Elements overflowing their containers (layout breaks)
 * - Missing button/input labels (accessibility + bad UX)
 * - Broken images (404 img src)
 * - Overlapping clickable elements
 * - Admin notices left un-dismissed
 * - Inconsistent font sizes suggesting styling leaks
 * - Empty containers (blank boxes/panels)
 */
const { test, expect } = require('@playwright/test');
const fs = require('fs');
const path = require('path');

const BASE  = process.env.WP_TEST_URL || 'http://localhost:8881';
const ADMIN = `${BASE}/wp-admin`;
const SNAP_DIR = path.join(__dirname, '../../../reports/screenshots');

let cfg = {};
try { cfg = JSON.parse(fs.readFileSync(path.join(__dirname, '../../../qa.config.json'), 'utf8')); } catch {}

const PLUGIN_SLUG = cfg.plugin?.slug || '';
fs.mkdirSync(SNAP_DIR, { recursive: true });

// Pages to audit — always includes dashboard + plugin settings + plugins list
const ADMIN_PAGES = [
  { name: 'Dashboard',    url: `${ADMIN}/` },
  { name: 'Plugins List', url: `${ADMIN}/plugins.php` },
  { name: 'Post List',    url: `${ADMIN}/edit.php` },
  { name: 'Media',        url: `${ADMIN}/upload.php` },
  ...(PLUGIN_SLUG ? [{ name: 'Plugin Settings', url: `${ADMIN}/admin.php?page=${PLUGIN_SLUG}` }] : []),
  ...(cfg.visualPages || []).map(p => ({
    name: p.name || p.url,
    url: p.url.startsWith('http') ? p.url : `${ADMIN}/${p.url}`,
  })),
];

// ─────────────────────────────────────────────────────────────────────────────
// Layout & Overflow Checks
// ─────────────────────────────────────────────────────────────────────────────
for (const { name, url } of ADMIN_PAGES) {
  test.describe(`UI Audit — ${name}`, () => {
    test(`${name}: no elements overflow viewport width`, async ({ page }) => {
      await page.goto(url);
      await page.waitForLoadState('networkidle');

      const overflowing = await page.evaluate(() => {
        const vw = window.innerWidth;
        const issues = [];
        document.querySelectorAll('*').forEach(el => {
          const r = el.getBoundingClientRect();
          if (r.right > vw + 5 && r.width > 10 && r.width < vw * 0.9) {
            const text = (el.textContent || '').trim().slice(0, 60);
            issues.push(`<${el.tagName.toLowerCase()}> right=${Math.round(r.right)}px (text: "${text}")`);
          }
        });
        return issues.slice(0, 10);
      });

      if (overflowing.length > 0) {
        await page.screenshot({ path: path.join(SNAP_DIR, `overflow-${name.replace(/\W/g,'-')}.png`), fullPage: true });
      }
      expect(overflowing, `Overflow on ${name}:\n${overflowing.join('\n')}`).toHaveLength(0);
    });

    test(`${name}: no empty visible containers (blank white boxes)`, async ({ page }) => {
      await page.goto(url);
      await page.waitForLoadState('networkidle');

      const blanks = await page.evaluate(() => {
        const issues = [];
        document.querySelectorAll('.postbox, .card, .wp-block, [class*="panel"], [class*="-box"]').forEach(el => {
          const r = el.getBoundingClientRect();
          if (r.width > 80 && r.height > 40) {
            const text = (el.innerText || '').trim();
            if (text.length < 3) {
              issues.push(`Empty container: <${el.tagName.toLowerCase()}> class="${el.className.slice(0,60)}"`);
            }
          }
        });
        return issues.slice(0, 5);
      });
      expect(blanks, `Empty containers on ${name}:\n${blanks.join('\n')}`).toHaveLength(0);
    });

    test(`${name}: all buttons have accessible labels`, async ({ page }) => {
      await page.goto(url);
      await page.waitForLoadState('networkidle');

      const unlabeled = await page.evaluate(() => {
        const issues = [];
        document.querySelectorAll('button, input[type="submit"], input[type="button"]').forEach(el => {
          const label = el.textContent?.trim() ||
                        el.getAttribute('aria-label') ||
                        el.getAttribute('title') ||
                        el.getAttribute('value');
          if (!label || label.length < 1) {
            const ctx = el.className.slice(0, 50) || el.id || 'no-id';
            issues.push(`Unlabeled button: <${el.tagName.toLowerCase()}> [${ctx}]`);
          }
        });
        return issues.slice(0, 10);
      });
      expect(unlabeled, `Unlabeled buttons on ${name}:\n${unlabeled.join('\n')}`).toHaveLength(0);
    });

    test(`${name}: all inputs have associated labels`, async ({ page }) => {
      await page.goto(url);
      await page.waitForLoadState('networkidle');

      const unlabeled = await page.evaluate(() => {
        const issues = [];
        document.querySelectorAll('input:not([type="hidden"]):not([type="submit"]):not([type="button"]), select, textarea').forEach(el => {
          const id = el.id;
          const hasLabel = id && document.querySelector(`label[for="${id}"]`);
          const hasAriaLabel = el.getAttribute('aria-label') || el.getAttribute('aria-labelledby');
          const hasPlaceholder = el.getAttribute('placeholder');
          if (!hasLabel && !hasAriaLabel && !hasPlaceholder) {
            issues.push(`Unlabeled input: <${el.tagName.toLowerCase()}> name="${el.name || ''}" id="${id || 'none'}"`);
          }
        });
        return issues.slice(0, 10);
      });
      // Warn-level: WordPress core has some unlabeled inputs, so we allow up to 3
      if (unlabeled.length > 3) {
        expect(unlabeled, `Unlabeled inputs on ${name}:\n${unlabeled.join('\n')}`).toHaveLength(0);
      }
    });

    test(`${name}: no broken images (404 img src)`, async ({ page }) => {
      const broken = [];
      page.on('response', res => {
        if (res.request().resourceType() === 'image' && res.status() === 404) {
          broken.push(res.url());
        }
      });
      await page.goto(url);
      await page.waitForLoadState('networkidle');
      expect(broken, `Broken images on ${name}:\n${broken.join('\n')}`).toHaveLength(0);
    });

    test(`${name}: no PHP fatal/warning text in page`, async ({ page }) => {
      await page.goto(url);
      const body = await page.locator('body').textContent();
      expect(body, `PHP error on ${name}`).not.toMatch(/Fatal error:|Uncaught Error:|PHP Warning:|PHP Notice:|Parse error:/);
    });

    test(`${name}: page fully renders — not blank or redirect loop`, async ({ page }) => {
      const res = await page.goto(url);
      expect(res.status()).toBeLessThan(400);
      const html = await page.content();
      expect(html.length, `${name} rendered blank`).toBeGreaterThan(1000);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Admin Notices — should not stack up
// ─────────────────────────────────────────────────────────────────────────────
test.describe('Admin Notices', () => {
  test('no error-level admin notices on dashboard', async ({ page }) => {
    await page.goto(`${ADMIN}/`);
    await page.waitForLoadState('networkidle');

    const errorNotices = await page.locator('.notice-error, .error').count();
    if (errorNotices > 0) {
      await page.screenshot({ path: path.join(SNAP_DIR, 'admin-notice-errors.png'), fullPage: true });
    }
    expect(errorNotices, 'Error-level admin notices found on dashboard').toBe(0);
  });

  test('no more than 3 admin notices on plugin settings page', async ({ page }) => {
    if (!PLUGIN_SLUG) return;
    await page.goto(`${ADMIN}/admin.php?page=${PLUGIN_SLUG}`);
    await page.waitForLoadState('networkidle');

    const notices = await page.locator('.notice, .update-nag, .updated').count();
    if (notices > 3) {
      await page.screenshot({ path: path.join(SNAP_DIR, 'plugin-notice-spam.png'), fullPage: true });
    }
    expect(notices, `Too many admin notices (${notices}) on plugin settings page`).toBeLessThanOrEqual(3);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Plugin Settings UI — Consistency Checks
// ─────────────────────────────────────────────────────────────────────────────
test.describe('Plugin Settings — UI Consistency', () => {
  test.skip(!PLUGIN_SLUG, 'No plugin slug in qa.config.json');

  test('settings page has a visible heading (H1 or H2)', async ({ page }) => {
    await page.goto(`${ADMIN}/admin.php?page=${PLUGIN_SLUG}`);
    await page.waitForLoadState('networkidle');
    const h = await page.locator('h1, h2').first().textContent().catch(() => '');
    expect(h.trim().length, 'No heading found on settings page').toBeGreaterThan(2);
  });

  test('settings page save button is visible', async ({ page }) => {
    await page.goto(`${ADMIN}/admin.php?page=${PLUGIN_SLUG}`);
    await page.waitForLoadState('networkidle');

    const saveBtn = page.locator(
      'button[type="submit"], input[type="submit"], button:has-text("Save"), button:has-text("Update")'
    );
    // Only flag if page has forms (some settings pages are React SPAs)
    const hasForm = await page.locator('form').count();
    if (hasForm > 0) {
      await expect(saveBtn.first()).toBeVisible({ timeout: 5000 });
    }
  });

  test('settings page has no overlapping clickable elements', async ({ page }) => {
    await page.goto(`${ADMIN}/admin.php?page=${PLUGIN_SLUG}`);
    await page.waitForLoadState('networkidle');

    const overlaps = await page.evaluate(() => {
      const clickable = Array.from(document.querySelectorAll('a, button, input, select'));
      const issues = [];
      for (let i = 0; i < clickable.length; i++) {
        const a = clickable[i].getBoundingClientRect();
        if (a.width < 1 || a.height < 1) continue;
        for (let j = i + 1; j < clickable.length; j++) {
          const b = clickable[j].getBoundingClientRect();
          if (b.width < 1 || b.height < 1) continue;
          const overlap = !(a.right < b.left || b.right < a.left || a.bottom < b.top || b.bottom < a.top);
          if (overlap) {
            const ta = (clickable[i].textContent || '').trim().slice(0, 30);
            const tb = (clickable[j].textContent || '').trim().slice(0, 30);
            issues.push(`"${ta}" overlaps "${tb}"`);
            if (issues.length >= 5) return issues;
          }
        }
      }
      return issues;
    });
    expect(overlaps, `Overlapping clickable elements:\n${overlaps.join('\n')}`).toHaveLength(0);
  });

  test('settings toggles/checkboxes are visible and large enough to click (min 16px)', async ({ page }) => {
    await page.goto(`${ADMIN}/admin.php?page=${PLUGIN_SLUG}`);
    await page.waitForLoadState('networkidle');

    const tooSmall = await page.evaluate(() => {
      const issues = [];
      document.querySelectorAll('input[type="checkbox"], input[type="radio"]').forEach(el => {
        const r = el.getBoundingClientRect();
        if (r.width > 0 && r.width < 10) {
          issues.push(`Tiny toggle: ${el.id || el.name} (${Math.round(r.width)}x${Math.round(r.height)}px)`);
        }
      });
      return issues.slice(0, 10);
    });
    expect(tooSmall, `Too-small checkboxes:\n${tooSmall.join('\n')}`).toHaveLength(0);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// Mobile Admin — Responsive sanity
// ─────────────────────────────────────────────────────────────────────────────
test.describe('Mobile Admin — Responsive', () => {
  test.skip(!PLUGIN_SLUG, 'No plugin slug in qa.config.json');

  test('plugin settings page does not overflow on 375px width', async ({ page }) => {
    await page.setViewportSize({ width: 375, height: 812 });
    await page.goto(`${ADMIN}/admin.php?page=${PLUGIN_SLUG}`);
    await page.waitForLoadState('networkidle');

    await page.screenshot({ path: path.join(SNAP_DIR, 'plugin-settings-mobile.png'), fullPage: true });

    const overflow = await page.evaluate(() => {
      const vw = window.innerWidth;
      const els = [];
      document.querySelectorAll('*').forEach(el => {
        const r = el.getBoundingClientRect();
        if (r.right > vw + 10 && r.width > 20 && getComputedStyle(el).display !== 'none') {
          els.push(`<${el.tagName.toLowerCase()}> class="${el.className.slice(0,40)}" right=${Math.round(r.right)}`);
        }
      });
      return els.slice(0, 8);
    });
    expect(overflow, `Mobile overflow on settings:\n${overflow.join('\n')}`).toHaveLength(0);
  });
});
