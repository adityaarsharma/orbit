# Blueprint — Orbit Agentic v3.0

**Date:** 2026-05-20
**Version:** 3.0.0 — Orbit Agentic
**Build type:** Multi-session, multi-agent architecture upgrade

---

## What v3.0 is

Orbit goes from a **skill library** to a **living QA team**.

Every agent now has 4 parts — like a real hire:

| Part | What it means | Hard/Easy |
|---|---|---|
| **Skills** | What this agent knows and can do | Easy — already existed |
| **Process** | HOW we do it at POSIMYTH — SOPs, guardrails, order of ops | Hard — this is the real work |
| **MCP** | The connectors/systems where work happens | Easy — we have them |
| **Brain** | The intelligence layer — recalls past, learns from every approval | Evergrowing — never done |

The Brain is the hardest because it's like onboarding a new person. However smart they are, they need to learn YOUR products. Orbit ships a **starter brain pack** so every new install starts with Orbit-level intelligence, not zero.

---

## Architecture overview

```
┌──────────────────────────────────────────────────────────────────────┐
│                         OPERATOR                                      │
│  Plain language: "Audit NexterWP 2.3" / "RICE score backlog"         │
└───────────────────────────┬──────────────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────────────┐
│                    CLAUDE.md ROUTER                                   │
│  Intent → Agent routing | Team/Admin tier | Approval gate protocol   │
└───────────────────────────┬──────────────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────────────┐
│                    12 AGENT TEAM                                      │
│  Each agent = Skills + Process + MCP + Brain                         │
│                                                                       │
│  01 QA Lead      02 Security     03 Performance   04 Gutenberg Dev   │
│  05 Elementor    06 Designer     07 Release Mgr   08 Compat Eng      │
│  09 Test Auto    10 PM           11 Compliance    12 SEO & Docs      │
└───────────┬───────────────────────────────────────┬──────────────────┘
            │                                       │
            ▼                                       ▼
┌────────────────────────┐          ┌───────────────────────────────────┐
│   MCP LAYER            │          │   BRAIN LAYER                     │
│   (where work happens) │          │   (brain-posimyth orbit namespace)│
│                        │          │                                   │
│  brain-posimyth        │          │  Team key:  READ orbit/*          │
│  GitHub (gh CLI)       │          │  Admin key: WRITE orbit/*         │
│  wp-env / wp-cli       │          │                                   │
│  Claude in Chrome      │          │  orbit/plugins/<name>             │
│  DataForSEO            │          │  orbit/patterns/approved          │
│  Apify (via brain)     │          │  orbit/patterns/revised           │
│  Slack / n8n           │          │  orbit/knowledge/*                │
│  WP sites (publish)    │          │  orbit/team/agents/*              │
└────────────────────────┘          └───────────────────────────────────┘
```

---

## The 4-Part Agent Model (for every team member)

### 🎓 Skills
> "A new hire knows email marketing."

The discrete capabilities the agent has. What it can analyse, detect, generate, or judge. These map directly to Orbit skills + cherry-picked global skills.

**Rule:** Skills are TOOLS. The agent invokes them. Skills are not agents.

---

### 📋 Process
> "The process is: upload draft to FluentCRM, set the segment, preview, then send."

The POSIMYTH-specific SOP. Step-by-step order of operations. This is what makes an agent feel like your team member, not a generic Claude instance.

