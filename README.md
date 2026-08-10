<div align="center">

# 🪐 Orbit

### **Complete UAT for WordPress Plugins — Now Agentic**

*A Claude Code plugin · **116 runtime-evergreen `/orbit-*` skills** · **10-agent QA team** · CTO → PM → Dev → QA → Security → Release*

**v3.0 — Orbit Agentic.** Orbit is no longer just a skill suite. It's a 10-agent QA team connected to a shared brain (`brain`). CTO's brain is the team's constitution — every agent reads it first. Approved patterns get remembered. Cold starts become warm starts.

**The one-command audit:**

```bash
/orbit-do-it ~/plugins/my-plugin
```

Auto-detects plugin type. Picks the right pipeline. Runs core audits + UAT + perf + security + compat in parallel. Writes a one-page TL;DR + a master HTML report. Walks away. Comes back to a verdict.

<br />

![PHP](https://img.shields.io/badge/PHP-7.4%20→%208.5-777BB4?style=for-the-badge&logo=php&logoColor=white)
![WordPress](https://img.shields.io/badge/WordPress-6.3%20→%207.0-21759B?style=for-the-badge&logo=wordpress&logoColor=white)
![Playwright](https://img.shields.io/badge/Playwright-E2E-2EAD33?style=for-the-badge&logo=playwright&logoColor=white)
![Stagehand](https://img.shields.io/badge/Stagehand-AI%20UAT-7C3AED?style=for-the-badge)
![Lighthouse](https://img.shields.io/badge/Lighthouse-Performance-F44B21?style=for-the-badge&logo=lighthouse&logoColor=white)
![Claude Code](https://img.shields.io/badge/Claude%20Code-116%20Skills-CC785C?style=for-the-badge)
![Agentic](https://img.shields.io/badge/v3.0-Orbit%20Agentic-6366F1?style=for-the-badge)

<br />

**👨‍💻 Dev** · zero-regression releases &nbsp;·&nbsp; **🧪 QA** · structured coverage + auto-generated specs &nbsp;·&nbsp; **📊 PM** · flow maps + RICE backlog + release notes &nbsp;·&nbsp; **🎨 Designer** · visual diffs + token audits + dark mode &nbsp;·&nbsp; **🚀 Release Ops** · WP.org gates + EU CRA compliance &nbsp;·&nbsp; **👤 End User** · real browser, real flows, AI-resolved tests

📖 **[VISION.md](VISION.md)** &nbsp;·&nbsp; 🚀 **[Skills Reference](SKILLS.md)** &nbsp;·&nbsp; 🌱 **[Runtime-Evergreen Pattern](EVERGREEN.md)** &nbsp;·&nbsp; 🛡️ **[Evergreen Security](docs/21-evergreen-security.md)** &nbsp;·&nbsp; 🤖 **[Orbit Agentic](docs/BLUEPRINT-ORBIT-V3.md)** &nbsp;·&nbsp; 📓 **[Changelog](CHANGELOG.md)**

[Install in 60s](#install-in-60-seconds) · [Orbit Agentic — v3.0](#orbit-agentic--v30) · [The brainless agent](#the-brainless-team-agent) · [The 116 skills](#the-116-orbit-skills) · [Runtime-evergreen, explained](#runtime-evergreen-the-philosophy) · [Role guide](docs/onboarding-by-role.md) · [GitHub](https://github.com/adityaarsharma/orbit)

</div>

---

## What Orbit Is

A **Claude Code plugin** that gives a WordPress plugin team — dev, QA, PM, designer, release ops — a single command (`/orbit-do-it`) that audits everything that matters before a release: code standards, security, performance, accessibility, UAT, visual regression, hosting compatibility, EU CRA compliance, and 100+ other concerns.

It's **not a SaaS**. Runs locally via Docker (`wp-env`) + Claude Code. No accounts, no subscriptions, no cloud. The whole stack — 116 skills, all the scripts, the installer, this README — lives in one Git repo.

It's **runtime-evergreen**. When a skill runs, it fetches the canonical source-of-truth doc (e.g. Elementor's changelog, NVD's CVE feed, Kinsta's banned-plugins page) and applies *today's rules* — not a snapshot from when the skill was written. The same `/orbit-elementor-compat` SKILL.md handles V4 today, V5 next year, V6 the year after. Without anyone editing it.

It **composes with `WordPress/agent-skills`** — WP core's official AI agent skills (Brandon Payton, January 2026). Orbit's installer chains `npx openskills install WordPress/agent-skills`, so users get both: WP core's runtime/Playground primitives + Orbit's QA/UAT/audit suite.

---

## How it works — 3 layers

```
YOU
 │  "UAT audit example-plugin v2.5"          ← natural language in Claude Code
 ▼
AGENT  (05-uat.md)
 │  Step 1: Brain Prime                 ← 5 searches on brain
 │    "What did the last UAT find?"
 │    "Are there known flaky tests?"
 │    "What WP standards apply here?"
 │  Step 2: Spin Docker WP env
 │  Step 3: Playwright E2E
 │  Step 4: Dispatch 07-Security + 06-Perf + 04-Designer in parallel
 │  Step 5: Severity triage → CLEAR or BLOCKED
 │  Step 6: Ingest findings to brain   ← [uat, bug, example-plugin, High, ...]
 ▼
SKILLS  invoked by the agent automatically
 │  /orbit-playwright      → runs E2E browser tests
 │  /orbit-visual-regression → screenshots, diffs
 │  /orbit-wp-security     → XSS/CSRF/SQLi scan (via 07-Security)
 │  /orbit-lighthouse      → Lighthouse score (via 06-Performance)
 ▼
MCP + TOOLS  that skills use
    brain          ← read history, write findings
    wp-env (Docker)         ← clean WP install for testing
    Playwright + Chrome     ← real browser, real flows
    gh CLI                  ← open issues, create PRs
```

**The brain is what makes it a team, not just a tool.** Every finding is ingested. Every approved pattern is remembered. Every redline is surfaced the next time the same task runs. The agents get smarter every sprint — without you changing any files.

---

## Orbit Agentic — v3.0

> "Skills are easy. Process is harder. Brain is evergrowing — like onboarding a new person who's however smart, but still needs to learn YOUR products."

**v3.0 turns Orbit into a 10-agent QA team** where each agent has a defined role, written SOPs, a dedicated brain collection, and the MCP access to act on what they find. The more you use it, the smarter the whole team gets.

---

### The 10-Agent Team

| # | Agent | Role in one line |
|---|---|---|
| **00** | **CTO** | Strategic advisor. Reads all 10 brains. Sets direction — never executes. Sole writer to the shared brain. |
| **01** | **PM** | Daily coordinator. RICE scoring, feedback mining, sprint health. Routes every task to the right specialist. |
| **02** | **Code Reviewer** | Senior + skeptical. PHP, Gutenberg, Elementor, compat. APPROVE / REQUEST CHANGES / NITPICK — with file:line. |
| **03** | **Senior Dev** | Builds features, fixes UAT bugs. Runs WP standards before done. Never self-merges. |
| **04** | **Dev Designer** | WCAG 2.2 AA, RTL, dark mode, empty/error states. Writes design specs — 03 implements them. |
| **05** | **UAT** | Docker WP env, Playwright E2E, visual regression. Orchestrates 06 + 07 + 04 in parallel. Severity gates releases. |
| **06** | **Performance** | Hook weight, DB queries, bundle analysis, Lighthouse. Sets perf budgets. Enforces regression thresholds. |
| **07** | **Security** | XSS, SQLi, CSRF, supply chain, CVE, Stripe/EDD/Freemius, GDPR, PCI, premium gating. NEVER tests production. |
| **08** | **Release** | 7-step gate, WP.org Plugin Check, zip hygiene, release notes (Orbit voice), cross-channel announce. |
| **09** | **Docs** | README, feature docs, hook reference, in-code comments, changelog language. Ships with release — never after. |

---

### The shared brain — CTO is the head

`orbit/00-cto` is the team's constitution. Every agent reads it **first** — before their own collection. The CTO agent is the only one that writes to it. What lives there:

```
brain
└── orbit/
    ├── 00-cto/
    │   ├── hard-rules/       ← WP coding standards, security patterns, release rules
    │   ├── decisions/        ← Technology + product direction decisions
    │   ├── competitor-intel/ ← Competitor moves, market signals
    │   ├── risks/            ← Unstable APIs, CVE trends, deprecation warnings
    │   └── approved-patterns/← Patterns promoted from any agent to team-wide
    │
    ├── 01-pm/        ← Roadmap, RICE decisions, sprint history
    ├── 02-code-reviewer/ ← Review patterns, approvals, redlines
    ├── 03-senior-dev/    ← Build patterns, fix history
    ├── 04-dev-designer/  ← WCAG findings, RTL patterns, token decisions
    ├── 05-uat/           ← Bug reports, UAT results, flaky test registry
    ├── 06-performance/   ← Benchmarks, perf budgets, regression history
    ├── 07-security/      ← CVE findings, vuln patterns, payment audit history
    ├── 08-release/       ← Release history, WP.org rejections, announce templates
    └── 09-docs/          ← Freshness tracking, API doc history, voice patterns
```

```bash
# First install — seed 40 knowledge drawers into orbit/00-cto/hard-rules/
```

Day-one intelligence in the CTO brain: WP escaping rules, block.json required fields, WCAG 2.2 AA checklist, Stripe webhook security, readme.txt rejection patterns, N+1 DB query patterns, and 34 more. No cold starts for any agent.

**Two keys:**
- **Team key** — read `orbit/00-cto` + own collection. Agents recall past findings, approved patterns, known issues.
- **Admin key** — full read + write. Ingest findings, promote patterns, announce cross-channel. EDD ops: Admin only.

---

### Brain Prime — what every agent does first

Before touching any code or producing any output, every agent runs 5 brain searches and writes a **Brain Prime block**:

```
BRAIN PRIME — example-plugin v2.5 (UAT)
• CTO rules:   Never ship unescaped output. RTL mandatory. Lighthouse target ≥ 85.
• Bug history: v2.4 block reorder crash (orbit/05-uat/example-plugin). Fixed in v2.4.1.
• Patterns that worked: Docker WP 6.8 + Gutenberg 18.x env. Playwright --project=chromium first.
• Patterns to avoid: waitForTimeout() — caused 3 flaky tests in v2.3 audit.
• Open question:  Is scroll-animation block new in v2.5? (brain silent — will check changelog)
```

This block is pinned before any skill invocation. The agent never re-asks for context that's already in brain.

---

### The approval loop

Every `approve` and `revise` from the operator teaches the brain:

```
you: approve              → agent asks "Save as approved pattern?" → ingests to own collection
you: revise: <why>        → agent auto-ingests redline → surfaces this FIRST next time same task runs
you: skip                 → ingests as deprioritised — agent won't suggest it again
```

**CTO promotes team-wide:** When a pattern is strong enough for the whole team (not just one agent), Admin runs:
```bash
# Example: promote a new nonce pattern to team-wide hard rule
# Admin ingests to orbit/00-cto with [cto, hard-rule, ...] tag
# Every agent picks it up on next Brain Prime
```

---

### How agents collaborate — 5 real scenarios

#### Scenario 1 — New feature, end-to-end

A feature request ("Add scroll animation block to example-plugin") flows through the whole team:

```
01-PM        → RICE score: Impact 8 / Confidence 7 / Effort 5 → score 112 → APPROVED
               Routes to: 03-SrDev (build) + 04-DevDesigner (spec first)

04-DevDesigner → Brain Prime: loads WCAG rules from orbit/00-cto, past RTL findings from orbit/04
               → DESIGN SPEC: RTL mirror required. Reduced motion variant required. Touch target ≥ 44px.
               → Routes spec to: 03-SrDev

03-SrDev      → Brain Prime: loads WP standards from orbit/00-cto, past build patterns from orbit/03
               → Builds. Runs /orbit-wp-standards before PR.
               → Handoff brief to: 02-CodeReviewer (via 01-PM)

02-CodeReviewer → Brain Prime: loads PHP hard rules, past TPA redlines from orbit/02
               → Reviews PHP + block.json + Gutenberg + compat
               → REQUEST CHANGES: "save() uses SSR — must declare RenderCallback in block.json"
               → 03-SrDev fixes → re-review → APPROVE

05-UAT        → Brain Prime: loads severity rules, v2.4 bug history from orbit/05
               → Playwright E2E + visual regression. Dispatches 07-Security + 06-Perf + 04-Designer in parallel.
               → All pass → UAT CLEAR. Routes to: 08-Release

08-Release    → 7-step gate. All pass.
               → Release notes drafted. Cross-channel announce.
               → Routes to: 09-Docs (same day publish)

09-Docs       → Freshness audit. Feature documented. API hook reference updated. Publish same day as release.
```

#### Scenario 2 — Critical security found mid-sprint

```
07-Security   → Scanning example-plugin v2.5 RC
               → CRITICAL: Settings page — /wp-admin/admin.php?page=nxtwp echoes ?search= without esc_html()
               → ESCALATING CRITICAL immediately to 01-PM. Stopping scan.
               → Ingests to orbit/07-security/example-plugin: [security, example-plugin, Critical, xss-settings-page, v2.5-rc]

01-PM         → Receives escalation. Blocks sprint. Routes to 03-SrDev as Priority 0.
               → Notifies 08-Release: release gate will not run until Critical is resolved.

03-SrDev      → Fixes: esc_html( sanitize_text_field( $_GET['search'] ) )
               → Routes back to 07-Security for re-scan.

07-Security   → Re-scans. Clean. Confirms fix.
               → Ingests: [security, example-plugin, fixed, xss-settings-page, v2.5]
               → Routes to 05-UAT for regression test.

05-UAT → 08-Release → 09-Docs  (normal flow resumes)
```

#### Scenario 3 — WP.org rejection: the brain learns forever

```
08-Release    → Submitted example-plugin v2.4.0 to WP.org.
               → REJECTED: "Plugin is loading scripts/styles on all admin pages"

08-Release    → Ingests rejection to orbit/08-release:
                 [release, example-plugin, wp-org-rejection, scripts-all-admin-pages, v2.4.0]
               → Routes to 00-CTO: "This may be a team-wide pattern issue"

00-CTO        → Checks orbit/02-code-reviewer — same pattern in TPA code too.
               → Decision: promote to hard rule.
               → Ingests to orbit/00-cto/hard-rules/:
                 [cto, hard-rule, no-scripts-all-admin-pages, wp-org-requirement, 2026-05-20]

From now on:  Every agent reads this rule on Brain Prime.
               02-CodeReviewer blocks any PR that loads scripts on all admin pages.
               08-Release checks for it in the 7-step gate.
               One rejection — zero repeats, across all 3 plugins, forever.
```

#### Scenario 4 — Performance regression caught before release

```
06-Performance → Benchmark example-plugin v2.5 vs v2.4 baseline (orbit/06-performance/example-plugin/budget)
               → REGRESSION: DB queries 11 (was 4). Bundle +38KB. Lighthouse 71 (was 83). All HIGH.

06-Performance → Routes to 01-PM with regression report.

01-PM         → Creates ticket. Routes to 03-SrDev with context from orbit/06.

03-SrDev      → Brain Prime: loads orbit/06 regression context + orbit/03 past performance fixes
               → Fixes: N+1 in get_posts() loop → single WP_Query with post__in
               → Fixes: tree-shaking config for scroll-animation bundle
               → Routes back to 06-Performance

06-Performance → Re-run. DB queries: 3. Bundle: +2KB. Lighthouse: 86. All pass.
               → Updates orbit/06-performance/example-plugin/budget for v2.5 baseline
               → Routes to 05-UAT
```

#### Scenario 5 — Competitor ships a feature → CTO brief → PM decision

```
00-CTO        → Monthly competitor pulse (via /orbit-pm-competitor-pulse)
               → Elementor Kit shipped: "AI Copilot inside block editor"
               → Assesses: High opportunity — our users want this too.

00-CTO BRIEF — Elementor Kit AI Copilot
  Signal:     Kit shipped AI block generation inside editor. WP.org reviews +320 this week.
  Assessment: Medium threat — users already asking in example-plugin support.
  Recommendation: Differentiate, not copy. Our angle: AI block config, not AI block generation.
  Owner:      01-PM runs RICE. 03-SrDev estimates effort.
  Confidence: Medium

00-CTO        → Ingests to orbit/00-cto:
                 [cto, competitor, elementorkit, ai-copilot, differentiate-with-config, 2026-05]

01-PM         → RICE: Reach 9 / Impact 7 / Confidence 5 / Effort 7 → score 45 → Q3 roadmap
               → Routes to backlog. Monitors competitor reviews monthly.
```

---

### Skills → agents — who uses what

Every agent invokes specific Orbit skills. The routing is declared in `routes/routes.yaml`. Quick reference:

| Agent | Key skills they invoke |
|---|---|
| **02 — Code Reviewer** | `/orbit-wp-standards` `/orbit-elementor-compat` `/orbit-gutenberg-dev` `/orbit-compat-matrix` |
| **03 — Senior Dev** | `/orbit-wp-standards` `/orbit-scaffold-tests` `/orbit-block-json-validate` `/orbit-i18n` |
| **04 — Dev Designer** | `/orbit-accessibility` `/orbit-designer-rtl` `/orbit-designer-dark-mode` `/orbit-designer-empty-error` |
| **05 — UAT** | `/orbit-playwright` `/orbit-visual-regression` `/orbit-user-flow` `/orbit-uat-gutenberg` `/orbit-uat-elementor` `/orbit-qa-regression-pack` |
| **06 — Performance** | `/orbit-lighthouse` `/orbit-db-profile` `/orbit-bundle-analysis` `/orbit-editor-perf` `/orbit-perf-stress-test` |
| **07 — Security** | `/orbit-wp-security` `/orbit-broken-access-control` `/orbit-sec-secrets-leak` `/orbit-cve-check` `/orbit-pay-stripe` `/orbit-gdpr` |
| **08 — Release** | `/orbit-release-gate` `/orbit-plugin-check` `/orbit-release-meta` `/orbit-zip-hygiene` `/orbit-changelog-test` `/orbit-version-compare` |
| **09 — Docs** | `/orbit-release-meta` `/orbit-i18n` `/orbit-pm-release-notes` `/orbit-abilities-api` `/api-documentation` |

Full routing: `routes/routes.yaml`

---

### Always-on agents (Phase 2)

Agent files support two operating modes:

- **Mode A (now)** — Operator-invoked in Claude Code. Open an agent, describe the task, it runs its SOP.
- **Mode B (Phase 2)** — API runner Autonomous runner. 9 AM–6 PM IST. Autonomous scheduled dispatch. No agent file changes needed.

When Phase 2 activates, 5 always-on agents will run on schedule: 00-CTO (competitor pulse weekly), 01-PM (daily sprint routing), 06-Performance (benchmark on every commit), 07-Security (CVE feed daily), 08-Release (release gate on tag push).

→ Full architecture: [docs/BLUEPRINT-ORBIT-V3.md](docs/BLUEPRINT-ORBIT-V3.md)

---

## Install in 60 seconds

```bash
curl -fsSL https://raw.githubusercontent.com/adityaarsharma/orbit/main/install.sh | bash
```

That installs:

1. Orbit cloned to `~/Claude/orbit`
2. **10 AI agents** symlinked into `~/.claude/agents/` — available in every Claude Code session
3. **116 `/orbit-*` skills** symlinked into `~/.claude/skills/` — agents invoke these automatically
4. **WordPress/agent-skills** via `npx openskills install WordPress/agent-skills` (WP core's official skills)
5. Power tools: PHPCS + WPCS + VIP + PHPCompatibility, PHPStan, Playwright + Chromium/Firefox/WebKit, Lighthouse, axe-core, WP-CLI, wp-env, wp-now, source-map-explorer, PurgeCSS

After install:

```bash
# 1. Quit Claude Code fully (Cmd+Q) and reopen — agents + skills register

# 2. Seed the starter brain (one-time, requires Admin key):

# 3. Talk to an agent:
"UAT audit ~/plugins/my-plugin for v2.5"
"Security scan the new AJAX handler in settings.php"
"Run release gate for my-plugin v2.5"

# Or use skills directly (no brain key needed):
/orbit-do-it ~/plugins/my-plugin
```

### What's the difference — agents vs skills?

| | Agents | Skills |
|---|---|---|
| **What they are** | SOP-driven specialists. Read brain, follow process, ingest findings. | Markdown instructions — Claude runs bash/PHP/Playwright |
| **How you invoke** | Natural language: "UAT audit this plugin" | Slash command: `/orbit-playwright` |
| **Skills vs agents** | Agents invoke skills automatically | Skills are tools — you or an agent calls them |
| **Brain access** | Yes — reads history, ingests findings | No — stateless per invocation |
| **When to use** | When you want the full workflow done right | When you want one specific check |

**Use agents for releases.** Use skills for quick one-off checks during development.

### Update later

```bash
/orbit-update          # refreshes both agents + skills, ~20 seconds
```

### From a clone (offline-capable)

```bash
git clone https://github.com/adityaarsharma/orbit ~/Claude/orbit
cd ~/Claude/orbit
bash install.sh
```

---

## The brainless team agent

The whole vision distilled into one command:

```bash
/orbit-do-it ~/plugins/my-plugin
```

What happens:

1. **Auto-detects** plugin type — Elementor addon, Gutenberg block plugin, WooCommerce extension, form plugin, membership/LMS, theme, or generic
2. **Picks the right pipeline** — core 6 audits + type-specific add-ons + UAT + live security feeds + perf + a11y + i18n
3. **Runs in parallel** with CPU throttle (auto-detects M1 / M2 / workstation)
4. **For UAT** — uses `/orbit-uat-agent` (Stagehand-style natural-language tests; no selectors to write)
5. **Generates** the master HTML report + a one-page TL;DR
6. **Verdict** — **SHIP**, **WARN**, or **BLOCK** with the top 3 things to fix

Total: **~10–15 minutes**, zero questions after the path. Designed for non-technical team members + dev leads who want the audit done, not configured.

```
$ /orbit-do-it ~/plugins/my-new-plugin

🪐 Detected: Elementor addon (PHP 8.1+, 14 widgets)
   Pipeline: 6 core audits + Elementor (dev/controls/compat/skins/V4)
             + UAT (natural-language) + live CVE feeds + Lighthouse
   ETA: 12 min.

[12 min later]

✅ Verdict: BLOCK release — 2 Critical findings.

   Top 3 to fix:
   1. Settings page — XSS in ?search= (active probe found it)
   2. widget-3 — render() echoes attribute without esc_html
   3. widget-7 — insert time 1.4s (target < 300ms)

   Full report: ~/plugins/my-new-plugin/reports/index.html
```

Want even less friction? **`/orbit-uat-agent`** alone — describe flows in English ("log in → open Settings → fill API Key → save → verify saved"), the agent generates Playwright + AI-resolved selectors, runs them, self-heals on UI changes. ~$0.01–0.05 per test. Designed so a designer or PM can run UAT without writing a selector.

---

## Runtime-evergreen, the philosophy

Software-quality tooling shouldn't freeze in the year it was written. WordPress, Elementor, Stripe, the CVE landscape — all evolve continuously. A skill that hardcodes "use apiVersion 3" is a time bomb.

Orbit's pattern, top of every SKILL.md:

```markdown
## Runtime — fetch live before auditing (DO THIS FIRST)

When this skill is invoked:

1. Fetch in parallel (these are source-of-truth):
   - https://elementor.com/pro/changelog/
   - https://developers.elementor.com/docs/deprecations/
   - https://github.com/elementor/elementor/releases

2. Synthesize current state:
   - "What's the current major Elementor version as of today?"
   - "What APIs were deprecated in the last 2 minor releases?"

3. Audit against synthesized current rules — NOT against embedded text below.

4. Cite, in every finding: source URL + fetch timestamp.
   Example: `Per elementor.com/pro/changelog (fetched 2026-04-30 14:32 UTC):
            foo() deprecated in 3.22.`
```

That section is **executable instructions for Claude**, not documentation. When the skill runs, Claude reads it → fetches → uses live data.

| | Old pattern (snapshot) | Runtime-evergreen (v2.7) |
|---|---|---|
| `/orbit-elementor-compat` | "Test 3.18 / 3.20 / 3.22 / latest" hardcoded | Fetches changelog → tests latest 3 minors of TODAY |
| `/orbit-host-kinsta` | "Banned plugins as of April 2026" | Fetches Kinsta's banned-plugins page on every run |
| `/orbit-cve-check` | Pulls NVD weekly via cron | Pulls NVD + Patchstack + WPScan + GitHub Advisory + MITRE per invocation |
| `/orbit-pay-stripe` | "Use PaymentIntents API" (today's recommendation) | Fetches Stripe API ref → uses today's recommendation |

WebFetch caches for 15 minutes, so back-to-back runs in `/orbit-do-it` don't fire 100 fetches — unique URLs are de-duped + reused. Total overhead: ~10–30 sec on cold cache, sub-second after.

If WebFetch fails (no network), every skill has `## Embedded fallback rules` for offline mode + a clear `⚠ Live source fetch failed — using fallback. Findings may be stale.` notice.

Full pattern: [EVERGREEN.md](EVERGREEN.md). Drift-checks across the suite: `/orbit-skill-improver --check` (action-mode meta-skill that fetches all skills' sources, diffs rules, opens PRs).

---

## The 116 Orbit skills

| Category | Count | Sample |
|---|---|---|
| **Master + Brainless** | 4 | `/orbit` `/orbit-do-it` `/orbit-skill-add` `/orbit-skill-improver` |
| **Setup & Environment** | 6 | `/orbit-setup` `/orbit-update` `/orbit-install` `/orbit-docker-site` `/orbit-wp-playground` `/orbit-pre-commit` |
| **Pipeline** | 3 | `/orbit-gauntlet` `/orbit-release-gate` `/orbit-multi-plugin` |
| **Code Audits** | 14 | `/orbit-wp-{standards,security,performance,database}` `/orbit-{accessibility,i18n,code-quality,pm-ux-audit,compat-matrix,cve-check,abilities-api,rtc-compat,broken-access-control,scaffold-tests}` |
| **Gutenberg / Block Editor Dev** | 8 | `/orbit-gutenberg-dev` `/orbit-block-{render-test,edit-test,patterns,bindings,variations}` `/orbit-fse-test` `/orbit-interactivity-api` |
| **Elementor Dev** | 6 | `/orbit-elementor-{dev,controls,compat,pro,skins,dynamic-tags}` |
| **UAT Templates + Agent** | 6 | `/orbit-uat-agent` (natural-language) + `/orbit-uat-{elementor,gutenberg,woo,forms,membership}` |
| **QA Specialised** | 5 | `/orbit-qa-{flaky-detector,mutation,coverage,snapshot-cleanup,regression-pack}` |
| **PM Specialised** | 5 | `/orbit-pm-{rice,release-notes,feedback-mining,roadmap,competitor-pulse}` |
| **Designer Specialised** | 5 | `/orbit-designer-{tokens,empty-error,icons,rtl,dark-mode}` |
| **Browser Testing** | 4 | `/orbit-playwright` `/orbit-visual-regression` `/orbit-user-flow` `/orbit-conflict-matrix` |
| **Performance** | 7 | `/orbit-{lighthouse,editor-perf,db-profile,bundle-analysis}` `/orbit-perf-{stress-test,memory-leak,cdn}` |
| **Comparison** | 4 | `/orbit-{uat,version,competitor}-compare` `/orbit-changelog-test` |
| **Release** | 5 | `/orbit-{release-meta,zip-hygiene,plugin-check,block-json-validate,reports}` |
| **WP Edge Cases** | 7 | `/orbit-{multisite,uninstall-test,gdpr,cron-audit,cache-compat,rest-fuzzer,ajax-fuzzer}` |
| **Lifecycle** | 3 | `/orbit-life-{activation,upgrade,rollback}` |
| **Hosting Compat** | 5 | `/orbit-host-{wpengine,kinsta,cloudways,shared,pantheon}` |
| **Plugin Compat** | 5 | `/orbit-compat-{yoast,rankmath,wpml,polylang,acf}` |
| **Payment Integration** | 4 | `/orbit-pay-{stripe,paypal,edd,freemius}` |
| **Security Specialised** | 3 | `/orbit-sec-{xss-active,supply-chain,secrets-leak}` |
| **EU CRA + Premium** | 2 | `/orbit-vdp` (EU mandate) `/orbit-premium-audit` (Patchstack: 76% Pro vulns exploitable) |
| **SEO** | 3 | `/orbit-seo-{schema,sitemap,page-speed}` |

**Full skill reference** with trigger phrases + descriptions: [SKILLS.md](SKILLS.md).

---

## Composition with `WordPress/agent-skills`

WP core ships its own AI agent skills via [WordPress/agent-skills](https://github.com/WordPress/agent-skills) ([announcement, January 2026](https://wordpress.org/news/2026/01/new-ai-agent-skill/)). The flagship skill is `wp-playground` — spins up WordPress in seconds via Playground CLI, gives AI agents a fast feedback loop for code iteration.

**Orbit wraps; it doesn't reinvent.** `install.sh` runs `npx openskills install WordPress/agent-skills` automatically. `/orbit-wp-playground` is a thin doc-only skill that points at WP core's runtime primitives.

| Concern | Owned by |
|---|---|
| Spin up WordPress for testing | **WP core** (`wp-playground`) |
| Plugin code-quality audit | Orbit (`/orbit-wp-standards` etc.) |
| Natural-language UAT | Orbit (`/orbit-uat-agent`) |
| Live security feeds | Orbit (`/orbit-cve-check`) |
| Multi-version matrix | Orbit (`/orbit-compat-matrix`) |
| WP 7.0 Abilities API | **WP core** runtime + Orbit audit (`/orbit-abilities-api`) |

When WP core ships more agent skills, Orbit picks them up via the same `npx openskills install` chain — no Orbit code change needed.

---

## Vision

### Why this exists

Most WordPress plugin issues that reach users fall into five categories:

1. **Code that was never wrong, just untested** — a widget that renders fine on the dev's machine breaks on PHP 8.2 or with WPML active or on Kinsta's edge cache
2. **Performance regressions nobody noticed** — a new feature adds 40 extra DB queries per page load, or 80KB to the bundle
3. **Design debt** — settings UI that confuses users because it was built dev-first, not user-first
4. **Flow blindness** — nobody mapped whether a first-time user can actually complete setup without a tutorial
5. **No comparison baseline** — "our Mega Menu is better than ElementKit" stated without any data

UAT (User Acceptance Testing) is the practice of validating a product from every perspective before it ships — not just "does the code run" but "will a real user get stuck, is the UI regressed, does the PM have evidence it's better than competitors." **Orbit automates that entire layer for WordPress plugins.**

### What top teams do that most don't

- Automattic / WordPress VIP run every commit through PHP linting + VIP coding standards before merge
- 10up uses AI-powered visual regression — catches when something *looks* different without being *technically* broken
- WordPress.org plugin team added 15+ automated security checks in 2025 alone
- Leading Elementor addon teams run Playwright E2E suites across 3 WP versions before release

Orbit brings that same discipline to any plugin team, with a single command.

### The three rules

1. **Local-first, not CI-first.** Real MySQL, real PHP, real browsers — already on your Mac. CI is optional plumbing.
2. **Skills are senior reviewers, scripts are junior QA.** Claude Code skills read the code the way an experienced senior developer would. Scripts handle deterministic checks.
3. **Skills must be runtime-evergreen.** No quarterly maintenance. Every skill fetches its canonical source on every run.

### What's coming next

- **WP 7.0 readiness** (ships May 20, 2026) — already covered by `/orbit-abilities-api` + `/orbit-rtc-compat` + the runtime-fetch pattern
- **EU Cyber Resilience Act compliance** — `/orbit-vdp` is mandatory; `/orbit-premium-audit` covers the 76% premium-exploitability gap
- **Elementor V4 Atomic** (default for new sites April 2026) — `/orbit-elementor-compat` auto-handles via runtime-fetch
- **Cloud-hosted runs** (orbit.run, future) — gauntlet on a PR via GitHub Action, no local Docker
- **Community contributions** — `/orbit-skill-add` is a meta-skill that scaffolds new skills in the Orbit pattern. Anyone can add a skill via PR; the community catalogue grows.

---

## Severity model

Every Orbit skill applies this triage:

| Level | Action before release |
|---|---|
| **Critical** | Block release. Fix immediately. |
| **High** | Block release. Fix in this PR. |
| **Medium** | Fix if under 30 min. Otherwise log + defer. |
| **Low / Info** | Log in tech debt. Defer. |

`/orbit-do-it` reads these consistently and produces a single SHIP / WARN / BLOCK verdict at the top of every report.

---

## Reports

Every audit run drops everything into `reports/`:

```
reports/
├── qa-report-<timestamp>.md           ← markdown summary
├── tldr-<timestamp>.md                ← one-page verdict
├── index.html                         ← master HTML (PM-friendly)
├── playwright-html/index.html         ← visual test report
├── skill-audits/index.html            ← tabbed AI audit
├── uat-report-<timestamp>.html        ← UAT comparison + videos
├── pm-ux/pm-ux-report-*.html          ← PM-friendly UX report
└── lighthouse/lh-<timestamp>.json     ← Core Web Vitals
```

Open the master index:

```bash
open ~/plugins/my-plugin/reports/index.html
```

Designed to be shared with PMs / managers / customers without terminal access.

---

## Standards this follows

- [WordPress Coding Standards](https://github.com/WordPress/WordPress-Coding-Standards) — WPCS phpcs ruleset
- [WordPress VIP Coding Standards](https://github.com/Automattic/VIP-Coding-Standards) — enterprise-grade rules
- [10up Open Source Best Practices](https://10up.github.io/Open-Source-Best-Practices/testing/) — coverage targets, E2E approach
- [WordPress Plugin Check](https://github.com/WordPress/plugin-check) — the official WP.org submission tool
- [WordPress Playground Guide](https://wordpress.github.io/wordpress-playground/) — CI browser testing
- [OWASP Top 10](https://owasp.org/www-project-top-ten/) — security baseline
- [WCAG 2.2 AA](https://www.w3.org/WAI/WCAG22/quickref/) — accessibility
- [Patchstack 2026 Security Whitepaper](https://patchstack.com/whitepaper/state-of-wordpress-security-in-2026/) — current threat model

---

## Contributing

Open to:

- **New skills** — fork, run `/orbit-skill-add`, follow the runtime-evergreen pattern, open a PR
- **Skill improvements** — every skill has `Sources & Evergreen References`. If a source moved or a rule needs updating, `/orbit-skill-improver --pr` opens a draft for review
- **Edge-case reports** — file a GitHub issue with `[skill]` or `[bug]` tag and a minimal repro

Keep contributions research-first. Every check should link to the standard or incident that motivated it.

---

## Built by

[the maintainers](https://adityaarsharma.com) · the maintainers
github.com/adityaarsharma/orbit

**The discipline:** Software-quality tooling shouldn't freeze in the year it was written. It should know what *today* looks like by re-reading the canonical sources every time it runs. That's runtime-evergreen. That's Orbit.

---

## 📚 Knowledge base (open-source)

Orbit ships a general WordPress QA knowledge base as plain files in [`knowledge/`](knowledge/):
- [`bug-signatures.md`](knowledge/bug-signatures.md) — 40+ WP bug signatures (security · core-compat · WooCommerce · i18n · perf/DB · PHP 8)
- [`eval-fixtures.md`](knowledge/eval-fixtures.md) — 20 regression fixtures with ground-truth findings
- [`agent-standard.md`](knowledge/agent-standard.md) — how agents reason (load-signatures-first, bounded reflection, Docker-live, self-eval)

This is the **general, open-source** Orbit — runs standalone, no hosted service required. Bug signatures are ever-evolving: add a new one whenever a bug escapes a real audit.
