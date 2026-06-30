# 🔴 RULE 0 — Smart-Agentic Mandate (applies to every Orbit agent)

> **Single source of truth for how every Orbit agent must execute.** Sits ABOVE every per-agent Process section. If this file disagrees with an agent's Process, this file wins.
>
> Operator directive 2026-06-02. Non-negotiable.

---

## A. Run every skill end-to-end. Default = full sweep, not cherry-pick

Every agent has a **Skill commands** list. When the agent is invoked on a project, the default is to **run every skill in that list against the project**. Not "if relevant", not "if mode is full" — every skill, every time, in the order the Process section prescribes.

**Why:** Orbit missed five RankReady i18n bugs (`JSON_UNESCAPED_UNICODE` corruption, JS↔PHP label parity, Polylang `.md` endpoint, stale .po translator file) because the conservative "only run the check that obviously applies" pattern lets entire bug classes slip through. The runtime traps in `orbit-code-reviewer` §10 exist precisely because static review keeps missing things. Run everything. Be aggressive. Time spent running a skill that returns CLEAR is cheap. Time spent shipping a bug is not.

**How to apply:**
1. On agent spawn, after priming from the repo (Step 1), build a **work-list** = every skill in your **Skill commands** block.
2. For each skill, run it. If it returns CLEAR with zero findings, log it and move on. Never silently skip.
3. The Process section's conditional branches (e.g. "if plugin has payments → run payment audit") are **escalation cues, not gates** — they mean "run this with EXTRA depth", not "run this only here". The baseline scan still runs.
4. Parallel by default. Independent skills fire in one batch (multiple tool calls in one message).
5. Sequential only when output of A feeds B (e.g. `/orbit-docker-site` must finish before `/orbit-uat-agent`).

## B. Opt-out requires a recorded reason

The ONLY way to skip a skill on a given run is to record the reason in the run report.

**Format (one line in the run report under `reports/`):**
```
SKIP <skill-name> on <plugin> v<version> — Reason: <why>
```

**Acceptable reasons:**
- Skill is unavailable for this plugin TYPE (e.g. `/orbit-pay-stripe` on a plugin with zero payment code — but you must have grep-verified the absence, not assumed)
- A previous run of this skill in the last 24h on this exact commit returned CLEAR (brain check)
- Operator explicitly said `--skip <skill>` on this invocation

**Banned reasons:**
- "This plugin probably doesn't need it" — run it and let the skill decide
- "It's a small change" — small changes shipped 4 of the 5 RankReady i18n bugs
- "It'll take too long" — see Why above
- "It found nothing last time" — last time was on a different commit

## C. Mandatory TaskCreate at task start

On any non-trivial agent invocation (>1 tool call), the FIRST thing the agent does — before any skill, before brain search — is `TaskCreate` for each skill in its work-list. Update to `in_progress` when starting, `completed` when the skill returns.

**Why:** Without a visible task list, agents drop skills under context pressure or model summary compaction. With one, every skill is tracked, visible to the operator, and audit-able.

## D. End-of-run completeness report

Every agent ends with a **Coverage Report** before the findings report:

```
COVERAGE — <agent> on <plugin> v<version>
Skills in list: <N>
Skills run:     <M>     (M should equal N)
Skills skipped: <N - M> (each with a reason recorded in the run report)

If M < N and no skip reason exists for a skipped skill → THIS RUN IS INVALID.
Restart and run the missing skills.
```

## E. Smart-agentic = aggressive, not conservative

When uncertain whether a skill applies:
- **Run it.** Empty result = cheap. Missed bug = expensive.

When the operator asks for "a quick check":
- **Run the full sweep.** Tell them "ran the full sweep in N seconds, results below" — quick is an output format, not an excuse to skip skills.

When you find a finding that overlaps with another agent's domain:
- **Flag it AND keep going.** The other agent will dedupe at orchestration time. Better two flags than zero.

When a skill seems redundant with a finding you already made:
- **Run it anyway.** Different skills catch different angles. `/orbit-i18n` catches `__()` wrapping; `/orbit-i18n-runtime` catches `JSON_UNESCAPED_UNICODE`. Both run.

## F. Cross-reference with other rules

- This rule (Rule 0) sits ABOVE every per-agent Process. It is the execution base.
- §10 (Code Reviewer runtime traps) is the documented list of bug classes that escaped Rule 0 in the past — every new escape adds an entry.
- This file wins on execution policy. Per-agent `.md` Process sections elaborate; they never override Sections A–E.

## G. Verification

Before reporting `STATUS: CLEAR` to the operator, the agent must include the Coverage Report (Section D). An agent that returns CLEAR without coverage data has not actually done the work.

## H. The agent `.md` is the source of truth for skill routing

Each agent's **Skill commands** block in its own `.md` file is the canonical skill set + run order. Build the work-list (Section A) directly from that block — no external service, no brain, no network call.

**To give an agent a new skill — or move one between agents — edit the agent's `.md` Skill commands block and commit.** It goes live on the next `install.sh --update` (skills are symlinked, so text changes apply immediately). The repo is the single source of truth; there is no separate live-state service to keep in sync.

---

**Last updated:** 2026-06-30
**Operator approval:** required for any change to Sections A, B, D, E, or H
