# Orbit — Onboarding Guide

> You just installed Orbit. This guide gets you operational in one session.
> No prior reading needed — start here, follow in order.

---

## 1. What you just installed

Running `bash install.sh` gives you three things:

```
~/.claude/agents/     ← 10 AI specialists (talk to these)
~/.claude/skills/     ← 116 /orbit-* commands (agents call these)
~/Claude/orbit/       ← the repo (brain scripts, agent files, skill source)
```

**Agents** are the people on your team. **Skills** are the tools they use.
You talk to agents. Agents invoke skills. You don't call skills directly unless you want one specific check fast.

---

## 2. The 3-layer system

```
YOU
 │  type in Claude Code: "UAT audit my-plugin v2.5"
 ▼
AGENT  reads its SOP from ~/.claude/agents/05-uat.md
 │  — searches brain for past findings on this plugin
 │  — runs its process (step by step)
 │  — invokes skills automatically
 │  — ingests new findings back to brain
 ▼
SKILL  /orbit-playwright, /orbit-wp-security, etc.
 │  — Claude Code markdown instructions
 │  — fetches live docs (WP changelog, CVE feeds, Elementor deprecations)
 │  — runs bash / PHP / Playwright
 ▼
BRAIN  brain-posimyth (orbit/00-cto + own collection)
 │  — every agent reads CTO's brain first (hard rules, WP standards)
 │  — reads its own history (past findings on this plugin)
 │  — writes new findings after each session
```

**The brain is what separates Orbit Agentic from plain Claude Code.**
Without it: the agent starts cold every time — smart but amnesiac.
With it: the agent starts warm — "last audit found an N+1 in get_posts(), is it still there?"

---

## 3. The 10 agents — who to talk to

| Agent | When to talk to them |
|---|---|
| **00-CTO** | "Should we respond to Elementor's new AI feature?" / "Tech direction for Q3" |
| **01-PM** | "What should we build next?" / "RICE this feature request" / "Route this sprint" |
| **02-Code Reviewer** | "Review this PR" / "Is this PHP pattern correct?" / "Block editor audit" |
| **03-Senior Dev** | "Build this feature" / "Fix the bug UAT flagged" |
| **04-Dev Designer** | "Check accessibility on the settings page" / "RTL audit" / "Dark mode spec" |
| **05-UAT** | "Full audit before release" / "Test this flow" / "Visual regression check" |
| **06-Performance** | "Why is Lighthouse dropping?" / "DB query count spiked" / "Bundle size check" |
| **07-Security** | "Scan the new AJAX handler" / "CVE check dependencies" / "GDPR audit" |
| **08-Release** | "Run release gate" / "Submit to WP.org" / "Draft release notes" |
| **09-Docs** | "Are docs current for v2.5?" / "Document the new hook" / "Changelog review" |

**You don't need to pick the right agent perfectly.** Start by telling **01-PM** what you want to do — PM routes the work to the right specialist.

```
you: "I want to release NexterWP v2.5 this Friday. What needs to happen?"
01-PM: Checks sprint state, routes to 05-UAT + 09-Docs, 
       sets 08-Release as the final gate.
```

---

## 4. How to talk to an agent

Open Claude Code. Type naturally. The agent reads its system prompt from the installed `.md` file.

```bash
# Route everything through PM for complex tasks:
"Route the v2.5 release for NexterWP — UAT is done, need gate + announce"

# Or talk directly to the specialist:
"Security scan ~/plugins/tpa/includes/settings-ajax.php for XSS and nonce issues"
"Benchmark NexterWP v2.5 DB queries vs v2.4 baseline"
"Generate release notes for NexterWP v2.5 changelog entries"
"Check if NexterWP v2.5 docs are fresh for WP.org submission"
```

The agent will:
1. Show you a **Brain Prime block** — what it found in brain before starting
2. Follow its **SOP** — numbered steps, in order
3. Show results with **file:line refs** (never vague)
4. Ask `approve` / `revise` at decision points

---

## 5. The approval loop — how the brain learns

Every session, the brain learns from your responses:

```
agent gives you output
↓
you: approve          → "Save as approved pattern?" → ingests to brain
                         Next time: agent starts with this pattern loaded

you: revise: <why>    → auto-ingests redline immediately
                         Next time: agent surfaces this first — "last time this
                         approach was revised because X, trying different approach"

you: skip             → deprioritised — agent won't suggest it again
```

**This is how the team gets smarter.** You don't edit agent files. You don't update configs. You just approve what works and revise what doesn't — the brain accumulates.

---

## 6. The shared brain — CTO is the head

Every agent searches `orbit/00-cto` **first** before their own collection. CTO's brain is the team's constitution. When something is important enough for the whole team — a new WP.org rule, a security pattern, an architectural decision — CTO ingests it there. Every agent picks it up from the next session.

```
orbit/00-cto/hard-rules/    ← WP coding standards, security patterns, release rules
orbit/00-cto/decisions/     ← technology + product direction
orbit/00-cto/competitor-intel/ ← competitor moves, market signals
orbit/00-cto/approved-patterns/ ← patterns promoted to team-wide
```

First-time setup — seed the starter brain (one-time, Admin key required):

```bash
bash brain/seed-brain.sh --key <orbit-admin-key>
```

