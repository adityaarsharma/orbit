# Orbit — Brain Connector Spec

## Primary connector

| Connector | URL | Tier |
|---|---|---|
| `brain-posimyth` | `https://brain.posimyth.com/connectors` | Admin (full access) |

## Tools used by Orbit agents

| Tool | Use |
|---|---|
| `posimyth_brain_search` | Search past audit findings, known issues, patterns, operator preferences |
| `posimyth_brain_wake_up` | Wake up brain context at session start |
| `posimyth_brain_list_drawers` | Browse available memory drawers |
| `posimyth_brain_add_note` | Ingest new learnings after operator feedback |
| `wp_nexterwp_*` | Publish release notes, docs, changelogs to NexterWP site |
| `wp_tpae_*` | Publish release notes, docs, changelogs to TPAE site |
| `github_*` | PR creation, issue tracking, branch operations |

## Brain drawer naming convention for Orbit

All Orbit learnings are tagged: `[orbit, <agent-id>, <task-type>, approved|revised|deprioritised]`

Examples:
- `[orbit, 02-security, xss-scan, approved]` — security pattern operator approved
- `[orbit, 07-release, zip-hygiene, revised]` — release process that needed rework
- `[orbit, 04-gutenberg, block-json, deprioritised]` — check operator decided to skip

## Hard rules

1. `brain-posimyth` is the ONLY connector. Old per-service stdio MCPs are deprecated.
2. All brain writes require Admin tier — never use Team tier for `add_note`.
3. Every search must use at least 3 different query angles (see workflow pattern).
4. Brain search results older than 90 days should be flagged as potentially stale.
