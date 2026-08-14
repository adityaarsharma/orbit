#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════
#  🪐  Orbit — One-line installer
#  WordPress Plugin QA Framework · github.com/adityaarsharma/orbit
#
#  Usage (paste into Claude Code or your terminal):
#    curl -fsSL https://raw.githubusercontent.com/adityaarsharma/orbit/main/install.sh | bash
#
#  Or, if Orbit is already cloned, run from the repo root:
#    bash install.sh
#
#  Flags:
#    --update        Refresh symlinks + remove deprecated, no prompts
#    --agents-only   Install agents only — skip all skill symlinks (saved as preference)
#    --skills-only   Skip the power-tools install (just symlink skills)
#    --help          Print this help
# ══════════════════════════════════════════════════════════════
set -e

# ── Args ────────────────────────────────────────────────────────
UPDATE_MODE=0
SKILLS_ONLY=0
AGENTS_ONLY=0
for arg in "$@"; do
  case "$arg" in
    --update) UPDATE_MODE=1 ;;
    --skills-only) SKILLS_ONLY=1 ;;
    --agents-only) AGENTS_ONLY=1 ;;
    --help|-h)
      head -25 "$0" | grep -E '^#' | sed 's/^# //;s/^#//'
      exit 0
      ;;
  esac
done

# Load saved agents-only preference (set once via --agents-only, persists across --update runs)
[ -f "$HOME/.orbit/.agents-only" ] && AGENTS_ONLY=1

# ── Constants ───────────────────────────────────────────────────
SKILLS_DIR="$HOME/.claude/skills"
AGENTS_DIR="$HOME/.claude/agents"
ORBIT_HOME_DEFAULT="$HOME/Claude/orbit"
ORBIT_KEYS_FILE="$HOME/.orbit/keys.env"
CLAUDE_SETTINGS="$HOME/.claude/settings.json"
REPO_URL="https://github.com/adityaarsharma/orbit.git"

# ── Header ──────────────────────────────────────────────────────
if [ $UPDATE_MODE -eq 0 ]; then
  cat <<'HEADER'

════════════════════════════════════════════════════
  🪐  Orbit — WordPress Plugin QA Framework
════════════════════════════════════════════════════

  Installing 11 AI agents + 116 /orbit-* skills:

  Agents (talk to these in Claude Code):
    orbit-cto           Strategic advisor — tech direction, competitor intel
    orbit-pm            Coordinator — RICE, routing, sprint health
    orbit-code-reviewer PHP + Gutenberg + Elementor + compat review
    orbit-senior-dev    Builds features, fixes bugs
    orbit-dev-designer  WCAG, RTL, dark mode, empty states
    orbit-uat           Playwright E2E, visual regression, severity triage
    orbit-perf          Hook weight, DB queries, Lighthouse budgets
    orbit-security      XSS/SQLi/CSRF, CVE, payments, GDPR
    orbit-release       7-step gate, WP.org, zip hygiene, announce
    orbit-docs          README, API hooks, freshness, changelog
    orbit-runner        Automated shell runner — WP-CLI, Docker matrix, auto-fix

  Key skills (agents invoke these automatically):
    /orbit-wp-standards     /orbit-wp-security    /orbit-lighthouse
    /orbit-playwright       /orbit-release-gate   /orbit-plugin-check
    /orbit-accessibility    /orbit-cve-check      /orbit-gdpr
    ... and 107 more

  Repo:    github.com/adityaarsharma/orbit
  License: GPL-2.0+ (open source)
  Author:  the maintainers

════════════════════════════════════════════════════

HEADER
fi

# ── Resolve ORBIT_HOME ──────────────────────────────────────────
# If we're already inside the repo, use it. Otherwise clone.
if [ -f "./install.sh" ] && [ -d "./skills/orbit" ]; then
  ORBIT_HOME="$(pwd -P)"
  if [ $UPDATE_MODE -eq 1 ]; then
    echo "⏳ [1/4] Pulling latest from GitHub..."
    git -C "$ORBIT_HOME" fetch --tags --quiet
    git -C "$ORBIT_HOME" pull --rebase --quiet
    echo "   ✓ Pulled latest"
  else
    echo "⏳ [1/4] Using local repo at $ORBIT_HOME"
  fi
elif [ -d "$ORBIT_HOME_DEFAULT/.git" ]; then
  ORBIT_HOME="$ORBIT_HOME_DEFAULT"
  echo "⏳ [1/4] Found existing Orbit at $ORBIT_HOME — pulling latest..."
  git -C "$ORBIT_HOME" fetch --tags --quiet
  git -C "$ORBIT_HOME" pull --rebase --quiet
  echo "   ✓ Pulled latest"