This seeds 40 knowledge drawers (WP Standards, Block Editor, Elementor, Security, Performance, Release, Accessibility, Compat) directly into `orbit/00-cto/hard-rules/`. Every agent starts day-one informed — not cold.

---

## 7. First session — step by step

### If you have a brain key (Team or Admin):

```bash
# Step 1 — (Admin only, one-time) Seed the brain
bash brain/seed-brain.sh --key <orbit-admin-key>

# Step 2 — Open Claude Code. Talk to PM.
"I want to audit NexterWP v2.4.1 before the release next week.
 What agents should run, in what order?"

# 01-PM routes: 05-UAT (full audit) → 07-Security + 06-Perf + 04-Designer
# (parallel) → 08-Release (gate) → 09-Docs (freshness)

# Step 3 — Start the UAT
"UAT audit ~/plugins/nexterwp for v2.4.1. Full audit."

# Step 4 — When UAT completes, respond to findings:
# Critical/High → you decide: fix now or defer
# you: revise: <why>  (on any finding you disagree with)
# you: approve        (when the report looks right)

# Step 5 — Run release gate
"Run release gate for NexterWP v2.4.1"

# Step 6 — Ship
"approve" → 08-Release drafts release notes + cross-channel announce
```

### If you don't have a brain key yet (skills-only mode):

```bash
# Direct skill use — no brain, but fully functional:
/orbit-do-it ~/plugins/my-plugin

# Or specific checks:
/orbit-wp-security     audit ~/plugins/my-plugin for XSS and auth issues
/orbit-release-gate    run 7-step gate for ~/plugins/my-plugin v2.5
/orbit-lighthouse      score ~/plugins/my-plugin on staging URL
```

Brain key → contact POSIMYTH for Team key access, or see `docs/team-access.md`.

---

## 8. MCP tools the agents use

Agents need these tools to act. They're set up once.

| Tool | What agents use it for | Setup |
|---|---|---|
| **`brain-posimyth`** | Brain search + ingest. Required for brain-aware sessions. | Team or Admin key in Claude Code settings |
| **`gh` CLI** | Read source code, create PRs, open issues, tag releases | `brew install gh && gh auth login` |
| **`wp-env`** | Docker WP environment for UAT and security testing | `npm install -g @wordpress/env` |
| **`Claude in Chrome`** | Visual regression, browser UAT, accessibility inspection | Built into Claude Code |
| **Context7** | Live WP API docs, Elementor docs, Stripe docs — fetched at runtime | Built into Claude Code |

**Minimum viable setup:** `gh` CLI + `wp-env`. Brain key unlocks the full system.

Full MCP reference: `docs/mcp-library.md`

---

## 9. Process layer — what's inside each agent

Every agent file has 4 parts:

```
## 🎓 Skills         ← which /orbit-* skills this agent knows and invokes
## 📋 Process        ← numbered SOPs (Step 1 → Step N) + guardrails (🚫 Never / ✅ Always)
## 🔌 MCP + Connectors ← which MCP tools it uses, which key tier required
## 🧠 Brain          ← what to search before starting, what to ingest when done
```

The **Process** layer is where your team's knowledge lives. When something goes wrong, when a new WP.org rule drops, when a recurring pattern needs to be blocked — you (or CTO) add it to the right agent's guardrails. One line:

```
🚫 NEVER enqueue scripts on all admin pages — WP.org rejection reason, 2026-05-20
```

Every future run of that agent checks this. Permanently.

Agent files live at: `~/.claude/agents/00-cto.md` through `~/.claude/agents/09-docs.md`
Source: `~/Claude/orbit/agents/` (symlinked — edit source, changes are live immediately)

---

## 10. Updating Orbit

```bash
/orbit-update
```

Refreshes both agents and skills symlinks. Pulls latest from GitHub. ~20 seconds.
Skill and agent content changes are live immediately (symlinks). No Claude Code restart needed.

---

## Quick reference card

```
Talk to PM for routing:      "Route the v2.5 release"
Talk to UAT for testing:     "Full audit ~/plugins/my-plugin v2.5"
Talk to Security for scans:  "Scan settings-ajax.php for XSS"
Talk to Release for gating:  "Run release gate v2.5"
Talk to CTO for strategy:    "Should we respond to X competitor feature?"
Talk to Docs for freshness:  "Are docs current for v2.5?"

Approval loop:
  approve              → save pattern to brain
  revise: <why>        → save redline to brain (prevents repeat)
  skip                 → deprioritise

Brain:
  Team key   → read orbit/00-cto + own collection
  Admin key  → read + write all collections (EDD = Admin only)
  Seed:      bash brain/seed-brain.sh --key <key>

Skills (quick, no brain):
  /orbit-do-it           Full audit, one command
  /orbit-wp-security     Security scan
  /orbit-release-gate    7-step release gate
  /orbit-lighthouse      Performance score
  /orbit-accessibility   WCAG 2.2 AA audit
```

---

## Related docs

- `README.md` — full architecture, all 5 collaboration scenarios
- `docs/mcp-library.md` — MCP setup for WordPress developers
- `docs/team-access.md` — Team key vs Admin key, key rotation
- `docs/24-use-cases.md` — 6 agentic scenarios + 25 skill scenarios
- `brain/orbit-brain-spec.md` — full brain architecture spec
- `SKILLS.md` — all 116 skills listed with categories
