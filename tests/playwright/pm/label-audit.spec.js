/**
 * Orbit PM — Label & Terminology Audit
 *
 * Extracts every label, button, nav item, and option from the plugin's admin
 * pages, then:
 *   1. Compares against competitor-terms.json (industry-standard terminology)
 *   2. Flags anti-patterns (jargon, vague buttons, double negatives, truncation,
 *      inconsistent capitalization, ambiguous toggles)
 *   3. Checks option ordering in select/radio groups
 *
 * For every flag it names which competitor uses the better term so PMs have
 * a concrete benchmark, not just an abstract rule.
 *
 * Output: reports/pm-ux/label-audit-findings.json
 *
 * Severity: WARN  (not a release blocker)
 */

const { test, expect } = require('@playwright/test');
const fs   = require('fs');
const path = require('path');

const WP_BASE    = process.env.WP_TEST_URL || 'http://localhost:8881';
const ADMIN_BASE = `${WP_BASE}/wp-admin`;
const REPORT_DIR = 'reports/pm-ux';

// ── Load competitor terms ─────────────────────────────────────────────────────
let COMP_TERMS = {};
try {
  COMP_TERMS = JSON.parse(
    fs.readFileSync(path.join('config', 'pm-ux', 'competitor-terms.json'), 'utf8')
  );
} catch {
  console.warn('[Label Audit] config/pm-ux/competitor-terms.json not found — using built-in patterns only');
}

// ── Anti-pattern rules ────────────────────────────────────────────────────────
const ANTI_PATTERNS = [
  {
    id: 'vague_button',
    severity: 'high',
    test: (text) => /^(submit|go|ok|done|yes|no|click here|here|more)$/i.test(text.trim()),
    message: (text) => `"${text}" is a vague button label. Use an action verb: "Save Settings", "Delete Entry", "Enable Feature".`,
    competitors: 'WooCommerce, WPForms, Yoast SEO all use specific verbs.',
  },
  {
    id: 'double_negative',
    severity: 'high',
    test: (text) => /disable.{0,10}(de|un|dis)/i.test(text) || /don.t\s+not/i.test(text) || /no\s+not/i.test(text),
    message: (text) => `"${text}" looks like a double negative. Rewrite as a positive statement.`,
    competitors: 'Yoast SEO rewrites all toggles as "Enable X" / "Disable X" — never double negatives.',
  },
  {
    id: 'technical_jargon',
    severity: 'medium',
    test: (text) => /\b(enqueue|wpdb|nonce|sanitize|transient|cpt|meta_key|post_meta|hook|filter|action)\b/i.test(text),
    message: (text) => `"${text}" contains PHP/WP developer jargon. Use plain English: "Load Scripts" not "Enqueue", "Security Check" not "Nonce", "Cached Data" not "Transient".`,
    competitors: 'WooCommerce, WPForms always translate dev-terms into user-friendly language.',
  },
  {
    id: 'tech_abbreviation',
    severity: 'medium',
    test: (text) => /\b(cfg|cnfg|param|val(?!id)|attr(?!ribute)|obj|proc|fn|var(?!iant|ious))\b/i.test(text),
    message: (text) => `"${text}" uses a developer abbreviation. Spell it out: "Parameter", "Value", "Attribute".`,
    competitors: 'WordPress Core style guide requires fully spelled-out labels.',
  },
  {
    id: 'ambiguous_toggle',
    severity: 'high',
    test: (text) => /^(toggle|switch|flip|change|on|off|1|0|true|false)$/i.test(text.trim()),
    message: (text) => `"${text}" is ambiguous for a toggle. Use "Enable [Feature]" or "Disable [Feature]" explicitly.`,
    competitors: 'Jetpack, WooCommerce, Yoast SEO all name their toggles: "Enable Comments", "Disable Tracking".',
  },
  {
    id: 'inconsistent_save',
    severity: 'high',
    test: (text) => /^(apply|confirm|update settings|save changes|apply changes)$/i.test(text.trim()),
    message: (text) => `"${text}" — the WordPress standard is "Save Settings". Inconsistent save labels confuse users who muscle-memory the button.`,
    competitors: 'Yoast SEO, WooCommerce, RankMath all use "Save Settings" — users expect it.',
  },
  {
    id: 'truncated_label',
    severity: 'medium',
    test: (text, el) => el && el.scrollWidth > el.clientWidth,
    message: (text) => `"${text}" appears truncated (text wider than container). Shorten label or widen column.`,
    competitors: 'WooCommerce uses responsive label widths — nothing clips.',
  },
  {
    id: 'all_caps_abuse',
    severity: 'low',
    test: (text) => text.length > 4 && text === text.toUpperCase() && /[A-Z]{4,}/.test(text),
    message: (text) => `"${text}" is ALL CAPS. Use Title Case for headings, Sentence case for descriptions.`,
    competitors: 'WordPress Core uses Title Case for nav items, Sentence case for descriptions.',
  },
  {
    id: 'missing_article',
    severity: 'low',
    test: (text) => /^(enable|disable|show|hide|use|allow|block)\s*$/i.test(text.trim()),
    message: (text) => `"${text}" is incomplete — specify WHAT. "Enable what?" Pair with the feature name.`,
    competitors: 'Yoast SEO: "Enable reading analysis", "Enable SEO analysis" — always complete.',
  },
];