else
  ORBIT_HOME="$ORBIT_HOME_DEFAULT"
  echo "⏳ [1/4] Cloning Orbit to $ORBIT_HOME..."
  mkdir -p "$(dirname "$ORBIT_HOME")"
  git clone --depth 1 --quiet "$REPO_URL" "$ORBIT_HOME"
  echo "   ✓ Cloned"
fi

# ── Capture version ─────────────────────────────────────────────
ORBIT_VERSION=$(git -C "$ORBIT_HOME" describe --tags --always 2>/dev/null || echo "main")
echo "$ORBIT_VERSION" > "$ORBIT_HOME/.orbit_version"

# ── Save agents-only preference ─────────────────────────────────
if [ $AGENTS_ONLY -eq 1 ]; then
  mkdir -p "$HOME/.orbit"
  touch "$HOME/.orbit/.agents-only"
fi

# ── Install skills (symlinks for live updates) ──────────────────
INSTALLED=0
if [ $AGENTS_ONLY -eq 0 ]; then
  echo ""
  echo "⏳ [2/4] Installing /orbit-* skills to ~/.claude/skills/..."
  mkdir -p "$SKILLS_DIR"

  for skill_path in "$ORBIT_HOME/skills/"orbit*; do
    skill=$(basename "$skill_path")
    [ -f "$skill_path/SKILL.md" ] || continue

    # Remove existing entry (symlink or directory) so we can re-link cleanly
    if [ -L "$SKILLS_DIR/$skill" ] || [ -d "$SKILLS_DIR/$skill" ]; then
      rm -rf "$SKILLS_DIR/$skill"
    fi

    # Symlink so /orbit-update gets fresh content automatically
    ln -s "$skill_path" "$SKILLS_DIR/$skill"
    INSTALLED=$((INSTALLED + 1))
  done

  echo "   ✓ Linked $INSTALLED skills"
  SKILLS_PURGED=0
else
  echo ""
  echo "⏳ [2/4] Agents-only mode — removing any existing orbit-* skill symlinks..."
  SKILLS_PURGED=0
  if [ -d "$SKILLS_DIR" ]; then
    for existing in "$SKILLS_DIR"/orbit-*; do
      if [ -L "$existing" ] || [ -d "$existing" ]; then
        rm -rf "$existing"
        SKILLS_PURGED=$((SKILLS_PURGED + 1))
      fi
    done
  fi
  if [ $SKILLS_PURGED -gt 0 ]; then
    echo "   ✓ Removed $SKILLS_PURGED orbit-* skill symlink(s) from ~/.claude/skills/"
  else
    echo "   ✓ No orbit-* skills found — palette already clean"
  fi
fi

# ── Install agents (symlinks for live updates) ──────────────────
echo ""
echo "⏳ [2b] Installing 11 Orbit agents to ~/.claude/agents/..."
mkdir -p "$AGENTS_DIR"

AGENTS_INSTALLED=0
for agent_path in "$ORBIT_HOME/agents/"orbit-*.md; do
  agent=$(basename "$agent_path")
  [ -f "$agent_path" ] || continue

  # Remove existing entry so we can re-link cleanly
  if [ -L "$AGENTS_DIR/$agent" ] || [ -f "$AGENTS_DIR/$agent" ]; then
    rm -f "$AGENTS_DIR/$agent"
  fi

  # Symlink so /orbit-update gets fresh agent content automatically
  ln -s "$agent_path" "$AGENTS_DIR/$agent"
  AGENTS_INSTALLED=$((AGENTS_INSTALLED + 1))
done

echo "   ✓ Linked $AGENTS_INSTALLED agents (orbit-cto through orbit-runner)"

# ── Remove old agent symlinks (v2.x 12-agent model + v3.x numeric prefix) ──
OLD_ORBIT_AGENTS=(
  # v2.x 12-agent model
  "01-qa-lead.md"   "02-security.md"   "03-performance.md"
  "04-gutenberg.md" "05-elementor.md"  "06-designer.md"
  "07-release.md"   "08-compat.md"     "09-test-auto.md"
  "10-pm.md"        "11-compliance.md" "12-seo-docs.md"
  # v3.x numeric-prefix names (renamed to orbit-* in v3.4.0)
  "00-cto.md"       "01-pm.md"         "02-code-reviewer.md"
  "03-senior-dev.md" "04-dev-designer.md" "05-uat.md"
  "06-performance.md" "07-security.md"  "08-release.md"
  "09-docs.md"
  # orbit-*-agent.md names (renamed to orbit-*.md in the general release)
  "orbit-cto-agent.md"        "orbit-pm-agent.md"        "orbit-code-reviewer-agent.md"
  "orbit-senior-dev-agent.md" "orbit-dev-designer-agent.md" "orbit-uat-agent.md"
  "orbit-perf-agent.md"       "orbit-security-agent.md"  "orbit-release-agent.md"
  "orbit-docs-agent.md"       "orbit-runner-agent.md"
)
AGENTS_REMOVED=0
for old_agent in "${OLD_ORBIT_AGENTS[@]}"; do
  if [ -L "$AGENTS_DIR/$old_agent" ] || [ -f "$AGENTS_DIR/$old_agent" ]; then
    rm -f "$AGENTS_DIR/$old_agent"
    AGENTS_REMOVED=$((AGENTS_REMOVED + 1))
  fi
