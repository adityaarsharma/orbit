/**
 * Orbit PM — UI Spell-Check Scan
 *
 * Extracts all visible strings from the plugin's admin pages — labels,
 * buttons, tooltips, placeholders, headings, notices — and checks for
 * typos using a built-in pattern list + cspell (if installed).
 *
 * Output: reports/pm-ux/spell-check-findings.json
 *         reports/pm-ux/extracted-ui-text.txt  (for cspell)
 *
 * Severity: WARN (never hard-blocks a release — PM judgment call)
 */

const { test, expect } = require('@playwright/test');
const fs   = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const WP_BASE    = process.env.WP_TEST_URL || 'http://localhost:8881';
const ADMIN_BASE = `${WP_BASE}/wp-admin`;
const REPORT_DIR = 'reports/pm-ux';

// ── Common typo dictionary ────────────────────────────────────────────────────
// Covers the 60 most frequent plugin UI spelling errors — context-agnostic,
// safe to flag regardless of what the plugin does.
const KNOWN_TYPOS = {
  'recieve': 'receive',       'seperate': 'separate',
  'occured': 'occurred',      'acheive': 'achieve',
  'beleive': 'believe',       'calender': 'calendar',
  'definately': 'definitely', 'existance': 'existence',
  'frequecy': 'frequency',    'grammer': 'grammar',
  'independant': 'independent','neccessary': 'necessary',
  'noticable': 'noticeable',  'occassion': 'occasion',
  'persistant': 'persistent', 'priviledge': 'privilege',
  'reccomend': 'recommend',   'relevent': 'relevant',
  'sucessful': 'successful',  'suprise': 'surprise',
  'untill': 'until',          'wierd': 'weird',
  'writting': 'writing',      'arguement': 'argument',
  'begining': 'beginning',    'bussiness': 'business',
  'catagory': 'category',     'compatability': 'compatibility',
  'configration': 'configuration', 'dashbord': 'dashboard',
  'deafult': 'default',       'descripion': 'description',
  'disabe': 'disable',        'eable': 'enable',
  'excepiton': 'exception',   'exlcude': 'exclude',
  'extention': 'extension',   'intergration': 'integration',
  'languge': 'language',      'manully': 'manually',
  'messge': 'message',        'metada': 'metadata',
  'naviagtion': 'navigation', 'notifcation': 'notification',
  'permision': 'permission',  'plguin': 'plugin',
  'prefernce': 'preference',  'prview': 'preview',
  'regsiter': 'register',     'seting': 'setting',
  'setings': 'settings',      'synchonize': 'synchronize',
  'templte': 'template',      'thurbnail': 'thumbnail',
  'uninstal': 'uninstall',    'validaton': 'validation',
  'varialbe': 'variable',     'widhet': 'widget',
  'custome': 'custom',        'generat': 'generate',
  'imge': 'image',            'improt': 'import',
  'colum': 'column',          'allways': 'always',
  'tendancy': 'tendency',     'occuring': 'occurring',
};

function scanForTypos(text, pageUrl, elementType) {
  const findings = [];
  const words = text.toLowerCase().match(/\b[a-z]{4,}\b/g) || [];
  const seen  = new Set();
  for (const word of words) {
    if (KNOWN_TYPOS[word] && !seen.has(word)) {
      seen.add(word);
      findings.push({
        typo: word,
        suggestion: KNOWN_TYPOS[word],
        context: text.trim().slice(0, 80),
        page: pageUrl,
        element: elementType,
      });
    }
  }
  return findings;
}

// ── Page text extractor ───────────────────────────────────────────────────────
async function extractPageText(page) {
  return page.evaluate(() => {
    const items = [];
    const push  = (type, text) => {
      const t = text.trim();
      if (t.length > 2) items.push({ type, text: t });
    };

    document.querySelectorAll('label').forEach(el => push('label', el.innerText));
    document.querySelectorAll('button, input[type="submit"], input[type="button"]').forEach(el =>
      push('button', el.innerText || el.value || ''));
    document.querySelectorAll('.button, .btn, .wp-button').forEach(el =>
      push('button', el.innerText));
    document.querySelectorAll('[title]').forEach(el =>
      push('tooltip', el.getAttribute('title') || ''));
    document.querySelectorAll('[data-tip], [data-tooltip]').forEach(el =>
      push('tooltip', el.getAttribute('data-tip') || el.getAttribute('data-tooltip') || ''));
    document.querySelectorAll('.description, .help-text, .field-description, .howto').forEach(el =>
      push('help-text', el.innerText));
    document.querySelectorAll('.nav-tab, .wp-submenu a, .wp-menu-name').forEach(el =>
      push('nav', el.innerText));
    document.querySelectorAll('.wrap h1, .wrap h2, .postbox h2, .postbox h3, .section-title').forEach(el =>
      push('heading', el.innerText));
    document.querySelectorAll('input[placeholder], textarea[placeholder], select[placeholder]').forEach(el =>
      push('placeholder', el.getAttribute('placeholder') || ''));
    document.querySelectorAll('.notice p, .notice-info p, .notice-warning p, .error p, .updated p').forEach(el =>
      push('notice', el.innerText));
    document.querySelectorAll('th, td.column-name, .column-title').forEach(el =>
      push('table-header', el.innerText));

    return items;
  });
}