**The hard part:** Process has guardrails. Every step that could go wrong has a rule:
- Critical finding → stop and escalate (don't batch)
- Never test production (always staging)
- Always cite file:line (never vague findings)
- Never re-report fixed issues (check brain)

**Process = Skills + Order + Guardrails**

---

### 🔌 MCP + Connectors
> "After knowing the skill and process, you need the system where it runs."

| Tier | Tools available |
|---|---|
| **Team (read-only)** | brain-posimyth read, GitHub read, Claude in Chrome, DataForSEO |
| **Admin (write)** | brain-posimyth write, GitHub write, WP sites publish, Slack, n8n, Apify, FluentCRM |

Each agent file specifies exactly which connectors it uses and at what tier.

---

### 🧠 Brain
> "A smart new hire still needs to learn your products. Brain is that learning."

The intelligence layer. Two jobs:
1. **Recall** — Before any work: 5 brain searches. What do we know about this plugin? What patterns worked? What failed? Never start from zero.
2. **Ingest** — After every approval: save what's new. After every revision: save the redline. Brain compounds. By week 4, the agent rarely asks questions.

**Brain is evergrowing.** It's never "done". Every approve/revise is a new drawer.

**Orbit starter brain:** 40 pre-loaded drawers shipped with Orbit. Day-1 intelligence.

---

## Brain — Team vs Admin key model

```
brain-posimyth
└── orbit/              ← Orbit namespace (separated from Golden Circle)
    ├── plugins/
    │   ├── nexterwp/   ← per-plugin findings history
    │   ├── tpa/
    │   └── uichemy/
    ├── patterns/
    │   ├── approved/   ← "do this again" — approved by operator
    │   └── revised/    ← "don't do this again" — revised/rejected
    ├── knowledge/      ← evergreen WP + Orbit standards
    │   ├── wp-standards
    │   ├── block-editor
    │   ├── elementor
    │   ├── security
    │   └── performance
    └── team/
        └── agents/     ← per-agent learnings (01-qa-lead, 02-security, ...)
```

**Team key:** Can search + read `orbit/*`. Cannot write. Cannot access Golden Circle drawers.
**Admin key:** Can write to `orbit/*`. Full ingest. Can add to `knowledge/` base.

---

## Always-on agents (future — Phase 2)

5 agents will run 9 AM – 6 PM IST like real employees. Which 5 is operator's choice. The framework already supports this — agent files are written for both:
- **Mode A (current):** Claude Code — operator types, agent responds
- **Mode B (future):** API-based runner — Dora/PM2 dispatches task, agent runs headlessly, reports back to ClickUp/Slack

No change to agent files needed between modes. The 5-step WAKE/ANALYSE/PLAN/EXECUTE/INGEST is mode-agnostic.

---

## MCP library — WordPress dev essentials

See full spec at `docs/mcp-library.md`.

**Must-have for any WP dev using Orbit:**
1. `brain-posimyth` (orbit namespace) — memory
2. GitHub via `gh` CLI — code, PRs, issues
3. `Claude in Chrome` — visual browser testing
4. Context7 — live WP/React/PHP docs at runtime
5. Apify (via brain-posimyth) — WP.org scraping, CVE mining
6. DataForSEO — PageSpeed, SERP, performance data

**POSIMYTH team additionally:**
7. `wp-nexterwp` / `wp-theplusaddons` / `adityaarsharma-wordpress` — WP publish
8. `n8n-mcp` — workflow automation
9. `slack-aditya` — team notifications
10. `fluentcrm` — release email drafts

---

## v3.0 release scope

### What ships in v3.0
- [ ] CLAUDE.md — Team/Admin tier model + full routing
- [ ] 12 agent files — 4-part structure (Skills/Process/MCP/Brain)
- [ ] `brain/orbit-brain-spec.md` — Brain architecture
- [ ] `brain/starter-brain.md` — 40 pre-loaded drawers
- [ ] `docs/mcp-library.md` — MCP audit for WP devs
- [ ] `docs/team-access.md` — Team vs Admin key setup guide
- [ ] `memory/agent-workflow-pattern.md` — Updated 5-step workflow
- [ ] `routes/routes.yaml` — Full skill source map
- [ ] CHANGELOG.md v3.0 entry
- [ ] README.md update — Agentic section

### What's Phase 2 (post-v3.0)
- Always-on 5 agents (Dora + PM2 + Claude API runner)
- ClickUp task queue integration
- Slack status mirror
- Per-agent daily digest

---

## Build sequence (this session)

```
Step 1  CLAUDE.md update (Team/Admin + 4-part framework)        ← this file done
Step 2  All 12 agent files with 4-part structure                ← agents/
Step 3  Brain spec + starter brain                              ← brain/
Step 4  MCP library + Team access docs                          ← docs/
Step 5  CHANGELOG v3.0 entry                                    ← CHANGELOG.md
```