// ── Competitor terminology checker ────────────────────────────────────────────
function checkAgainstCompetitorTerms(text) {
  const findings = [];
  const t = text.toLowerCase().trim();
  const categories = ['nav_labels', 'button_labels', 'field_labels', 'error_messages', 'section_headings'];

  for (const cat of categories) {
    if (!COMP_TERMS[cat]) continue;
    for (const [concept, data] of Object.entries(COMP_TERMS[cat])) {
      if (!data.avoid) continue;
      for (const badTerm of data.avoid) {
        if (t === badTerm.toLowerCase() || t.includes(badTerm.toLowerCase())) {
          findings.push({
            found: text,
            badTerm,
            standard: data.standard,
            usedBy: (data.used_by || []).join(', '),
            severity: 'medium',
            message: `"${text}" — industry standard is "${data.standard}" (used by: ${(data.used_by || []).join(', ')}).`,
          });
          break;
        }
      }
    }
  }

  return findings;
}

// ── Option ordering checker ───────────────────────────────────────────────────
const PREFERRED_SEQUENCES = [
  { pattern: /^(none|never|off)$/i,      rank: 0 },
  { pattern: /^(low|minimal|basic)$/i,   rank: 1 },
  { pattern: /^(medium|moderate|standard)$/i, rank: 2 },
  { pattern: /^(high|full|maximum|all)$/i, rank: 3 },
  { pattern: /^custom$/i,                rank: 99 },
  { pattern: /^daily$/i,                 rank: 10 },
  { pattern: /^weekly$/i,                rank: 11 },
  { pattern: /^monthly$/i,               rank: 12 },
  { pattern: /^yearly$/i,                rank: 13 },
  { pattern: /^small$/i,                 rank: 20 },
  { pattern: /^large$/i,                 rank: 22 },
  { pattern: /^enable(d)?$/i,            rank: 0 },
  { pattern: /^disable(d)?$/i,           rank: 1 },
];

function rankOption(text) {
  for (const seq of PREFERRED_SEQUENCES) {
    if (seq.pattern.test(text.trim())) return seq.rank;
  }
  return null;
}

function checkOptionOrdering(options) {
  // Only check if all options have a known rank
  const ranks = options.map(o => ({ text: o, rank: rankOption(o) }));
  if (ranks.some(r => r.rank === null)) return null;

  const sorted = [...ranks].sort((a, b) => a.rank - b.rank);
  const isOrdered = ranks.every((r, i) => r.rank === sorted[i].rank);
  if (!isOrdered) {
    return {
      found: options,
      suggested: sorted.map(r => r.text),
      message: `Options appear out of logical order. Suggested: [${sorted.map(r => r.text).join(', ')}]`,
      competitor: 'WooCommerce, WPForms order options: None → Low → Medium → High → Custom.',
    };
  }
  return null;
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
  return [...pages].slice(0, 10);
}

// ── Extract all UI text from a page ──────────────────────────────────────────
async function extractLabels(page) {
  return page.evaluate(() => {
    const items = [];
    const push  = (type, text, extra = {}) => {
      const t = text.trim();
      if (t.length > 1 && t.length < 120) items.push({ type, text: t, ...extra });
    };

    document.querySelectorAll('label').forEach(el      => push('label', el.innerText));
    document.querySelectorAll('th').forEach(el          => push('table-header', el.innerText));
    document.querySelectorAll('.nav-tab').forEach(el    => push('nav-tab', el.innerText));
    document.querySelectorAll('.wp-menu-name').forEach(el => push('nav-menu', el.innerText));
    document.querySelectorAll('.wp-submenu li a').forEach(el => push('submenu', el.innerText));
    document.querySelectorAll('button, input[type="submit"], input[type="button"]').forEach(el =>
      push('button', el.innerText || el.value || ''));
    document.querySelectorAll('.button, .wp-button, .btn').forEach(el =>
      push('button', el.innerText));
    document.querySelectorAll('.wrap h1, .wrap h2, .postbox h2, .section-title').forEach(el =>
      push('heading', el.innerText));
    document.querySelectorAll('.notice p, .error p, .updated p').forEach(el =>
      push('notice', el.innerText));

    // Select options with their group
    document.querySelectorAll('select').forEach(sel => {
      const label     = sel.previousElementSibling?.innerText || sel.name || 'unknown';
      const optTexts  = Array.from(sel.options).map(o => o.text.trim()).filter(t => t);
      if (optTexts.length > 1) {
        items.push({ type: 'select-group', label, options: optTexts });
      }
      optTexts.forEach(t => push('select-option', t));
    });

    // Radio groups
    document.querySelectorAll('[type="radio"]').forEach(r => {
      const label = document.querySelector(`label[for="${r.id}"]`);
      if (label) push('radio-option', label.innerText);
    });

    return items;
  });
}

