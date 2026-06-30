# Orbit — WordPress QA & Dev Agent Team v3.0

> 11 AI specialists. One operator. Describe the work. Right agent picks it up.
> Every agent = **Skills + Process**. Runs fully standalone — no MCP, no API keys, no brain required.

---

## Standalone by default — no MCP, no keys

Every Orbit agent runs out of the box with nothing but the repo and standard dev tools
(`gh` CLI, `wp-env`/Docker, `Claude in Chrome`, Playwright). There is **no required MCP
connector and no API key**. Clone, run `install.sh`, talk to an agent — that's it.

Each agent primes from the **repo itself** — its own `skills/`, the `checklists/`, and the
shared docs — not from an external service. Findings are written to the run report under
`reports/`.

### Optional internal brain (POSIMYTH staff only — off by default)

POSIMYTH-internal runs can optionally layer a private memory/brain on top for cross-run
history and pattern reuse. It is **not part of the default path** and is never required to
run any agent. See [`docs/internal-brain.md`](docs/internal-brain.md) if you have keys.
Community users can ignore it entirely.

---

## Hard rules for every agent

1. **Prime from the repo first.** Read the relevant `skills/`, `checklists/`, and your own Skills list before output. Never start from zero — but never depend on an external service either.
2. **Process has guardrails.** Critical = flag immediately. Production = never touch. File:line = always cite.
3. **Skills are tools, not agents.** Agent invokes skills in sequence. Skills don't run autonomously.
4. **Don't self-merge.** Agents report findings and propose changes; a human approves merges and releases. `approve` / `revise: <reason>` / `skip` are operator replies, not service-gated pauses.
5. **Orbit skills are evergreen.** They fetch canonical sources at runtime. Trust their live-source logic.
6. **Quality gate before output.** No LLM-isms, no jargon, no vague findings.

Agent workflow spec: `memory/agent-workflow-pattern.md`

---

## How to use Orbit

**Don't call skills. Don't name agents. Say what you want.**

```
"Audit NexterWP 2.3 before release"
"Security scan TPA — anything critical?"
"All Gutenberg blocks passing JSON validation?"
"RICE score these 5 features for the backlog"
"Run UAT on the new membership module"
"Generate release notes for NexterWP 2.3"
"Is our payment flow GDPR compliant?"
"What did competitors ship this month?"
"Fix the bug UAT filed on the checkout widget"
"Is adopting the Interactivity API a good bet right now?"
```

Orbit routes, runs, and pauses only when it needs your yes/no.

---

## Intent → Agent routing

| If your request mentions… | Routes to |
|---|---|
| "strategy", "competitor", "should we adopt", "industry", "technology direction", "risk" | **00 — CTO** (advises, doesn't execute) |
| "prioritise", "backlog", "RICE", "roadmap", "feedback", "sprint", "what to build next" | **01 — PM** (routes work to 02–09) |
| "review", "PR", "block.json", "Gutenberg", "Elementor widget", "ACF", "WPML", "compat", "lifecycle", "multisite", "uninstall" | **02 — Code Reviewer** |
| "build", "implement", "fix bug", "feature", "write code", "refactor" | **03 — Senior Dev** |
| "accessibility", "WCAG", "a11y", "RTL", "dark mode", "empty state", "design tokens", "contrast", "touch targets" | **04 — Dev Designer** |
| "UAT", "test", "Playwright", "full audit", "pre-release", "visual regression", "flaky", "Docker", "clean install" | **05 — UAT** (also orchestrates full audits) |
| "performance", "slow", "speed", "memory leak", "bundle", "Lighthouse", "N+1", "autoload", "perf budget" | **06 — Performance** |
| "security", "XSS", "CSRF", "SQLi", "CVE", "vulnerability", "Stripe", "GDPR", "payment", "compliance", "PCI", "EDD", "Freemius", "premium gating" | **07 — Security** |
| "release", "changelog", "release notes", "zip", "metadata", "version bump", "readme.txt", "WP.org", "announce", "blog post", "social" | **08 — Release** |
| "docs", "documentation", "README", "screenshots", "API docs", "hook reference", "help article" | **09 — Docs** |

Multi-area request → **05 — UAT** orchestrates full audit and dispatches 07/06/04 in parallel.
Unclear → ask one question, then route.

---

## Full audit orchestration (05 — UAT coordinates)

```
operator: "full audit NexterWP 2.3"

05 UAT
  PRIME → read the UAT skills + checklists in the repo for this plugin type
  DISPATCH (parallel):
    ├── 07 Security     PHP source scan + CVE + payment/GDPR (if applicable)
    ├── 06 Performance  Hook weight + Lighthouse + baseline comparison
    └── 04 DevDesigner  WCAG + RTL + dark mode

  UAT FLOWS → Docker clean install → plugin UAT template
  
  ASSEMBLE → severity matrix (deduplicate cross-agent findings)
  GATE → "🔴 Critical: N  🟠 High: N  🟡 Medium: N | STATUS: BLOCKED/CLEAR"
  
  IF CLEAR → hand to 01-PM who routes to 08-Release
  
  02-CodeReviewer and 09-Docs are NOT in this dispatch:
    02 reviews code PRs (initiated by 03-SrDev, not the audit)
    09 checks docs freshness separately (before release, via 08-Release)
```

---

## Operator replies

These are plain replies you type to an agent — nothing is service-gated.

| You say | What happens |
|---|---|
| `approve` | Agent continues to the next step / proceeds with the proposed change |
| `approve all` | Approve all pending items in this report |
| `revise: <reason>` | Agent redrafts using your reason |
| `skip` | Drop this item, move to next |
| `pause` | Hold everything, resume later |
| `escalate` | Bump to orbit-pm for cross-agent coordination |

---

## Always-on agents (Phase 2 — coming)

Agents run in two modes:
- **Mode A (now):** Claude Code — operator invokes, agent responds
- **Mode B (Phase 2):** API runner — 9 AM–6 PM IST scheduled dispatch

Agent files are compatible with both. When Phase 2 activates, no file changes needed.

---

## The Team (11 agents)

| Agent | File | Charter |
|---|---|---|
| CTO | `agents/orbit-cto.md` | Strategy, competitor intel, tech direction — advises, never executes |
| PM | `agents/orbit-pm.md` | Daily coordinator, RICE, feedback mining, routes work |
| Code Reviewer | `agents/orbit-code-reviewer.md` | Senior + skeptical — reviews PRs, blocks bad code, demands tests |
| Senior Dev | `agents/orbit-senior-dev.md` | Builds features + fixes bugs — never self-merges |
| Dev Designer | `agents/orbit-dev-designer.md` | Plugin UI/UX consistency, WCAG 2.2 AA, RTL, design tokens |
| UAT | `agents/orbit-uat.md` | Docker UAT, flow testing, bug filing, full audit orchestration |
| Performance | `agents/orbit-perf.md` | Hook weight, N+1, bundle, Lighthouse, perf budgets |
| Security | `agents/orbit-security.md` | SAST, WP vulns, CVE, payment/GDPR/compliance |
| Release | `agents/orbit-release.md` | 7-gate release, WP.org submit, cross-channel announce |
| Docs | `agents/orbit-docs.md` | README, feature docs, API docs, screenshots, release notes |
| Runner | `agents/orbit-runner.md` | Automated shell runner — WP-CLI, Docker matrix, auto-fix |

**Archive:** Previous 12-agent structure (v3.0 initial) is at `agents/_archive/`. Logic preserved in relevant new agents per the consolidation map in `ORBIT-MEGA-RELEASE-HANDOFF.md`.
