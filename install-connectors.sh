#!/usr/bin/env bash
# Orbit Connector Installer — brain-posimyth sub-endpoints (v3.3.1)
#
# Usage:
#   bash install-connectors.sh <BRAIN_KEY>
#
# What it does:
#   1. Validates key against brain.posimyth.com — auto-detects tier (team / admin)
#   2. STALE CLEANUP — removes ONLY known pre-posi era stdio MCPs
#      NEVER removes: -posi MCPs (shared with Golden Circle), -orbit MCPs,
#      brain-orbit, brain-aditya, or any personal MCP
#   3. Registers all 7 Orbit MCPs for BOTH configs:
#        Claude Code   (~/.claude/settings.json)        → native HTTP type
#        Claude Desktop (claude_desktop_config.json)    → mcp-remote stdio bridge
#   4. Live verification — initialize handshake + tool count per endpoint
#   5. Bridge smoke-test — confirms mcp-remote binary available + Desktop MCPs will start
#   6. Prints summary + restart instructions
#
# Tiers:
#   team   → read access to all 7 Orbit MCPs
#   admin  → read + write access to all 7 Orbit MCPs (write enforced server-side)
#
# SHARED POOL: -posi MCPs are shared between Orbit and Golden Circle.
#   Running this installer never removes Golden Circle's -posi MCPs.
#   Running the GC installer never removes Orbit's MCPs.
#   Both coexist on the same machine without conflict.
#
# Safe to re-run. Idempotent. Backs up configs to *.orbit-install.bak.

set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Cross-platform npx detection — runs once at install
# Order: shell PATH → Apple Silicon Homebrew → Intel Homebrew → Linux apt → nvm → fail
#
# WHY: macOS GUI apps (Claude Desktop) don't inherit the shell PATH, so writing
# bare "npx" into claude_desktop_config.json silently fails at startup.
# Using the absolute path returned here fixes the "MCP could not be loaded" error.
# ─────────────────────────────────────────────────────────────────────────────
detect_npx() {
  local candidates=(
    "$(command -v npx 2>/dev/null || true)"
    "/opt/homebrew/bin/npx"      # Apple Silicon Mac (M1+)
    "/usr/local/bin/npx"          # Intel Mac / older Homebrew
    "/usr/bin/npx"                # Linux apt / most distros
    "$HOME/.nvm/versions/node/$(node -v 2>/dev/null)/bin/npx"  # nvm
  )
  for c in "${candidates[@]}"; do
    if [[ -n "$c" && -x "$c" ]]; then
      echo "$c"
      return 0
    fi
  done
  return 1
}

NPX_PATH=$(detect_npx) || {
  echo "✗ npx not found. Install Node.js first:"
  echo "  macOS:  brew install node"
  echo "  Linux:  sudo apt install nodejs npm"
  exit 1
}
echo "  ✓ npx detected at: $NPX_PATH"
export NPX_PATH

# Pre-warm mcp-remote so Claude Desktop connects instantly (not 5–15s on first use)
echo "  → Pre-warming mcp-remote npm cache..."
if "$NPX_PATH" -y mcp-remote --help >/dev/null 2>&1; then
  echo "  ✓ mcp-remote cached (Desktop MCPs will start instantly)"
else
  echo "  ⚠ mcp-remote pre-warm failed — Desktop will fetch it on first MCP use"
fi

KEY="${1:-}"
if [[ -z "$KEY" ]]; then
  cat <<EOF
Orbit Connector Installer (v3.3.1)
─────────────────────────────────────────────────────────
Usage:  bash install-connectors.sh <BRAIN_KEY>

2 tiers:
  • team   → read access to all 7 Orbit MCPs
  • admin  → read + write access (write enforced server-side)

Get a key from the POSIMYTH admin or see docs/team-access.md
─────────────────────────────────────────────────────────
EOF
  exit 1
fi

POSIMYTH_BASE="https://brain.posimyth.com"