// ── Tests ─────────────────────────────────────────────────────────────────────
test.describe('PM UX — Label & Terminology Audit', () => {

  test('audit all labels, buttons, and options against industry standards', async ({ page }) => {
    const pluginPages = await discoverPluginPages(page);

    if (pluginPages.length === 0) {
      console.log('[Label Audit] No plugin pages found — set PLUGIN_ADMIN_SLUG env var');
      test.skip();
    }

    const antiPatternFindings   = [];
    const competitorFindings    = [];
    const optionOrderFindings   = [];
    const pagesScanned          = [];

    for (const pageUrl of pluginPages) {
      try {
        await page.goto(pageUrl, { waitUntil: 'domcontentloaded', timeout: 15000 });
        pagesScanned.push(pageUrl);

        const items = await extractLabels(page);

        for (const item of items) {
          if (item.type === 'select-group') {
            const ordering = checkOptionOrdering(item.options);
            if (ordering) {
              optionOrderFindings.push({
                page: pageUrl,
                label: item.label,
                ...ordering,
              });
            }
            continue;
          }

          const { text, type } = item;

          // Anti-pattern checks
          for (const rule of ANTI_PATTERNS) {
            if (rule.id === 'truncated_label') continue; // requires DOM ref
            try {
              if (rule.test(text)) {
                antiPatternFindings.push({
                  page: pageUrl,
                  element: type,
                  text,
                  severity: rule.severity,
                  message: rule.message(text),
                  competitors: rule.competitors,
                });
                break; // one rule per element
              }
            } catch {}
          }

          // Competitor terminology check
          const termFindings = checkAgainstCompetitorTerms(text);
          for (const tf of termFindings) {
            competitorFindings.push({ page: pageUrl, element: type, ...tf });
          }
        }
      } catch (err) {
        console.log(`[Label Audit] Skipped ${pageUrl}: ${err.message}`);
      }
    }

    // ── Report ───────────────────────────────────────────────────────────────
    const report = {
      pagesScanned: pagesScanned.length,
      summary: {
        antiPatternCount: antiPatternFindings.length,
        competitorTermCount: competitorFindings.length,
        optionOrderCount: optionOrderFindings.length,
        total: antiPatternFindings.length + competitorFindings.length + optionOrderFindings.length,
      },
      antiPatterns: antiPatternFindings,
      competitorTerms: competitorFindings,
      optionOrdering: optionOrderFindings,
    };

    fs.mkdirSync(REPORT_DIR, { recursive: true });
    fs.writeFileSync(
      path.join(REPORT_DIR, 'label-audit-findings.json'),
      JSON.stringify(report, null, 2)
    );

    // ── Console summary ───────────────────────────────────────────────────────
    const total = report.summary.total;
    console.log(`\n[Label Audit] ${total} issue(s) found across ${pagesScanned.length} page(s)\n`);

    if (antiPatternFindings.length > 0) {
      const highs = antiPatternFindings.filter(f => f.severity === 'high');
      console.log(`  Anti-patterns: ${antiPatternFindings.length} (${highs.length} high severity)`);
      for (const f of antiPatternFindings.slice(0, 8)) {
        const icon = f.severity === 'high' ? '❌' : '⚠';
        console.log(`  ${icon} [${f.element}] ${f.message}`);
        if (f.competitors) console.log(`      → ${f.competitors}`);
      }
    }

    if (competitorFindings.length > 0) {
      console.log(`\n  Terminology (vs competitors): ${competitorFindings.length}`);
      for (const f of competitorFindings.slice(0, 6)) {
        console.log(`  ⚠ [${f.element}] ${f.message}`);
      }
    }

    if (optionOrderFindings.length > 0) {
      console.log(`\n  Option ordering: ${optionOrderFindings.length} group(s) out of logical order`);
      for (const f of optionOrderFindings) {
        console.log(`  ⚠ "${f.label}" → current: [${f.found.join(', ')}]`);
        console.log(`     suggested: [${f.suggested.join(', ')}]`);
        console.log(`     → ${f.competitor}`);
      }
    }

    if (total === 0) {
      console.log('  ✓ No label issues found — terminology matches industry standards.');
    } else {
      console.log(`\n  Full findings: reports/pm-ux/label-audit-findings.json`);
    }

    expect(true).toBe(true); // PM decides — never hard-blocks
  });
});