done
[ $AGENTS_REMOVED -gt 0 ] && echo "   ✓ Removed $AGENTS_REMOVED stale agent(s) (old 12-agent model)"

# ── Purge broken symlinks in agents + skills dirs ───────────────
BROKEN_AGENTS=$(find "$AGENTS_DIR" -maxdepth 1 -name "*.md" -xtype l 2>/dev/null | wc -l | tr -d ' ')
find "$AGENTS_DIR" -maxdepth 1 -name "*.md" -xtype l -delete 2>/dev/null || true
BROKEN_SKILLS=$(find "$SKILLS_DIR" -maxdepth 1 -name "orbit-*" -xtype l 2>/dev/null | wc -l | tr -d ' ')
find "$SKILLS_DIR" -maxdepth 1 -name "orbit-*" -xtype l -delete 2>/dev/null || true
[ "$BROKEN_AGENTS" -gt 0 ] 2>/dev/null && echo "   ✓ Cleaned $BROKEN_AGENTS broken agent symlink(s)" || true
[ "$BROKEN_SKILLS" -gt 0 ] 2>/dev/null && echo "   ✓ Cleaned $BROKEN_SKILLS broken skill symlink(s)" || true

# ── Remove deprecated skills ────────────────────────────────────
REMOVED=0
if [ $AGENTS_ONLY -eq 0 ]; then
  DEPRECATED=(
    orbit-init           # → orbit-setup (renamed in v2.5)
  )
  for skill in "${DEPRECATED[@]}"; do
    if [ -L "$SKILLS_DIR/$skill" ] || [ -d "$SKILLS_DIR/$skill" ]; then
      rm -rf "$SKILLS_DIR/$skill"
      echo "   ✓ Removed deprecated: $skill"
      REMOVED=$((REMOVED + 1))
    fi
  done
fi

# ── WordPress/agent-skills (official WP core agent skills) ─────
if [ $UPDATE_MODE -eq 0 ] && [ $SKILLS_ONLY -eq 0 ] && [ $AGENTS_ONLY -eq 0 ]; then
  echo ""
  echo "⏳ [3a] Installing WordPress/agent-skills (official WP core skills)..."
  echo "   wp-playground gives AI agents a fast WP feedback loop."
  echo "   Source: github.com/WordPress/agent-skills"
  echo ""
  if command -v npx >/dev/null 2>&1; then
    npx -y openskills install WordPress/agent-skills 2>/dev/null && {
      npx -y openskills sync 2>/dev/null || true
      echo "   ✓ WordPress/agent-skills installed"
    } || {
      echo "   ⚠ Couldn't install WordPress/agent-skills (network or npm issue)."
      echo "     Re-try later: npx openskills install WordPress/agent-skills"
    }
  else
    echo "   ⚠ npx not found — install Node.js to use WordPress/agent-skills"
  fi
fi

# ── Power tools (skipped on --update, --skills-only, or --agents-only) ──────────
if [ $UPDATE_MODE -eq 0 ] && [ $SKILLS_ONLY -eq 0 ] && [ $AGENTS_ONLY -eq 0 ]; then
  echo ""
  echo "⏳ [3/4] Installing power tools (PHPCS / Playwright / Lighthouse / wp-env)..."
  echo "   This is the longest step — about 3-5 minutes on first install."
  echo "   While we wait: /orbit-install can re-run individual tools later."
  echo ""

  if [ -x "$ORBIT_HOME/setup/install.sh" ]; then
    bash "$ORBIT_HOME/setup/install.sh" || {
      echo "   ⚠  Power-tools install hit an error."
      echo "      Skills are installed. Re-run later: /orbit-install"
    }
  else
    echo "   ⚠  setup/install.sh not found in repo. Skills are installed."
    echo "      Run /orbit-install to set up power tools manually."
  fi
else
  if [ $UPDATE_MODE -eq 1 ]; then SKIP_REASON="update mode"
  elif [ $AGENTS_ONLY -eq 1 ]; then SKIP_REASON="agents-only mode"
  else SKIP_REASON="skills-only mode"; fi
  echo ""
  echo "⏳ [3/4] Skipping power tools ($SKIP_REASON)"
