/**
 * Orbit PM — Guided Experience Score
 *
 * Detects whether a plugin guides first-time users or drops them cold.
 * Scans for: setup wizards, tooltips, inline help text, placeholder text,
 * welcome screens, contextual hints, empty-state guidance.
 *
 * Scores 0–10. Compares against what top WP plugins provide.
 * Output: reports/pm-ux/guided-ux-score.json
 *
 * Severity: WARN (not a release blocker — PM decision)
 */

const { test, expect } = require('@playwright/test');
const fs   = require('fs');
const path = require('path');

const WP_BASE    = process.env.WP_TEST_URL || 'http://localhost:8881';
const ADMIN_BASE = `${WP_BASE}/wp-admin`;
const REPORT_DIR = 'reports/pm-ux';

// ── Competitor benchmarks ─────────────────────────────────────────────────────
const COMPETITOR_GUIDANCE = {
  'Yoast SEO':        { score: 8, has: ['wizard', 'inline-help', 'tooltips', 'help-icons', 'empty-state'] },
  'RankMath':         { score: 9, has: ['wizard', 'inline-help', 'tooltips', 'help-icons', 'empty-state', 'welcome-screen'] },
  'Elementor':        { score: 9, has: ['wizard', 'tooltips', 'empty-state', 'welcome-screen', 'placeholder-text'] },
  'WooCommerce':      { score: 8, has: ['wizard', 'inline-help', 'tooltips', 'placeholder-text', 'empty-state'] },
  'WPForms':          { score: 9, has: ['wizard', 'inline-help', 'tooltips', 'help-icons', 'empty-state', 'placeholder-text'] },
  'Gravity Forms':    { score: 8, has: ['inline-help', 'tooltips', 'help-icons', 'placeholder-text'] },
  'MonsterInsights':  { score: 8, has: ['wizard', 'welcome-screen', 'inline-help', 'tooltips'] },
};

// ── Guidance signal detectors ─────────────────────────────────────────────────
const SIGNALS = [
  {
    id: 'wizard',
    label: 'Setup Wizard',
    points: 3,
    selectors: [
      '.setup-wizard', '.wizard', '.onboarding-wizard',
      '[data-step]', '.wizard-step', '.setup-step',
      '.wc-setup', '.rank-math-wizard', '.wpforms-setup',
    ],
    description: 'A step-by-step setup flow for first-time users.',
    example: 'RankMath, WooCommerce, WPForms all use a wizard. Score +3.',
  },
  {
    id: 'welcome_screen',
    label: 'Welcome / Onboarding Screen',
    points: 2,
    selectors: [
      '.welcome-panel', '.onboarding', '.welcome-screen',
      '.getting-started', '[class*="welcome"]', '[class*="onboarding"]',
      '.plugin-welcome', '.intro-screen', '[data-onboarding]',
    ],
    description: 'A dedicated screen shown to new users explaining where to start.',
    example: 'RankMath, MonsterInsights, Elementor show a welcome screen on first activate.',
  },
  {
    id: 'tooltips',
    label: 'Tooltips / Info Icons',
    points: 2,
    selectors: [
      '[data-tip]', '[data-tooltip]', '.tooltip', '.wc-help-tip',
      '.dashicons-editor-help', '.dashicons-info', '.help-icon',
      '[title]:not(a):not(img)', '.tippy', '.tipso', '.qtip',
    ],
    description: 'Contextual tooltips that explain settings inline.',
    example: 'Yoast SEO, WooCommerce, WPForms use "?" icons next to every setting.',
  },
  {
    id: 'inline_help',
    label: 'Inline Help Text',
    points: 2,
    selectors: [
      '.description', '.help-text', '.field-description',
      '.form-help', '.howto', '.setting-description',
      'p.description', 'span.description', '.cmb2-metabox-description',
    ],
    description: 'Text beneath fields explaining what they do.',
    example: 'WooCommerce, Yoast SEO, Gravity Forms have description text under every field.',
  },
  {
    id: 'placeholder_text',
    label: 'Placeholder Text in Inputs',
    points: 1,
    selectors: [
      'input[placeholder]:not([placeholder=""])',
      'textarea[placeholder]:not([placeholder=""])',
    ],
    description: 'Placeholder text showing expected input format (e.g. "https://yourdomain.com").',
    example: 'WPForms, Gravity Forms use placeholder text so users know what to type.',
  },
  {
    id: 'empty_state',
    label: 'Empty-State Guidance',
    points: 2,
    selectors: [
      '.no-items', '.empty-state', '[class*="empty-state"]',
      '.no-results', '.placeholder-content', '.empty-content',
      '.wp-list-table tbody tr.no-items', '.widefat .no-items',
    ],
    description: 'When a list/table is empty, text explains what to do next.',
    example: 'WooCommerce shows "Add your first product" with a button on empty Products page.',
  },
  {
    id: 'help_tab',
    label: 'WP Help Tab',
    points: 1,
    selectors: [
      '#contextual-help-wrap', '.contextual-help-tabs',
      '#screen-meta', '.screen-meta-toggle',
    ],
    description: 'WordPress Help tab registered for the plugin screen.',
    example: 'Yoast SEO registers a Help tab with docs links on every admin screen.',
  },
];

