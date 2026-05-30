# Orbit — Brain Architecture Spec

> brain-posimyth is the single memory layer for all Orbit agents.
> Orbit data lives in the `orbit/` namespace — separated from other POSIMYTH namespaces.

---

## Brain model — CTO is the head

**There is no separate "general" collection.**

`orbit/00-cto` is the top-level shared brain. The CTO agent is the only agent that writes to it (besides POSIMYTH-Admin). Every other agent reads `orbit/00-cto` first — before their own collection — because CTO's brain holds all the hard rules, WP evergreen standards, approved team-wide patterns, and strategic decisions.

```
brain-posimyth
└── orbit/
    ├── 00-cto/          ← THE SHARED HEAD BRAIN
    │   ├── hard-rules/       WP coding standards, security patterns, release rules
    │   ├── decisions/        Strategic decisions (technology, product direction)
    │   ├── competitor-intel/ Competitor moves, market signals
    │   ├── risks/            Technology risk flags (unstable APIs, CVE trends)
    │   └── approved-patterns/ Patterns promoted from any agent to team-wide
    │
    ├── 01-pm/           ← PM's own brain (roadmap, RICE, feedback patterns)
    ├── 02-code-reviewer/ ← Code review patterns, approvals, redlines
    ├── 03-senior-dev/   ← Build patterns, fix history, approved implementations
    ├── 04-dev-designer/ ← WCAG findings, RTL patterns, design token decisions
    ├── 05-uat/          ← Bug reports, UAT results, flaky tests, visual baselines
    ├── 06-performance/  ← Benchmarks, perf budgets, regression history
    ├── 07-security/     ← CVE findings, vuln patterns, payment/GDPR history
    ├── 08-release/      ← Release history, WP.org rejections, announce templates
    ├── 09-docs/         ← Freshness tracking, API doc history, voice patterns
    └── 10-runner/       ← wp-env matrix results, conflict maps, auto-fix confirmations, known-good configs
```

---

## Read/write rules

| Agent | Reads | Writes |
|---|---|---|
| **00 — CTO** | `orbit/00-cto` + all `orbit/01`→`orbit/10` | `orbit/00-cto` only |
| **01 — PM** | `orbit/00-cto` first, then `orbit/01-pm`, then `orbit/02`→`orbit/09` | `orbit/01-pm` only |
| **02–09 Specialists** | `orbit/00-cto` first, then own collection | Own collection only |
| **10 — Runner** | `orbit/00-cto` (hard rules) + `orbit/10-runner` (execution history) | `orbit/10-runner` only |
| **POSIMYTH-Admin** | All collections | All collections |
| **Customer-Team key** | `orbit/00-cto` (read), own session only | Own local session (not persisted) |

**Key rule:** Every agent reads CTO's brain before doing anything. CTO brain = the team's constitution.

---

## Chroma collection design

Each collection is a **separate Chroma vector space** — not just a folder filter.  
This means each agent has genuinely independent semantic search over its own history.

The CTO collection is the largest and most important. It should be queried first by every agent because it holds the most high-value cross-cutting knowledge.

---

## Key model

### POSIMYTH-Admin key
- Full read + write access to all `orbit/*` collections
- Can promote patterns to `orbit/00-cto` (team-wide approval)
- Can update hard rules in `orbit/00-cto/hard-rules/`
- EDD operations (store.posimyth.com): Admin key only

### Customer-Team key
- Read access to `orbit/00-cto` only (the shared head brain)
- Write access to own Claude Code session memory (local, not persisted to brain)
- Optional `--contribute` flag: sends anonymized patterns to POSIMYTH's evergreen review queue
- Cannot write to any `orbit/*` collection directly

---

## Brain naming convention

All Orbit notes tagged by agent: `[<agent-id>, <type>, <plugin-or-area>, ...]`