# ─── Orbit MCPs: name:path:min_tier ──────────────────────────────────────────
# 10 MCPs — no umbrella, no duplicate tools.
# brain-posi (/brain/mcp) replaces brain-posimyth (/connectors) — memory only, no duplication.
# Both team and admin get all 10 — write access is enforced server-side, not here.
SERVICES=(
  "brain-posi:/brain/mcp:team"
  "fluentsupport-posi:/fluentsupport/mcp:team"
  "apify-posi:/apify/mcp:team"
  "wp-tpae-posi:/wp-tpae/mcp:team"
  "wp-nexterwp-posi:/wp-nexterwp/mcp:team"
  "sproutai-blog-posi:/sproutai-blog/mcp:team"
  "ga4-posi:/ga4/mcp:team"
  "gsc-posi:/gsc/mcp:team"
  "discord-guti-posi:/discord-guti/mcp:team"
  "gplvault-cache-posi:/gplvault-cache/mcp:team"
)

# ─── Personal/general MCPs — NEVER touched ───────────────────────────────────
PERSONAL_KEEP=(
  "apple-mail" "playwright" "github" "context7"
  "n8n-mcp" "youtube-analytics" "slack-aditya"
  "Aditya's Desktop"
  # brain-aditya left alone if present — handled separately in cleanup logic
)

tier_rank() {
  case "$1" in
    team)  echo 1 ;;
    admin) echo 2 ;;
    *)     echo 0 ;;
  esac
}

