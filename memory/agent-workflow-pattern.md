# Orbit — Agent Workflow Pattern (5-step, mandatory for every agent)

> Every Orbit agent follows this exact pattern on every task. No exceptions.

---

## The 5-step workflow

### Step 1 — WAKE (Brain First)

Before writing a single line of analysis, the agent searches brain aggressively.

```
Search 1: posimyth_brain_search("<plugin name> audit history") — top 10
Search 2: posimyth_brain_search("<task type> findings <plugin type>") — top 5
Search 3: posimyth_brain_search("<domain area> known issues patterns") — top 5
Search 4 (self-history): posimyth_brain_search("<task type> approved last 30 days") — approved patterns to REUSE
Search 5 (negative-history): posimyth_brain_search("<task type> revised OR failed OR flagged") — patterns to AVOID
```

Then produce a **Brain Prime block** (internal, before any skill invocation):

```
BRAIN PRIME
• Plugin history: [what brain knows about this plugin]
• Known issues: [past findings that were flagged]
• Patterns that worked (last 30d): [list — reuse these]
• Patterns that failed/were revised: [list — DO NOT REPEAT]
• Operator preferences: [any stated rules from past sessions]
• Open questions (only if brain truly silent): [1-2 max]
```

**NEVER ask the operator to re-explain context that already exists in brain.** If brain has it, use it.

---

### Step 2 — ANALYSE

The operator's prompt is the **trigger**, not the full brief. The full brief = brain context + prompt combined.

- Apply every known pattern, preference, and historical finding from brain to the task
- If brain says "this issue was already fixed in v2.1" → don't re-flag it
- If brain says "Elementor 3.x compat breaks here" → lead with that
- If brain has nothing relevant → state that explicitly, then proceed fresh

---

### Step 3 — PLAN

Write a 3-line plan before executing:

```
Task: <restated in one sentence>
Skills I'll use: <ordered list with reason>
Output: <what operator sees>
Approval gate at: <which step pauses for operator yes/no>
```

---

### Step 4 — EXECUTE

Invoke skills **one at a time**, in the order planned. Each skill output feeds the next.

- Never one mega-prompt that tries to invoke 6 skills at once
- Parallel execution only when skills are completely independent (e.g. security + performance have no shared state)
- Surface findings at each skill step — don't batch everything for the end
- Flag Critical/High findings immediately, don't wait for the full report

---

### Step 5 — INGEST

After every task, ingest operator feedback into brain. This is what makes Orbit smarter over time.

| Operator says | Agent does |
|---|---|
| `approve` / `perfect` / `ship it` | Ask: "Save as approved pattern for future `<task-type>`?" → on yes: `posimyth_brain_add_note` with tag `[approved-pattern, orbit, <task-type>]` |
| `revise: <reason>` | Auto-ingest redline: `posimyth_brain_add_note` with tag `[revised, orbit, redline, <reason>]`. Next same task → brain surfaces this first |
| `skip` / `drop` | Ingest as `[deprioritised, orbit, <task-type>]` |
| Routine continue | NO ingest — only operator-feedback-driven signals |

**Selective:** only ingest what's NEW and OPERATOR-CONFIRMED. Never restate existing brain knowledge.

---

## What makes Orbit agents different from plain skill invocations

| Plain skill invocation | Orbit agent |
|---|---|
| Starts from zero every time | Starts from brain — compounding context |
| Re-asks same questions | Never re-asks — brain has the answers |
| Skills run in isolation | Agent orchestrates skill sequence with context hand-off |
| No learning loop | Every approve/revise makes next run smarter |
| Operator re-explains plugin history | Brain remembers every past finding |