fi

# ── Restart Claude Code (macOS — picks up new agents + MCP) ────
# Only auto-restart if we just changed something that needs it:
# - agents were re-linked (always on update)
# - brain connector was just added
NEEDS_RESTART=0
[ $AGENTS_INSTALLED -gt 0 ] && NEEDS_RESTART=1
[ $SKILLS_PURGED -gt 0 ] && NEEDS_RESTART=1

# Build restart reason for messaging
RESTART_REASON="updated agents"
[ $SKILLS_PURGED -gt 0 ] && [ $AGENTS_INSTALLED -gt 0 ] && RESTART_REASON="updated agents + removed $SKILLS_PURGED skill(s)"
[ $SKILLS_PURGED -gt 0 ] && [ $AGENTS_INSTALLED -eq 0 ] && RESTART_REASON="removed $SKILLS_PURGED skill(s) from palette"

if [ $NEEDS_RESTART -eq 1 ] && [[ "$OSTYPE" == "darwin"* ]]; then
  # Check if Claude Code is actually running
  if pgrep -x "Claude" > /dev/null 2>&1; then
    echo ""
    echo "🔄 Restarting Claude Code ($RESTART_REASON)..."
    osascript -e 'quit app "Claude"' 2>/dev/null || pkill -x "Claude" 2>/dev/null || true
    sleep 3
    open -a "Claude" 2>/dev/null && echo "   ✓ Claude Code restarted" || \
      echo "   ⚠  Couldn't relaunch — open Claude Code manually"
  else
    echo ""
    echo "   ℹ  Open Claude Code now to pick up changes ($RESTART_REASON)"
  fi
elif [ $NEEDS_RESTART -eq 1 ]; then
  echo ""
  echo "   ℹ  Restart Claude Code to apply changes ($RESTART_REASON)"
fi

# ── Closing ─────────────────────────────────────────────────────
echo ""
echo "⏳ [4/4] Wrapping up..."
echo ""

# Pre-compute skills summary line for footer
if [ $AGENTS_ONLY -eq 0 ]; then
  SKILLS_SUMMARY="  Skills installed:    $INSTALLED  (~/.claude/skills/)
  Skills removed:      $REMOVED (deprecated)"
elif [ $SKILLS_PURGED -gt 0 ]; then
  SKILLS_SUMMARY="  Skills purged:       $SKILLS_PURGED (removed from ~/.claude/skills/ — agents-only mode)"
else
  SKILLS_SUMMARY="  Skills:              none (agents-only mode)"
fi

cat <<FOOTER
════════════════════════════════════════════════════
  ✅  Orbit installed — $ORBIT_VERSION
════════════════════════════════════════════════════

  Agents installed:    $AGENTS_INSTALLED  (~/.claude/agents/)
  Agents removed:      $AGENTS_REMOVED (old 12-agent model)
$SKILLS_SUMMARY
  Repo:                $ORBIT_HOME

────────────────────────────────────────────────────
  Next steps
────────────────────────────────────────────────────

FOOTER

if [ $UPDATE_MODE -eq 0 ]; then
  cat <<'NEXT'
  1. Fully quit Claude Code (Cmd+Q on Mac) and reopen
  2. Talk to an agent:   "UAT audit my-plugin v2.5"
                         "Security scan the ajax handler in settings.php"
                         "CTO brief — Elementor just shipped X"
                         "Run release gate for my-plugin v2.5"



  Or use skills directly (no brain key needed):
     /orbit-setup            Guided wizard for your first plugin
     /orbit-do-it            Brainless full audit
     /orbit-release-gate     7-step release gate

  Onboarding:  ~/Claude/orbit/docs/onboarding-by-role.md
  All agents:  ~/.claude/agents/orbit-cto.md … orbit-runner.md
  All skills:  ~/Claude/orbit/SKILLS.md

  Update later:    bash install.sh --update  (refreshes agents + skills + MCPs)

NEXT
else
  cat <<'NEXTUPDATE'
  ⚡ Skill text changes: live immediately — no restart needed.
  🔄 Agent changes:      fully quit Claude Code (Cmd+Q) and reopen.

  Verify:        /orbit
  See changes:   git -C ~/Claude/orbit log --oneline -10

  Agents active (~/.claude/agents/):
    orbit-cto  orbit-pm  orbit-code-reviewer  orbit-senior-dev  orbit-dev-designer
    orbit-uat  orbit-perf  orbit-security  orbit-release  orbit-docs  orbit-runner

NEXTUPDATE
fi

cat <<'OUTRO'
────────────────────────────────────────────────────
  🪐  Built by the maintainers
  github.com/adityaarsharma/orbit
════════════════════════════════════════════════════

OUTRO

exit 0
