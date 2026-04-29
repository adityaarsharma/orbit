---
name: orbit-competitor-compare
description: Side-by-side comparison of your WordPress plugin vs competitor plugins from wordpress.org. Auto-downloads competitor zips, analyses each on version / installs / rating / bundle weight / PHPCS errors / security patterns / block.json adoption, and produces a markdown comparison table. Use when the user says "competitor analysis", "vs Essential Addons / Premium Addons / Yoast / RankMath", "where are we behind", "competitive moat".
---

# 🪐 orbit-competitor-compare — Competitor analysis from wordpress.org

PM-driven view: are we ahead of the competition or falling behind? Pulls live data from wordpress.org for evidence-based answers.

---

## Quick start

```bash
# Uses competitors from qa.config.json
bash ~/Claude/orbit/scripts/competitor-compare.sh

# Or explicit
bash ~/Claude/orbit/scripts/competitor-compare.sh \
  --competitors "essential-addons-for-elementor-free,premium-addons-for-elementor"
```

Output: `reports/competitor-<timestamp>.md`.

---

## What it pulls per competitor

For each WP.org slug:

| Metric | Source |
|---|---|
| Version | WP.org API |
| Active installs | WP.org plugin page |
| Rating (5★ scale + count) | WP.org plugin page |
| Last updated | WP.org plugin page |
| Tested up to (WP version) | Plugin header in zip |
| Requires PHP | Plugin header |
| JS bundle size | Sum of `assets/js/*.js` in zip |
| CSS bundle size | Sum of `assets/css/*.css` in zip |
| PHPCS errors | Run phpcs on the zip |
| Security patterns | Grep for `wp_nonce`, `current_user_can`, `wp_verify_nonce`, escaping count |
| block.json adoption | Count of `block.json` files in zip |
| Translatable strings | Count of `__()`, `_e()`, etc. |
| HPOS declared (WC plugins) | Plugin header check |
| GDPR hooks | `wp_privacy_personal_data_*` filter usage |

---

## Example output

```markdown
# Competitor Analysis — Elementor Addons · 2026-04-29

## Plugins compared
| Plugin | Version | Installs | Rating | Last update |
|---|---|---|---|---|
| **The Plus Addons (yours)** | 2.4.0 | 50K+ | 4.8 (320) | 2 days ago |
| Essential Addons (free) | 5.12.1 | 1M+ | 4.7 (1,800) | 1 week ago |
| Premium Addons | 4.10.50 | 600K+ | 4.7 (1,200) | 5 days ago |
| Happy Elementor Addons | 3.9.7 | 300K+ | 4.8 (900) | 2 weeks ago |

## Bundle weight
| Plugin | JS | CSS | Total |
|---|---|---|---|
| **You** | 287 KB | 51 KB | 338 KB |
| Essential | 412 KB | 87 KB | 499 KB |
| Premium | 510 KB | 102 KB | 612 KB |
| Happy | 220 KB | 38 KB | 258 KB |  ← leaner

You're 30% lighter than Essential, 80% lighter than Premium. Happy is 24% lighter than you.

## PHPCS errors (WPCS strict)
| Plugin | Errors | Warnings |
|---|---|---|
| **You** | 3 | 8 |
| Essential | 47 | 102 |
| Premium | 89 | 234 |
| Happy | 12 | 28 |

You're cleanest. Major positioning point.

## Security signals
| Plugin | nonce_field | current_user_can | wp_verify_nonce | esc_attr/html count |
|---|---|---|---|---|
| **You** | 18 | 24 | 18 | 142 |
| Essential | 8 | 12 | 8 | 89 |
| Premium | 4 | 6 | 4 | 67 |
| Happy | 22 | 28 | 22 | 178 |

Premium has 4× fewer nonce checks than you — competitive risk for them, advantage for you.

## block.json (Gutenberg adoption)
| Plugin | Block count |
|---|---|
| **You** | 0 |       ← gap
| Essential | 8 |
| Premium | 12 |
| Happy | 4 |

You don't ship Gutenberg blocks. Competitors do. **Strategic gap.**

## What this tells your roadmap
Wins:
  ✓ Lightest bundle (vs Essential, Premium)
  ✓ Cleanest PHPCS code
  ✓ Strongest security signal density

Gaps:
  ❌ No Gutenberg blocks — blocks editor users see your competitors first
  ⚠ Bundle still 24% heavier than Happy — review for tree-shake opportunities
  ⚠ Update cadence: 2 days vs Essential's 1 week — be careful of release fatigue

Strategic moves:
  1. Ship 5 Gutenberg blocks in v2.5 → match Happy's coverage
  2. Tree-shake the JS bundle by 20% → leapfrog Happy
  3. Highlight "lightest + most-secure" in landing page copy
```

---

## Configure competitors in qa.config.json

```json
{
  "competitors": [
    "essential-addons-for-elementor-free",
    "premium-addons-for-elementor",
    "happy-elementor-addons",
    "elementskit-lite"
  ],
  "competitorDownloadDir": "plugins/free"
}
```

The script auto-downloads each into `plugins/free/<slug>/<version>/`. Cache is reused if recent (< 24h old).

---

## Pro / paid competitors

WP.org doesn't host paid plugins. Drop their zips manually:

```bash
# Drop: plugins/pro/competitor-name-pro.zip
bash scripts/competitor-compare.sh --pro plugins/pro/competitor-pro.zip
```

The same metrics get extracted from the paid zip. License compliance — only do this with zips you legitimately purchased.

---

## Pair with `/orbit-pm-ux-audit`

`/orbit-competitor-compare` measures **structural** vs competitors (code, weight, security signals).
`/orbit-pm-ux-audit` measures **UX terminology** vs competitors (label benchmarks, guided UX score).
Run both before any positioning conversation — together they tell the full story.

---

## Cron-friendly: monthly competitor pulse

```cron
# 1st of every month at 9am
0 9 1 * * cd ~/plugins/my-plugin && \
  bash ~/Claude/orbit/scripts/competitor-compare.sh > /tmp/competitor-$(date +\%Y\%m).md
```

Diff month-over-month — surface when a competitor ships a major rewrite (sudden bundle weight change, version jump) so you can react.

---

## Hard rules

- ❌ Never republish or redistribute competitor code. This skill reads zips locally, produces metrics, deletes the zip.
- ❌ Never include competitor screenshots or proprietary content in your reports.
- ✅ Use this for evidence-based roadmap decisions, not marketing copy attacking specific competitors.