# ─── 1. Validate key + detect tier ───────────────────────────────────────────
echo ""
echo "→ Validating key against brain.posimyth.com..."
WHOAMI=$(curl -sf -H "Authorization: Bearer $KEY" "${POSIMYTH_BASE}/connectors/whoami" 2>/dev/null || echo '{}')
TIER=$(echo "$WHOAMI" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tier',''))" 2>/dev/null || echo "")

if [[ -z "$TIER" ]]; then
  echo "✗ Key rejected or brain unreachable."
  echo "  Confirm with the POSIMYTH admin or check:"
  echo "  curl -H 'Authorization: Bearer \$KEY' ${POSIMYTH_BASE}/connectors/whoami"
  exit 1
fi

MY_RANK=$(tier_rank "$TIER")
if [[ "$MY_RANK" -eq 0 ]]; then
  echo "✗ Tier '$TIER' not recognized. Expected: team or admin."
  echo "  Contact the POSIMYTH admin for a valid Orbit key."
  exit 1
fi

echo "✓ Key valid — tier: $TIER"

# ─── Build allowed list for this tier ────────────────────────────────────────
ALLOWED=()
for entry in "${SERVICES[@]}"; do
  IFS=':' read -r name path min_tier <<< "$entry"
  if [[ "$(tier_rank "$min_tier")" -le "$MY_RANK" ]]; then
    ALLOWED+=("$name:$path")
  fi
done
echo "  Endpoints for this tier: ${#ALLOWED[@]} / ${#SERVICES[@]}"

# ─── 2 + 3. Stale cleanup + register ─────────────────────────────────────────
#
# SHARED MCP POOL RULES (critical — do not change these guards):
#   -posi suffix   → shared between Orbit and Golden Circle — NEVER removed by either
#   -orbit suffix  → reserved for future Orbit-native endpoints — NEVER removed
#   brain-orbit    → Orbit umbrella MCP — NEVER removed
#   brain-aditya   → personal umbrella MCP — NEVER removed
#   PERSONAL_KEEP  → user's personal MCPs — NEVER removed
#   STALE_OLD_NAMES → pre-posi era stdio names — ONLY these are removed
#
update_config() {
  local cfg_path="$1"
  local label="$2"
  local client="$3"   # "code" or "desktop"

  if [[ ! -f "$cfg_path" ]]; then
    mkdir -p "$(dirname "$cfg_path")"
    echo '{}' > "$cfg_path"
  fi

  # Backup before any write
  cp "$cfg_path" "${cfg_path}.orbit-install.bak"

  local personal_str=""
  for p in "${PERSONAL_KEEP[@]}"; do
    personal_str="${personal_str}${p},"
  done

  python3 - "$cfg_path" "$KEY" "$POSIMYTH_BASE" "$client" "$label" \
    "$personal_str" "${ALLOWED[@]}" <<'PYEOF'
import json, sys, os

path, key, base, client, label = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5]
personal = set(n for n in sys.argv[6].split(',') if n)
services  = sys.argv[7:]

# Names safe to remove — pre-posi era stdio MCPs + legacy umbrella
# brain-posimyth (/connectors) duplicates every per-service tool — removed in v3.3.0
STALE_OLD_NAMES = {
    "fluentcrm", "wp-theplusaddons", "wp-nexterwp", "wp-uichemy",
    "ga4", "gsc", "dataforseo", "apify", "snov", "ocoya",
    "generatebanners", "meta-ads", "clickup-dora", "discord-guti",
    "fluentsupport", "plausible", "edd-store", "sproutai-blog",
    "wp-tpae", "wp-nexter", "wp-store",
    "brain-posimyth",   # legacy umbrella — duplicates all per-service tools
}

with open(path) as f:
    cfg = json.load(f)
cfg.setdefault("mcpServers", {})

# STALE CLEANUP — only remove known old stdio names
# Guards (in priority order):
#   1. personal list        — user's own MCPs, never touched
#   2. brain-aditya         — personal umbrella, never touched
#   3. brain-orbit          — Orbit umbrella, never touched
#   4. ends with -posi      — GC/Orbit shared pool, never touched by either installer
#   5. ends with -orbit     — Orbit future pool, never touched
#   6. in STALE_OLD_NAMES   — pre-posi era: remove
#   else: leave as-is
removed = []
for name in list(cfg["mcpServers"].keys()):
    if name in personal:
        continue
    if name in ("brain-aditya", "brain-orbit"):
        continue
    if name.endswith("-posi"):
        continue
    if name.endswith("-orbit"):
        continue
    if name in STALE_OLD_NAMES:
        removed.append(name)
        del cfg["mcpServers"][name]

# Register/update allowed endpoints (upsert — all other entries untouched)
# CRITICAL for Desktop: use absolute NPX_PATH, not bare "npx".
# macOS GUI apps don't inherit the shell PATH — bare "npx" silently fails at startup.
npx_path = os.environ.get("NPX_PATH") or "/opt/homebrew/bin/npx"

for s in services:
    name, sub = s.split(':', 1)
    url = base + sub
    if client == "code":
        cfg["mcpServers"][name] = {
            "type": "http",
            "url": url,
            "headers": {"Authorization": f"Bearer {key}"}
        }
    else:
        # Claude Desktop — mcp-remote stdio bridge
        cfg["mcpServers"][name] = {
            "command": npx_path,
            "args": ["-y", "mcp-remote", url, "--header", f"Authorization: Bearer {key}"]
        }

# Atomic write — prevents partial-write corruption on interrupted installs
tmp = path + '.tmp'
with open(tmp, 'w') as f:
    json.dump(cfg, f, indent=2)
os.replace(tmp, path)

total_posi = sum(1 for n in cfg["mcpServers"] if n.endswith("-posi"))
print(f"  {label}:")
print(f"    ✓ {len(services)} Orbit MCPs registered/updated")
print(f"    ✓ {total_posi} total -posi MCPs in config (Orbit + GC shared pool)")
if removed:
    print(f"    ✓ {len(removed)} stale old-style MCP(s) removed: {', '.join(removed)}")
else:
    print(f"    ✓ no stale MCPs found")
PYEOF
}

CLAUDE_CODE="$HOME/.claude/settings.json"
CLAUDE_DESKTOP="$HOME/Library/Application Support/Claude/claude_desktop_config.json"

echo ""
echo "→ Cleaning up + registering MCPs..."
update_config "$CLAUDE_CODE" "Claude Code" "code"