| Agent | Tag prefix |
|---|---|
| CTO (hard rule) | `[cto, hard-rule, ...]` |
| CTO (strategic) | `[cto, decision, ...]` |
| CTO (competitor) | `[cto, competitor, ...]` |
| PM | `[pm, rice, ...]` / `[pm, feedback, ...]` |
| Code Reviewer | `[reviewer, approved, ...]` / `[reviewer, blocked, ...]` |
| Senior Dev | `[dev, fix, ...]` / `[dev, pattern, ...]` |
| Dev Designer | `[designer, <plugin>, ...]` |
| UAT | `[uat, bug, ...]` / `[uat, audit-approved, ...]` |
| Performance | `[perf, benchmark, ...]` / `[perf, regression, ...]` |
| Security | `[security, <plugin>, ...]` |
| Release | `[release, <plugin>, ...]` |
| Docs | `[docs, <plugin>, ...]` |
| Runner | `[runner, matrix, ...]` / `[runner, conflict, ...]` / `[runner, fix-confirmed, ...]` |

**Examples:**
```
[cto, hard-rule, never-echo-without-escaping, 2026-05-20]
[cto, competitor, elementorkit, launched-ai-copilot, differentiate, 2026-05]
[pm, rice, nexterwp, scroll-animations, score-142, approved]
[reviewer, blocked, tpa, missing-nonce-ajax-handler, v6.3]
[uat, bug, nexterwp, High, block-editor-crash-on-reorder, v2.4]
[perf, benchmark, tpa, v6.3, db-queries-4, bundle-82kb, lighthouse-79]
[security, tpa, Critical, xss-settings-page, v6.2]
[release, nexterwp, released, v2.4.0, 2026-05-20]
```

---

## The 5 mandatory brain searches (every agent, every task)

```
Search 1: orbit/00-cto + "<task-area>"       — CTO brain: hard rules + approved patterns
Search 2: own-collection + "<plugin>"        — own history on this plugin
Search 3: own-collection + "approved last 30 days" — reuse what worked
Search 4: own-collection + "revised failed redline" — avoid what failed
Search 5: own-collection + "<specific-area> known issues" — domain context
```

Then produce **Brain Prime block** before ANY skill invocation:
```
BRAIN PRIME — <plugin> v<version>
• CTO rules: [relevant hard rules from orbit/00-cto]
• Plugin history: [what own brain knows — key past findings]
• Patterns that worked: [list — reuse]
• Patterns to avoid: [list — don't repeat]
• Open questions: [1-2 max — only if brain is silent]
```

---

## CTO brain seeding (first-time install)

On first Orbit install, Admin runs:
```bash
bash brain/seed-brain.sh --key <admin-key>
```

This seeds 40 pre-loaded knowledge drawers into `orbit/00-cto/hard-rules/` from `brain/starter-brain.md`:
- WP Standards (8): escaping, nonces, capability checks, sanitization, $wpdb, file structure, i18n, hooks
- Block Editor (6): block.json required fields, save vs SSR, attributes, editor hooks, Interactivity API, FSE
- Elementor (4): widget registration, control types, skin system, dynamic tags
- Security (5): XSS patterns, SQL injection, CSRF/nonce in AJAX, file inclusion, secrets exposure
- Performance (4): hook weight rules, N+1 patterns, asset loading, transient/cache
- Release (5): readme.txt fields, WP.org rejection reasons, semantic versioning, zip hygiene, changelog format
- Accessibility (4): WCAG 2.2 AA admin checklist, keyboard navigation, RTL rules, empty/error states
- Compat (4): WPML compat, caching plugin compat, multisite requirements, hosting constraints

Day-1 intelligence in CTO's brain. No cold starts for any agent.

---

## Ingest rules (what goes in brain, what doesn't)

### ✅ Always ingest
- Operator `approve` → after asking "Save as approved pattern?"
- Operator `revise: <reason>` → auto-ingest the redline immediately
- New Critical/High finding in a plugin never seen before
- Performance baseline for a new plugin version
- CTO decision that affects the whole team → ingest to `orbit/00-cto`
- New WP.org rule change → CTO ingests to `orbit/00-cto/hard-rules/`

### ❌ Never ingest
- Restated existing knowledge already in brain
- Routine "audit ran cleanly" with no new findings
- Findings already in brain from a previous audit
- Generic code patterns already in WP handbook
- Agent-specific findings into `orbit/00-cto` — those go to the agent's own collection
