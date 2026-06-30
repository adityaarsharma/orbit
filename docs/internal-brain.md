# Optional internal brain (POSIMYTH staff only)

> **You do not need this to use Orbit.** Every agent and skill runs fully standalone — no
> MCP, no API key, no network service. This document describes an **optional** memory layer
> that POSIMYTH staff can enable for cross-run history. Community users can ignore it.

## What it is

The internal brain is a private memory service (`brain-posimyth`) that lets agents persist
findings across runs and recall prior decisions. When it is **not** configured — the default
for everyone — agents prime from the repo (`skills/`, `checklists/`, their own Skill commands
block) and write findings to the run report under `reports/`. Nothing breaks; you simply don't
get cross-run memory.

## Default behaviour (no brain)

| Step | Without brain (default) |
|---|---|
| Prime on spawn | Read relevant `skills/` + `checklists/` in the repo |
| Skill routing | The agent's own `.md` **Skill commands** block |
| Skip opt-out | One line recorded in the run report under `reports/` |
| Findings storage | Written to `reports/<plugin>-<date>.md` |
| Cross-run recall | None — each run is self-contained |

This is the supported path for all community and external users.

## Enabling the optional layer (staff)

If you have a POSIMYTH-issued key, you can layer the brain on top. It only adds cross-run
recall and ingest — it never changes what a run is *capable* of.

```bash
mkdir -p ~/.orbit
echo 'ORBIT_TEAM_KEY=your_key_here' >> ~/.orbit/keys.env
bash install-connectors.sh <your_key>
```

- **No key in `~/.orbit/keys.env`** → `install.sh` skips connector setup and prints a note. Agents still install and run.
- Keys are issued internally. There is no public key provisioning — this layer is intentionally staff-only.

## Why it's optional

Orbit is a community tool. Gating any agent or skill behind a paid/internal service would
make the framework unusable for the people it's meant for. The brain is a convenience for
high-volume internal QA, not a dependency. If this document ever describes something an agent
*requires* to run, that's a bug — file it.