// ── Analyze a single page ─────────────────────────────────────────────────────
async function analyzePage(page, pageUrl) {
  await page.goto(pageUrl, { waitUntil: 'domcontentloaded', timeout: 15000 }).catch(() => {});

  const detected = [];
  const missing  = [];

  for (const signal of SIGNALS) {
    const found = await page.evaluate((selectors) => {
      return selectors.some(sel => {
        try { return document.querySelector(sel) !== null; } catch { return false; }
      });
    }, signal.selectors);

    if (found) {
      detected.push({ id: signal.id, label: signal.label, points: signal.points });
    } else {
      missing.push({
        id: signal.id,
        label: signal.label,
        points: signal.points,
        description: signal.description,
        example: signal.example,
      });
    }
  }

  // Count tooltip density (how many tooltips per page)
  const tooltipCount = await page.evaluate(() => {
    const sels = ['[data-tip]', '[data-tooltip]', '.tooltip', '.dashicons-editor-help', '.help-icon', '[title]:not(a):not(img)'];
    return sels.reduce((n, sel) => n + document.querySelectorAll(sel).length, 0);
  });

  // Count inputs with no placeholder and no adjacent description
  const nakedInputs = await page.evaluate(() => {
    const inputs = Array.from(document.querySelectorAll('input[type="text"], input[type="email"], input[type="url"], textarea'));
    return inputs.filter(inp => {
      const hasPlaceholder  = inp.placeholder && inp.placeholder.trim();
      const nextSibling     = inp.nextElementSibling;
      const hasDescription  = nextSibling && (
        nextSibling.classList.contains('description') ||
        nextSibling.classList.contains('help-text')
      );
      return !hasPlaceholder && !hasDescription;
    }).length;
  });

  return { pageUrl, detected, missing, tooltipCount, nakedInputs };
}

// ── Discover plugin admin pages ───────────────────────────────────────────────
async function discoverPluginPages(page) {
  const adminSlug = process.env.PLUGIN_ADMIN_SLUG || '';
  const pages     = new Set();

  if (adminSlug) pages.add(`${ADMIN_BASE}/admin.php?page=${adminSlug}`);

  await page.goto(ADMIN_BASE, { waitUntil: 'domcontentloaded' }).catch(() => {});
  const links = await page.evaluate((base) => {
    return Array.from(document.querySelectorAll('#adminmenu a'))
      .map(a => a.href)
      .filter(h => h.includes('page=') && h.startsWith(base));
  }, ADMIN_BASE);

  const coreSlugs = new Set(['dashboard', 'posts', 'pages', 'media', 'plugins',
    'themes', 'users', 'tools', 'options-general', 'edit-comments', 'index']);
  for (const link of links) {
    const slug = new URL(link).searchParams.get('page') || '';
    if (slug && !coreSlugs.has(slug)) pages.add(link);
  }

  return [...pages].slice(0, 8);
}

