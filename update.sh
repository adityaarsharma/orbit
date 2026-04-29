#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
#  🪐  Orbit — Updater
#  WordPress Plugin QA Framework · github.com/adityaarsharma/orbit
#
#  Usage:
#    bash update.sh                    — pull latest + refresh skills
#    bash update.sh --check            — check for updates without applying
#
#  Or, if Orbit is on disk and you want a clean update:
#    cd ~/Claude/orbit && git pull && bash install.sh --update
# ══════════════════════════════════════════════════════════════
set -e

CHECK_ONLY=0
[ "${1:-}" = "--check" ] && CHECK_ONLY=1

ORBIT_HOME_DEFAULT="$HOME/Claude/orbit"
REPO_URL="https://github.com/adityaarsharma/orbit.git"

# ── Find Orbit ──────────────────────────────────────────────────
if [ -f "./install.sh" ] && [ -d "./skills/orbit" ]; then
  ORBIT_HOME="$(pwd -P)"
elif [ -d "$ORBIT_HOME_DEFAULT/.git" ]; then
  ORBIT_HOME="$ORBIT_HOME_DEFAULT"
else
  echo "❌ Orbit not found at $ORBIT_HOME_DEFAULT or current directory"
  echo "   Install first:"
  echo "     curl -fsSL https://raw.githubusercontent.com/adityaarsharma/orbit/main/install.sh | bash"
  exit 1
fi

cd "$ORBIT_HOME"

echo ""
echo "════════════════════════════════════════════════════"
echo "  🪐  Orbit Updater"
echo "════════════════════════════════════════════════════"
echo ""

# ── Capture old version ─────────────────────────────────────────
OLD_VERSION=$(git describe --tags --always 2>/dev/null || echo "unknown")
echo "Current version: $OLD_VERSION"

# ── Fetch latest ────────────────────────────────────────────────
echo ""
echo "⏳ Checking for updates..."
git fetch --tags --quiet
LATEST=$(git rev-parse origin/main 2>/dev/null || git rev-parse origin/master 2>/dev/null)
CURRENT=$(git rev-parse HEAD)

if [ "$LATEST" = "$CURRENT" ]; then
  echo "✓ Already on the latest version ($OLD_VERSION). Nothing to do."
  exit 0
fi

# ── Show what's new ─────────────────────────────────────────────
echo ""
echo "Updates available. Recent commits:"
git log --oneline HEAD..origin/main 2>/dev/null | head -10 \
  || git log --oneline HEAD..origin/master 2>/dev/null | head -10

if [ $CHECK_ONLY -eq 1 ]; then
  echo ""
  echo "Run 'bash update.sh' (no flags) to apply."
  exit 0
fi

# ── Check for local changes ─────────────────────────────────────
if ! git diff --quiet || ! git diff --cached --quiet; then
  echo ""
  echo "⚠  You have local changes in $ORBIT_HOME"
  echo "   The update will rebase on top of upstream. If anything"
  echo "   conflicts, the rebase will pause for you to resolve."
  echo ""
  read -p "Continue? (y/N) " ans
  [ "$ans" != "y" ] && [ "$ans" != "Y" ] && { echo "Aborted."; exit 1; }
fi

# ── Pull ────────────────────────────────────────────────────────
echo ""
echo "⏳ Pulling latest..."
git pull --rebase --quiet || {
  echo "❌ Pull failed — likely a rebase conflict."
  echo "   Resolve manually:"
  echo "     cd $ORBIT_HOME"
  echo "     git rebase --abort  (to undo)"
  echo "     # or fix conflicts then: git rebase --continue"
  exit 1
}

NEW_VERSION=$(git describe --tags --always 2>/dev/null || echo "main")
echo "$NEW_VERSION" > "$ORBIT_HOME/.orbit_version"

# ── Refresh skill symlinks ──────────────────────────────────────
echo ""
echo "⏳ Refreshing skill symlinks..."
bash "$ORBIT_HOME/install.sh" --update

# ── Final ───────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════════"
echo "  ✅  Updated $OLD_VERSION → $NEW_VERSION"
echo "════════════════════════════════════════════════════"
echo ""
echo "Skill changes are live immediately."
echo "No restart needed unless an MCP server changed."
echo ""
echo "View what's new:"
echo "  cat $ORBIT_HOME/CHANGELOG.md | head -50"
echo ""

exit 0