// ── Discover plugin admin pages ───────────────────────────────────────────────
async function discoverPluginPages(page) {
  const adminSlug = process.env.PLUGIN_ADMIN_SLUG || '';
  const pages     = new Set();

  if (adminSlug) pages.add(`${ADMIN_BASE}/admin.php?page=${adminSlug}`);

  // Load WP admin and read submenu links belonging to the plugin
  await page.goto(ADMIN_BASE, { waitUntil: 'domcontentloaded' }).catch(() => {});

  const links = await page.evaluate((base) => {
    return Array.from(document.querySelectorAll('#adminmenu a'))
      .map(a => a.href)
      .filter(h => h.includes('page=') && h.startsWith(base));
  }, ADMIN_BASE);

  // Exclude core WP pages — only plugin-specific slugs
  const coreSlugs = new Set(['dashboard', 'posts', 'pages', 'media', 'plugins',
    'themes', 'users', 'tools', 'options-general', 'edit-comments',
    'woocommerce', 'index']);
  for (const link of links) {
    const slug = new URL(link).searchParams.get('page') || '';
    if (slug && !coreSlugs.has(slug)) pages.add(link);
  }

  return [...pages].slice(0, 12); // cap at 12 pages
}

// ── Tests ─────────────────────────────────────────────────────────────────────
test.describe('PM UX — Spell-Check Scan', () => {
  let allFindings = [];
  let pagesScanned = 0;
  const allRawText = [];

  test.afterAll(() => {
    fs.mkdirSync(REPORT_DIR, { recursive: true });

    // Save structured findings
    fs.writeFileSync(
      path.join(REPORT_DIR, 'spell-check-findings.json'),
      JSON.stringify({ pagesScanned, findings: allFindings }, null, 2)
    );

    // Save raw text for cspell
    const rawPath = path.join(REPORT_DIR, 'extracted-ui-text.txt');
    fs.writeFileSync(rawPath, allRawText.join('\n\n'));

    // Run cspell if available
    let cspellFindings = '';
    try {
      const cfgFlag = fs.existsSync('config/pm-ux/cspell.json')
        ? '--config config/pm-ux/cspell.json'
        : '--language-id text';
      cspellFindings = execSync(
        `npx cspell ${cfgFlag} --words-only "${rawPath}" 2>/dev/null`,
        { encoding: 'utf8', timeout: 30000 }
      ).trim();
      if (cspellFindings) {
        fs.writeFileSync(path.join(REPORT_DIR, 'cspell-output.txt'), cspellFindings);
      }
    } catch {
      // cspell not available — pattern-based check covers it
    }

    // Console summary
    if (allFindings.length === 0 && !cspellFindings) {
      console.log(`\n✓ [Spell-Check] No typos found across ${pagesScanned} page(s).`);
    } else {
      console.log(`\n[Spell-Check] ${allFindings.length} pattern-match typo(s) across ${pagesScanned} page(s):`);
      for (const f of allFindings) {
        console.log(`  ❌  "${f.typo}" → "${f.suggestion}"  |  [${f.element}] on ${f.page}`);
        console.log(`      Context: "${f.context}"`);
      }
      if (cspellFindings) {
        console.log(`\n  cspell also flagged additional words — see reports/pm-ux/cspell-output.txt`);
      }
    }
  });

  test('extract and spell-check all plugin admin UI text', async ({ page }) => {
    const pluginPages = await discoverPluginPages(page);

    if (pluginPages.length === 0) {
      console.log('[Spell-Check] No plugin admin pages found — set PLUGIN_ADMIN_SLUG env var');
      test.skip();
    }

    for (const pageUrl of pluginPages) {
      try {
        await page.goto(pageUrl, { waitUntil: 'domcontentloaded', timeout: 15000 });
        pagesScanned++;

        const extractions = await extractPageText(page);
        allRawText.push(`=== ${pageUrl} ===`);

        for (const { type, text } of extractions) {
          allRawText.push(`[${type}] ${text}`);
          const typos = scanForTypos(text, pageUrl, type);
          allFindings.push(...typos);
        }
      } catch (err) {
        console.log(`[Spell-Check] Skipped ${pageUrl}: ${err.message}`);
      }
    }

    // Warn threshold: 5+. Does not hard-fail (PM warning only).
    if (allFindings.length >= 5) {
      console.warn(`[Spell-Check] ${allFindings.length} typos detected — address before shipping`);
    }
    expect(true).toBe(true); // always passes; findings go to report
  });
});
