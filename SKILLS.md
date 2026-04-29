# Orbit — Skills Reference

> **45 specialised `/orbit-*` Claude Code skills** for WordPress plugin QA.
> One master dispatcher + 44 deep-dive skills. Type `/orbit` to browse the menu.

**Repo:** https://github.com/adityaarsharma/orbit
**Author:** [Aditya Sharma](https://github.com/adityaarsharma) · POSIMYTH Innovation
**Roadmap (60+ more):** [SKILL-ROADMAP.md](SKILL-ROADMAP.md)
**How to add a new skill:** [skills/orbit-skill-add/SKILL.md](skills/orbit-skill-add/SKILL.md)

---

## How to install

```bash
# One-line install (clone + symlink + power tools)
curl -fsSL https://raw.githubusercontent.com/adityaarsharma/orbit/main/install.sh | bash

# Or, from a clone
git clone https://github.com/adityaarsharma/orbit ~/Claude/orbit
cd ~/Claude/orbit && bash install.sh
```

After install, restart Claude Code (`Cmd+Q` and reopen on macOS) so the slash commands appear in the palette.

---

## Quick reference — every skill in one table

| # | Skill | Purpose | Trigger phrases |
|---|---|---|---|
| 1 | `/orbit` | Master dispatcher / role-based menu | "orbit", "orbit help", "what does orbit do" |
| 2 | `/orbit-setup` | Guided onboarding wizard | "set up orbit", "first time", "new plugin" |
| 3 | `/orbit-update` | Pull latest Orbit (zero questions) | "update orbit", "upgrade orbit", "refresh orbit" |
| 4 | `/orbit-install` | Install all power tools | "install power tools", "missing tool" |
| 5 | `/orbit-docker-site` | Spin up wp-env / wp-now test site | "create test site", "Docker WP", "wp-env" |
| 6 | `/orbit-pre-commit` | Install pre-commit hook | "block bad commits", "git hook" |
| 7 | `/orbit-gauntlet` | Full 11-step audit pipeline | "run gauntlet", "full QA", "audit my plugin" |
| 8 | `/orbit-release-gate` | Day-of-release sequence | "ship it", "release this", "tag v2.0" |
| 9 | `/orbit-multi-plugin` | Batch-test multiple plugins in parallel | "test all plugins", "batch QA" |
| 10 | `/orbit-wp-standards` | WP coding standards review | "PHPCS", "WPCS", "nonces / escaping" |
| 11 | `/orbit-wp-security` | XSS / CSRF / SQLi audit | "security audit", "find vulns" |
| 12 | `/orbit-wp-performance` | Hook weight + N+1 + transient misuse | "performance audit", "find slow hooks" |
| 13 | `/orbit-wp-database` | $wpdb / autoload / indexes | "DB review", "$wpdb audit" |
| 14 | `/orbit-scaffold-tests` | Read code → 70+ QA scenarios | "generate tests", "scaffold tests" |
| 15 | `/orbit-code-quality` | Dead code + complexity + AI hallucinations | "code quality", "AI-gen review" |
| 16 | `/orbit-accessibility` | WCAG 2.2 AA on admin + frontend | "a11y", "WCAG", "axe-core" |
| 17 | `/orbit-i18n` | Translation strings + POT + RTL | "i18n", "translation", "POT" |
| 18 | `/orbit-pm-ux-audit` | Spell + guidance score + label benchmark | "PM UX", "spell check labels" |
| 19 | `/orbit-compat-matrix` | PHP × WP version matrix | "PHP 7.4 vs 8.x", "WP 6.5 compat" |
| 20 | `/orbit-cve-check` | Live CVE feed + ownership-transfer | "CVE check", "weekly security scan" |
| 21 | `/orbit-playwright` | Setup / write / run / debug E2E | "Playwright", "E2E", "trace viewer" |
| 22 | `/orbit-visual-regression` | Pixel-diff + responsive + admin colours | "visual regression", "pixel diff" |
| 23 | `/orbit-user-flow` | Click depth + onboarding + analytics events | "user flow", "click depth" |
| 24 | `/orbit-conflict-matrix` | Test against top 20 WP plugins | "plugin conflicts", "vs Yoast" |
| 25 | `/orbit-lighthouse` | Core Web Vitals scoring | "Lighthouse", "LCP / CLS / TBT" |
| 26 | `/orbit-editor-perf` | Elementor / Gutenberg editor timing | "Elementor slow", "Gutenberg lag" |
| 27 | `/orbit-db-profile` | Query count + N+1 + autoload bloat | "Query Monitor", "N+1" |
| 28 | `/orbit-bundle-analysis` | JS / CSS bundle weight + dead CSS | "bundle size", "PurgeCSS" |
| 29 | `/orbit-uat-compare` | Plugin A vs Plugin B (HTML report) | "side-by-side", "UAT report" |
| 30 | `/orbit-version-compare` | Old version vs new version diff | "v1 vs v2", "diff zips" |
| 31 | `/orbit-competitor-compare` | Vs WP.org competitors | "competitor analysis" |
| 32 | `/orbit-changelog-test` | Changelog → targeted test plan | "test the changelog" |
| 33 | `/orbit-release-meta` | Plugin header + readme.txt + parity | "validate plugin header" |
| 34 | `/orbit-zip-hygiene` | Validate the release zip | "validate zip", "before SVN" |
| 35 | `/orbit-reports` | Generate master HTML report | "make HTML report" |
| 36 | `/orbit-multisite` | Multisite / network compatibility | "multisite", "network activation" |
| 37 | `/orbit-uninstall-test` | uninstall.php cleanup verification | "uninstall test", "remove all data" |
| 38 | `/orbit-rest-fuzzer` | REST endpoint fuzzing | "REST fuzzer", "test REST permissions" |
| 39 | `/orbit-ajax-fuzzer` | admin-ajax.php fuzzing | "AJAX fuzzer", "wp_ajax security" |
| 40 | `/orbit-gdpr` | Personal data export + erase hooks | "GDPR", "right to be forgotten" |
| 41 | `/orbit-block-json-validate` | Gutenberg block.json schema | "block.json validate" |
| 42 | `/orbit-plugin-check` | Official WP.org plugin-check | "WP.org submission", "plugin-check" |
| 43 | `/orbit-cron-audit` | wp_schedule_event hygiene | "cron audit", "WP-Cron" |
| 44 | `/orbit-cache-compat` | Object + page cache compatibility | "Redis", "WP Rocket compat" |
| 45 | `/orbit-skill-add` | Meta-skill — generate new orbit-* skills | "add a skill", "create new orbit skill" |

---

## By category

### 🛠 Setup & Environment
| Skill | What it does |
|---|---|
| `/orbit-setup` | Guided wizard — installs everything, configures first plugin, runs first audit |
| `/orbit-docker-site` | wp-env (Docker) or wp-now setup; troubleshooting "site not running" |
| `/orbit-install` | One-shot installer for PHPCS, Playwright, Lighthouse, WP-CLI, etc. |
| `/orbit-pre-commit` | Git pre-commit hook — blocks `var_dump`, `console.log DEBUG`, etc. (<10s) |
| `/orbit-update` | Pull latest Orbit + refresh skill symlinks |

### 🏃 Run the Pipeline
| Skill | What it does |
|---|---|
| `/orbit-gauntlet` | Full 11-step audit (modes: quick / full / release) |
| `/orbit-release-gate` | Day-of-release sequence — preflight, metadata, gauntlet, evidence pack |
| `/orbit-multi-plugin` | Batch-test multiple plugins in parallel with CPU throttling |

### 🔍 Code Audits
| Skill | What it does |
|---|---|
| `/orbit-wp-standards` | Naming, escaping, nonces, capability checks, i18n, hook patterns |
| `/orbit-wp-security` | XSS / CSRF / SQLi / auth bypass / path traversal in source code |
| `/orbit-wp-performance` | Hook weight, N+1 DB calls, blocking assets, transient misuse |
| `/orbit-wp-database` | $wpdb, autoload bloat, missing indexes, uninstall cleanup |
| `/orbit-scaffold-tests` | Read code → 70+ business-logic test scenarios |
| `/orbit-code-quality` | Dead code, complexity, AI-hallucination risks |
| `/orbit-accessibility` | WCAG 2.2 AA on admin UI + frontend output |
| `/orbit-i18n` | Translation strings, text domain, POT freshness, RTL |
| `/orbit-pm-ux-audit` | Spell-check + guided UX score + label benchmark |
| `/orbit-compat-matrix` | PHP 7.4 / 8.1 / 8.3 × WP 6.3 / 6.5 / latest matrix |
| `/orbit-cve-check` | Live CVE feed correlation + ownership-transfer detection |

### 🌐 Browser Testing (Playwright)
| Skill | What it does |
|---|---|
| `/orbit-playwright` | First-time setup, write specs, run, debug, trace viewer |
| `/orbit-visual-regression` | Pixel-diff snapshots + responsive (375/768/1440) + admin colours |
| `/orbit-user-flow` | Click depth, onboarding detection, analytics-event verification |
| `/orbit-conflict-matrix` | Test against Yoast, RankMath, WC, Elementor + 16 more |

### ⚡ Performance Deep-Dive
| Skill | What it does |
|---|---|
| `/orbit-lighthouse` | Core Web Vitals (LCP / FCP / TBT / CLS / TTI) |
| `/orbit-editor-perf` | Elementor / Gutenberg editor ready time + widget insert timing |
| `/orbit-db-profile` | Query count per page, slow queries, N+1, autoload bloat |
| `/orbit-bundle-analysis` | JS / CSS bundle weight + source-map-explorer + PurgeCSS |

### 🆚 Comparison
| Skill | What it does |
|---|---|
| `/orbit-uat-compare` | Plugin A vs Plugin B HTML report with paired screenshots + videos |
| `/orbit-version-compare` | v(N-1).zip vs v(N).zip — function / hook / asset diffs |
| `/orbit-competitor-compare` | Vs WP.org competitors (version, installs, code quality, bundle) |
| `/orbit-changelog-test` | Map every changelog entry → targeted test or audit |

### 📦 Release Metadata
| Skill | What it does |
|---|---|
| `/orbit-release-meta` | Plugin header, readme.txt, version parity, license, POT freshness |
| `/orbit-zip-hygiene` | Validate the release zip — no .git, no source maps, no dev deps |
| `/orbit-plugin-check` | Run wordpress.org's official plugin-check tool |
| `/orbit-block-json-validate` | Every block.json against current WP schema |
| `/orbit-reports` | Generate master HTML index across every report |

### 🔬 WordPress-Specific Edge Cases
| Skill | What it does |
|---|---|
| `/orbit-multisite` | Network activation, super-admin caps, switch_to_blog safety |
| `/orbit-uninstall-test` | uninstall.php removes options / postmeta / tables / crons |
| `/orbit-rest-fuzzer` | Auto-discover register_rest_route + fuzz |
| `/orbit-ajax-fuzzer` | wp_ajax_* / wp_ajax_nopriv_* fuzzing |
| `/orbit-gdpr` | wp_privacy_personal_data_exporters + erasers |
| `/orbit-cron-audit` | wp_schedule_event hygiene + zombie cron detection |
| `/orbit-cache-compat` | Object cache (Redis) + page cache (WP Rocket) |

### 🧬 Meta
| Skill | What it does |
|---|---|
| `/orbit-skill-add` | Generate new `/orbit-*` skills following the established pattern |

---

## Mandatory skills for `/orbit-gauntlet --mode full`

These run automatically as Step 11 of the gauntlet (6 parallel AI audits):

1. `/orbit-wp-standards`
2. `/orbit-wp-security`
3. `/orbit-wp-performance`
4. `/orbit-wp-database`
5. `/orbit-accessibility`
6. `/orbit-code-quality`

---

## Severity model (applied to all skill output)

| Level | Action before release |
|---|---|
| **Critical** | Block release. Fix immediately. |
| **High** | Block release. Fix in this PR. |
| **Medium** | Fix if under 30 min. Otherwise log and defer. |
| **Low / Info** | Log in tech debt. Defer. |

---

## How to add a new skill

```bash
# In Claude Code:
/orbit-skill-add
```

Or read the manual: [skills/orbit-skill-add/SKILL.md](skills/orbit-skill-add/SKILL.md).

Naming pattern: `/orbit-<thing>` (specific tool), `/orbit-<thing>-test` (behavioural), `/orbit-<thing>-fuzzer` (active probe), `/orbit-<thing>-compat` (compatibility), `/orbit-<thing>-validate` (schema), `/orbit-<thing>-audit` (read-only review).

Roadmap of 60+ candidate skills: [SKILL-ROADMAP.md](SKILL-ROADMAP.md).

---

## Output rules

Every skill writes to `reports/` — never terminal-only.

| Skill type | Output | Location |
|---|---|---|
| Code audits | Markdown with severity table | `reports/skill-audits/<skill>.md` |
| Playwright | HTML reporter | `reports/playwright-html/index.html` |
| Gauntlet | Master markdown | `reports/qa-report-<timestamp>.md` |
| UAT compare | HTML with screenshots + videos | `reports/uat-report-<timestamp>.html` |
| Lighthouse | JSON + summary | `reports/lighthouse/lh-<timestamp>.json` |
| DB profile | Text | `reports/db-profile-<timestamp>.txt` |
| PM UX | HTML | `reports/pm-ux/pm-ux-report-<timestamp>.html` |
| Master index | HTML linking to all of the above | `reports/index.html` |

View reports after any run:
```bash
python3 scripts/generate-reports-index.py
open reports/index.html
```

---

## Built by

**[Aditya Sharma](https://adityaarsharma.com)** · POSIMYTH Innovation
github.com/adityaarsharma/orbit
