---
name: orbit-update
description: Update Orbit to the latest version. Pulls the latest from GitHub, refreshes every installed `/orbit-*` skill in place, and removes any deprecated entries. Zero questions, zero prompts. Use whenever the user says "update orbit", "upgrade orbit", "pull latest orbit", "refresh orbit skills", or has seen a new release on the Orbit repo. Safe to run repeatedly — if already on latest, exits cleanly.
argument-hint: (no arguments — just run it)
disable-model-invocation: false
---

# 🪐 orbit-update — One-command updater

> Part of [Orbit](https://github.com/adityaarsharma/orbit) · Built by [Aditya Sharma](https://github.com/adityaarsharma)

You are the **orbit-update** agent. Your only job: pull the latest Orbit from GitHub, refresh every installed skill on this machine, remove deprecated tools, and tell the user what changed. **No prompts. No questions. No preferences touched.** Pure passthrough.

---

## STEP 1 — Announce

Print exactly this:

```
════════════════════════════════════════════════════
  🪐  Orbit — updating to latest
════════════════════════════════════════════════════

I'll pull the latest from github.com/adityaarsharma/orbit and
refresh every /orbit-* skill on this machine. Your qa.config.json,
reports, .auth/ cookies, and Docker containers stay untouched.

Deprecated commands (if any) will be removed automatically —
keeping your /orbit-* palette clean.

Takes about 20-30 seconds.
```

---

## STEP 2 — Detect install location

Orbit is typically cloned to `~/Claude/orbit`. Detect:

```bash
if [ -d "$HOME/Claude/orbit/.git" ]; then
  ORBIT_HOME="$HOME/Claude/orbit"
elif [ -d "$HOME/orbit/.git" ]; then
  ORBIT_HOME="$HOME/orbit"
elif command -v orbit-locate >/dev/null 2>&1; then
  ORBIT_HOME=$(orbit-locate)
else
  echo "ORBIT_NOT_FOUND"
fi
```

If `ORBIT_NOT_FOUND`, fall through to **Remote-update path** (Step 4). Otherwise → Step 3.

---

## STEP 3 — Local-update path (Orbit is cloned)

```bash
cd "$ORBIT_HOME"

# Capture current version for the diff
OLD_VERSION=$(git describe --tags --always 2>/dev/null || git rev-parse --short HEAD)

# Pull latest
git fetch --tags --quiet
git pull --rebase --quiet

NEW_VERSION=$(git describe --tags --always 2>/dev/null || git rev-parse --short HEAD)

if [ "$OLD_VERSION" = "$NEW_VERSION" ]; then
  echo "ALREADY_LATEST $NEW_VERSION"
else
  echo "UPDATED $OLD_VERSION → $NEW_VERSION"
fi
```

If already on latest:
```
✅ Already on the latest Orbit (<version>). Nothing to do.
```

If updated, run the install script to refresh symlinks:

```bash
bash "$ORBIT_HOME/install.sh" --update
```

`--update` flag tells install.sh: don't ask anything, just refresh symlinks + remove deprecated.

Show:
```
✅ Refreshed all skills. <NEW_VERSION>

What's new since <OLD_VERSION>:
   <output of: git log OLD_VERSION..NEW_VERSION --oneline | head -10>
```

---

## STEP 4 — Remote-update path (Orbit isn't cloned)

The user installed via the curl one-liner — Orbit isn't on disk locally. We need to fetch and re-install.

```bash
curl -fsSL https://raw.githubusercontent.com/adityaarsharma/orbit/main/install.sh | bash -s -- --update
```

If `curl` isn't available, fall back to `wget`:

```bash
wget -qO- https://raw.githubusercontent.com/adityaarsharma/orbit/main/install.sh | bash -s -- --update
```

If both fail, show the manual fallback:

```
❌ Couldn't reach GitHub to fetch the updater.

Manual fallback:

  git clone https://github.com/adityaarsharma/orbit ~/Claude/orbit
  cd ~/Claude/orbit
  bash install.sh --update

Then re-run /orbit-update.
```

---

## STEP 5 — Verify the update landed

```bash
ls ~/.claude/skills/ | grep -c '^orbit'
```

Expected: 45 (or whatever the latest count is). Tell the user the count.

```bash
cat ~/Claude/orbit/.orbit_version 2>/dev/null
```

Should show the version we just pulled.

---

## STEP 6 — Final message

Print:

```
════════════════════════════════════════════════════
  ✅ Orbit is on the latest version (<NEW_VERSION>)
════════════════════════════════════════════════════

What got refreshed:
  • <N> skills in ~/.claude/skills/orbit-*
  • All /scripts/*.sh helpers
  • Templates in /tests/playwright/templates/
  • Docs in /docs/

What stayed:
  • Your qa.config.json
  • reports/ history
  • .auth/ cookies
  • Docker containers (wp-env)

If you see new /orbit-* commands you didn't have before,
they're listed in /orbit (master menu). Try them out.

Skill text changes apply immediately.
No restart needed unless an MCP server changed.
```

---

## STEP 7 — Remove deprecated skills (if any)

The install script handles this, but as a safety net, check for known-removed skills and clean them:

```bash
# Skills that have been removed in favour of better names
DEPRECATED=(
  orbit-init                # → renamed to orbit-setup
  # ...future renames go here
)

for skill in "${DEPRECATED[@]}"; do
  if [ -L "$HOME/.claude/skills/$skill" ] || [ -d "$HOME/.claude/skills/$skill" ]; then
    rm -rf "$HOME/.claude/skills/$skill"
    echo "✓ Removed deprecated: $skill"
  fi
done
```

Print only if anything was actually removed.

---

## HARD RULES

- **Never ask the user anything.** Zero-question skill. If anything fails, give a 1-line fix — never a stack trace.
- **Never touch qa.config.json, reports/, .auth/, or wp-env containers.** This is just refreshing the Orbit code.
- **Never suggest a full reinstall** unless the install script returns non-zero AND its error literally says reinstall is needed.
- **Pass through all install.sh output verbatim** — the script self-prints version numbers and progress.
- **Safe to run repeatedly.** If already on latest, exit cleanly with the "already latest" message.
- **Don't run `git stash` or `git reset`** — if the user has local changes, surface them in the output and stop. Never silently discard their work.