if [[ "$(uname -s)" == "Darwin" ]]; then
  mkdir -p "$(dirname "$CLAUDE_DESKTOP")"
  update_config "$CLAUDE_DESKTOP" "Claude Desktop" "desktop"
fi

# ─── 4. Live verification ─────────────────────────────────────────────────────
echo ""
echo "→ Live verification (initialize handshake + tool count):"

TOTAL_TOOLS=0
HEALTHY=0
FAILED=0

for s in "${ALLOWED[@]}"; do
  IFS=':' read -r name sub <<< "$s"
  url="${POSIMYTH_BASE}${sub}"

  # MCP initialize handshake — the one that breaks Claude Desktop when missing
  INIT_OK=$(curl -s -X POST \
    -H "Authorization: Bearer $KEY" \
    -H "Content-Type: application/json" \
    "$url" \
    -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"orbit-installer","version":"3.3.0"}}}' \
    | python3 -c "import json,sys; d=json.load(sys.stdin); print('yes' if d.get('result',{}).get('serverInfo') else 'no')" \
    2>/dev/null || echo "no")

  # Tool count
  COUNT=$(curl -s -X POST \
    -H "Authorization: Bearer $KEY" \
    -H "Content-Type: application/json" \
    "$url" \
    -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' \
    | python3 -c "import json,sys; print(len(json.load(sys.stdin).get('result',{}).get('tools',[])))" \
    2>/dev/null || echo "0")

  if [[ "$INIT_OK" == "yes" && "$COUNT" -gt 0 ]]; then
    STATUS="✓"
    HEALTHY=$((HEALTHY + 1))
    TOTAL_TOOLS=$((TOTAL_TOOLS + COUNT))
  else
    STATUS="✗"
    FAILED=$((FAILED + 1))
  fi
  printf "  %s %-24s  init=%-3s  tools=%s\n" "$STATUS" "$name" "$INIT_OK" "$COUNT"
done

# ─── 5. Bridge smoke-test ─────────────────────────────────────────────────────
# Confirms the mcp-remote binary is functional before user restarts Claude Desktop.
echo ""
echo "→ Bridge smoke-test (Desktop startup check)..."
if "$NPX_PATH" mcp-remote --version >/dev/null 2>&1; then
  echo "  ✓ mcp-remote at $NPX_PATH — Claude Desktop bridge ready"
else
  echo "  ⚠ mcp-remote version check inconclusive — Desktop MCPs should still work after restart"
fi

# ─── 6. Summary ───────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════════════"
echo "  ✓ ORBIT CONNECTORS INSTALLED"
echo "════════════════════════════════════════════════════════"
echo "  Tier:               $TIER"
echo "  MCPs registered:    ${#ALLOWED[@]} ($HEALTHY healthy, $FAILED failed)"
echo "  Total tools:        $TOTAL_TOOLS"
echo "  Stale MCPs:         scrubbed from Claude Code + Desktop"
echo "  Personal MCPs:      preserved (brain-aditya, github, apple-mail, etc.)"
echo "  GC MCPs:            untouched (-posi shared pool preserved)"
echo ""
echo "  Backups (rollback if needed):"
echo "    cp ${CLAUDE_CODE}.orbit-install.bak ${CLAUDE_CODE}"
[[ "$(uname -s)" == "Darwin" ]] && echo "    cp \"${CLAUDE_DESKTOP}.orbit-install.bak\" \"${CLAUDE_DESKTOP}\""
echo ""
echo "  ⚠ RESTART REQUIRED:"
echo "    1. Quit Claude Code completely   (Cmd+Q — not just close window)"
echo "    2. Quit Claude Desktop           (Cmd+Q)"
echo "    3. Reopen both"
echo "    4. Test: 'what tools do I have?' — should see ${#ALLOWED[@]} Orbit MCPs"
if [[ "$FAILED" -gt 0 ]]; then
  echo ""
  echo "  ⚠ $FAILED endpoint(s) failed verification."
  echo "    Check brain.posimyth.com is reachable and your key is valid."
fi
echo "════════════════════════════════════════════════════════"
