# Orbit — Cross-Agent Handoff Schema

> When QA Lead dispatches sub-agents, each handoff must include this context block.

---

## Handoff brief schema

```
ORBIT HANDOFF BRIEF
From: <agent-id> (e.g. 01-qa-lead)
To: <agent-id> (e.g. 02-security)
Plugin: <plugin-name> v<version>
Plugin path: <local path>
Task: <specific task in one sentence>
Priority: Critical | High | Medium | Low
Brain context already loaded: <yes — see prime block below | no>
Depends on: <none | waiting for agent X to finish first>
Output needed: <what format — findings list | report | PR | approval gate>
---
BRAIN PRIME (from QA Lead's WAKE step — pass to sub-agent so it doesn't re-search):
• Plugin history: [...]
• Known issues: [...]
• Patterns to reuse: [...]
• Patterns to avoid: [...]
```

---

## Standard handoff paths

### Full audit (operator: "full audit" or "release gate")

```
01-qa-lead ──parallel──► 02-security    "PHP source security scan"
           ──parallel──► 03-performance "Hook weight + bundle analysis"
           ──parallel──► 06-designer    "Accessibility + RTL check"
           ──parallel──► 08-compat      "Plugin compat matrix"
           ──parallel──► 09-test-auto   "Regression pack run"
           ──waits for all──► 01-qa-lead assembles severity report
           ──if all Critical/High resolved──► 07-release "Release gate"
```

### Security-only (operator: "security scan")

```
01-qa-lead ──► 02-security (full cluster)
02-security ──if vulns found──► 01-qa-lead severity triage
```

### Release preparation (operator: "prepare release" or "release notes")

```
07-release ──► 12-seo-docs "Release notes + docs update"
07-release ──► 10-pm       "RICE check on any last-minute scope"
```

### Elementor work (operator: Elementor compat or widget check)

```
05-elementor ──► 03-performance "Widget render performance"
05-elementor ──► 06-designer    "Widget accessibility"
```

---

## Escalation rules

| Condition | Action |
|---|---|
| Agent finds Critical severity | Immediately escalate to 01-qa-lead before continuing |
| Agent unsure which finding is Critical vs High | Ask operator one question |
| Two agents find conflicting issues | 01-qa-lead arbitrates |
| Agent hits a skill error / no output | Log and ask operator to re-run with different context |