// ── Tests ─────────────────────────────────────────────────────────────────────
test.describe('PM UX — Guided Experience Score', () => {

  test('score guidance depth and compare against competitors', async ({ page }) => {
    const pluginPages = await discoverPluginPages(page);

    if (pluginPages.length === 0) {
      console.log('[Guided UX] No plugin pages found — set PLUGIN_ADMIN_SLUG env var');
      test.skip();
    }

    const pageResults  = [];
    const detectedIds  = new Set();
    let   totalNaked   = 0;

    for (const pageUrl of pluginPages) {
      try {
        const result = await analyzePage(page, pageUrl);
        pageResults.push(result);
        result.detected.forEach(d => detectedIds.add(d.id));
        totalNaked += result.nakedInputs;
      } catch {}
    }

    // Aggregate: which signals appeared on ANY page
    const presentSignals  = SIGNALS.filter(s => detectedIds.has(s.id));
    const missingSignals  = SIGNALS.filter(s => !detectedIds.has(s.id));
    const rawScore        = presentSignals.reduce((n, s) => n + s.points, 0);
    const maxScore        = SIGNALS.reduce((n, s) => n + s.points, 0); // 13
    const guidanceScore   = Math.round((rawScore / maxScore) * 10);

    // Competitor comparison
    const comparisons = Object.entries(COMPETITOR_GUIDANCE).map(([name, bench]) => ({
      competitor: name,
      score: bench.score,
      ahead: bench.score > guidanceScore,
      gap: bench.score - guidanceScore,
    })).sort((a, b) => b.gap - a.gap);

    const competitorAvg  = Math.round(
      Object.values(COMPETITOR_GUIDANCE).reduce((n, b) => n + b.score, 0) /
      Object.keys(COMPETITOR_GUIDANCE).length
    );

    // ── Report ──────────────────────────────────────────────────────────────
    const report = {
      score: guidanceScore,
      maxScore: 10,
      competitorAverage: competitorAvg,
      pagesScanned: pageResults.length,
      presentSignals: presentSignals.map(s => ({ id: s.id, label: s.label, points: s.points })),
      missingSignals: missingSignals.map(s => ({
        id: s.id,
        label: s.label,
        points: s.points,
        description: s.description,
        example: s.example,
      })),
      nakedInputsWithNoHelp: totalNaked,
      competitorComparison: comparisons,
    };

    fs.mkdirSync(REPORT_DIR, { recursive: true });
    fs.writeFileSync(
      path.join(REPORT_DIR, 'guided-ux-score.json'),
      JSON.stringify(report, null, 2)
    );

    // ── Console output ───────────────────────────────────────────────────────
    const bar = '█'.repeat(guidanceScore) + '░'.repeat(10 - guidanceScore);
    console.log(`\n[Guided UX] Score: ${guidanceScore}/10  ${bar}  (Competitor avg: ${competitorAvg}/10)`);

    if (presentSignals.length > 0) {
      console.log(`\n  ✓ Present (${presentSignals.length}):`);
      for (const s of presentSignals) console.log(`     • ${s.label} (+${s.points}pts)`);
    }

    if (missingSignals.length > 0) {
      console.log(`\n  ✗ Missing (${missingSignals.length}) — users are navigating these alone:`);
      for (const s of missingSignals) {
        console.log(`     • ${s.label} (would add +${s.points}pts)`);
        console.log(`       ${s.description}`);
        console.log(`       → ${s.example}`);
      }
    }

    if (totalNaked > 0) {
      console.log(`\n  ⚠ ${totalNaked} input field(s) have no placeholder text AND no description beneath them.`);
      console.log(`    Users have no hint of what to type. Add placeholder="" or <p class="description">...`);
    }

    const ahead = comparisons.filter(c => !c.ahead).length;
    const behind = comparisons.filter(c => c.ahead);
    if (behind.length > 0) {
      console.log(`\n  Competitors with better guidance:`);
      for (const c of behind.slice(0, 3)) {
        console.log(`     • ${c.competitor}: ${c.score}/10  (you are ${c.gap} point(s) behind)`);
      }
    }

    if (guidanceScore >= competitorAvg) {
      console.log(`\n  ✓ At or above competitor average (${competitorAvg}/10) — good standing.`);
    } else {
      console.log(`\n  ⚠ Below competitor average. Users of ${behind[0]?.competitor || 'top competitors'} get more guidance.`);
    }

    expect(true).toBe(true); // never hard-fails; PM calls the shot
  });
});
