# 🪐 Orbit update — all 11 agents now run standalone (no MCP, no keys)

**For: every Orbit dev. TL;DR: pull `main`, run `bash install.sh --update`, and all 11 agents work with zero MCP connectors and zero API keys.**

## What changed

Until now, every Orbit agent was wired to the internal `brain-posimyth` MCP. On spawn it ran
"5 brain searches before any output," skill routing lived in a per-agent brain RUNBOOK drawer,
and skip opt-outs had to be written to brain. If you didn't have a POSIMYTH key, the agents
half-worked at best.

That dependency is gone. **The repo is now the single source of truth.**

| Area | Before | Now |
|---|---|---|
| Prime on spawn | 5 `brain-posimyth` searches | Read the repo's own `skills/` + `checklists/` |
| Skill routing | per-agent brain RUNBOOK drawer (live state) | the agent's `.md` **Skill commands** block |
| Skip opt-out | note written to brain | one line in the run report (`reports/`) |
| Findings memory | ingested to brain collections | written to `reports/<plugin>-<date>.md` |
| Connectors needed | `brain-posimyth` (Admin/Team key) + `*-posi` connectors | none — just `gh`, `wp-env`/Docker, Chrome, Playwright |

All 11 agents — `orbit-cto`, `orbit-pm`, `orbit-code-reviewer`, `orbit-senior-dev`,
`orbit-dev-designer`, `orbit-uat`, `orbit-perf`, `orbit-security`, `orbit-release`,
`orbit-docs`, `orbit-runner` — were converted. Their Skills, Process logic, severity model,
and guardrails are unchanged. Only the brain/MCP wiring and the service-gated approval pauses
were removed.

## What did NOT change

- Every skill and the full audit/gauntlet pipeline still run exactly the same.
- The Smart-Agentic Mandate (Rule 0 — run every skill end-to-end) still applies; opt-out
  reasons just go in the run report instead of brain.
- Jigar's new **`/orbit-woocommerce-beta-check`** skill (PR #4) is merged into `main`.

## The optional internal brain (POSIMYTH staff only)

The `brain-posimyth` layer still exists for internal high-volume QA — it now adds *optional*
cross-run memory on top, and is **off by default**. Nothing requires it. Details:
`docs/internal-brain.md`.

## How to get it

```bash
# if you already have Orbit installed
bash install.sh --update

# fresh install (no key, no setup)
curl -fsSL https://raw.githubusercontent.com/adityaarsharma/orbit/main/install.sh | bash
```

Then fully quit Claude Code (Cmd+Q) and reopen so the new agents load. Talk to any agent —
e.g. `"UAT audit my-plugin v2.5"` — and it just works.

## Why

Orbit is a community tool. Gating agents behind an internal paid service made it unusable for
the people it's for. Now: clone, install, run. That's the whole story.
