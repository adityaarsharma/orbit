#!/usr/bin/env bash
# Orbit Connector Installer — brain-posimyth sub-endpoints (v3.1.2)
#
# Usage:
#   bash install-connectors.sh <BRAIN_KEY>
#
# What it does:
#   1. Validates key against brain.posimyth.com — auto-detects tier
#   2. WHITELIST CLEANUP — removes ANY stale MCP that's not:
#        a) one of the Orbit -posi connectors (we register these)
#        b) on the personal-keep list (apple-mail, playwright, github,
#           context7, brain-aditya, slack-* — never touched)
#      This prevents the "corrupted MCP config" problem after re-installs
#   3. Registers Orbit MCPs for BOTH configs:
#        Claude Code  (~/.claude/settings.json)   → native HTTP type
#        Claude Desktop (claude_desktop_config.json) → mcp-remote bridge
#   4. Live verification — initialize handshake + tool count per endpoint
#   5. Prints summary + restart instructions
#
# Tiers:
#   readonly  → brain-posimyth umbrella only (public Orbit users)
#   team      → + clickup-dora-posi, fluentsupport-posi
#   admin     → all endpoints incl. WordPress + GA4 + GSC
#
# Safe to re-run. Idempotent. Backs up configs before writing.

set -euo pipefail

KEY="${1:-}"
if [[ -z "$KEY" ]]; then
  cat <<EOF
Orbit Connector Installer (v3.1.2)
─────────────────────────────────────────────────────────
Usage:  bash install-connectors.sh <BRAIN_KEY>

Tiers:
  • readonly  → brain-posimyth umbrella only
  • team      → + ClickUp Dora + FluentSupport
  • admin     → all Orbit endpoints (WordPress, GA4, GSC, etc.)

Get a key from POSIMYTH admin or see docs/team-access.md
─────────────────────────────────────────────────────────
EOF
  exit 1
fi

POSIMYTH_BASE="https://brain.posimyth.com"

# ─── Orbit MCPs: name:path:min_tier ──────────────────────────
# Only QA-relevant endpoints. No marketing/business ops.
SERVICES=(
  "brain-posimyth:/connectors:readonly"
  "fluentsupport-posi:/fluentsupport/mcp:team"
  "clickup-dora-posi:/clickup-dora/mcp:team"
  "ga4-posi:/ga4/mcp:admin"
  "gsc-posi:/gsc/mcp:admin"
  "wp-tpae-posi:/wp-tpae/mcp:admin"
  "wp-nexterwp-posi:/wp-nexterwp/mcp:admin"
)

# ─── Personal/general MCPs — NEVER touched ───────────────────
PERSONAL_KEEP=(
  "apple-mail" "playwright" "github" "context7"
  "n8n-mcp" "youtube-analytics" "slack-aditya"
  "Aditya's Desktop"
  # brain-aditya left alone if present — not in either list
)

tier_rank() {
  case "$1" in
    readonly) echo 1 ;;
    team)     echo 2 ;;
    admin)    echo 3 ;;
    *)        echo 0 ;;
  esac
}

# ─── 1. Validate key + detect tier ───────────────────────────
echo ""
echo "→ Validating key against brain.posimyth.com..."
WHOAMI=$(curl -sf -H "Authorization: Bearer $KEY" "${POSIMYTH_BASE}/connectors/whoami" 2>/dev/null || echo '{}')
TIER=$(echo "$WHOAMI" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tier',''))" 2>/dev/null || echo "")

if [[ -z "$TIER" ]]; then
  echo "✗ Key rejected or brain unreachable."
  echo "  Confirm with POSIMYTH admin or check: curl -H 'Authorization: Bearer $KEY' ${POSIMYTH_BASE}/connectors/whoami"
  exit 1
fi
echo "✓ Key valid — tier: $TIER"
MY_RANK=$(tier_rank "$TIER")

# ─── Build allowed list for this tier ────────────────────────
ALLOWED=()
for entry in "${SERVICES[@]}"; do
  IFS=':' read -r name path min_tier <<< "$entry"
  if [[ "$(tier_rank "$min_tier")" -le "$MY_RANK" ]]; then
    ALLOWED+=("$name:$path")
  fi
done
echo "  Endpoints for this tier: ${#ALLOWED[@]} / ${#SERVICES[@]}"

# ─── 2 + 3. Stale cleanup + register ────────────────────────
#
# SHARED MCP POOL RULE:
#   All -posi MCPs belong to one shared pool used by BOTH Orbit and
#   Golden Circle. Neither installer removes the other's MCPs.
#
#   What gets removed:   old stdio-style MCPs with known stale names
#                        (pre-posi era: fluentcrm, ga4, gsc, wp-theplusaddons, etc.)
#   What is NEVER removed: anything ending in -posi, brain-aditya, personal MCPs
#   What gets added/updated: this installer's allowed endpoints (fresh token)
#
update_config() {
  local cfg_path="$1"
  local label="$2"
  local client="$3"   # "code" or "desktop"

  if [[ ! -f "$cfg_path" ]]; then
    mkdir -p "$(dirname "$cfg_path")"
    echo '{}' > "$cfg_path"
  fi

  # Backup
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

# Known stale stdio MCPs from pre-posi era — safe to remove
STALE_OLD_NAMES = {
    "fluentcrm", "wp-theplusaddons", "wp-nexterwp", "wp-uichemy",
    "ga4", "gsc", "dataforseo", "apify", "snov", "ocoya",
    "generatebanners", "meta-ads", "clickup-dora", "discord-guti",
    "fluentsupport", "plausible", "edd-store", "sproutai-blog",
    "wp-tpae", "wp-nexter", "wp-store",
}

with open(path) as f:
    cfg = json.load(f)
cfg.setdefault("mcpServers", {})

# STALE CLEANUP — only remove known old stdio names
# NEVER remove: -posi suffix MCPs (shared pool), brain-aditya, personal MCPs
removed = []
for name in list(cfg["mcpServers"].keys()):
    if name in personal:
        continue
    if name == "brain-aditya":
        continue
    if name.endswith("-posi"):          # shared pool — never touched by either installer
        continue
    if name in STALE_OLD_NAMES:
        removed.append(name)
        del cfg["mcpServers"][name]

# Register/update this installer's allowed endpoints (upsert — keeps others untouched)
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
            "command": "npx",
            "args": ["-y", "mcp-remote", url, "--header", f"Authorization: Bearer {key}"]
        }

# Atomic write
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
  update_config "$CLAUDE_DESKTOP" "Claude Desktop" "desktop"
fi

# ─── 4. Live verification ─────────────────────────────────────
echo ""
echo "→ Live verification (initialize handshake + tool count):"

TOTAL_TOOLS=0
HEALTHY=0
FAILED=0

for s in "${ALLOWED[@]}"; do
  IFS=':' read -r name sub <<< "$s"
  url="${POSIMYTH_BASE}${sub}"

  # MCP initialize handshake (the one that breaks Claude Desktop when missing)
  INIT_OK=$(curl -sf -X POST \
    -H "Authorization: Bearer $KEY" \
    -H "Content-Type: application/json" \
    "$url" \
    -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"orbit-installer","version":"3.1.2"}}}' \
    | python3 -c "import json,sys; d=json.load(sys.stdin); print('yes' if d.get('result',{}).get('serverInfo') else 'no')" \
    2>/dev/null || echo "no")

  # Tool count
  COUNT=$(curl -sf -X POST \
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

# ─── 5. Summary ──────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════════"
echo "  ✓ ORBIT CONNECTORS INSTALLED"
echo "════════════════════════════════════════════════════"
echo "  Tier:               $TIER"
echo "  MCPs registered:    ${#ALLOWED[@]} ($HEALTHY healthy, $FAILED failed)"
echo "  Total tools:        $TOTAL_TOOLS"
echo "  Stale MCPs:         scrubbed from Claude Code + Desktop"
echo "  Personal MCPs:      preserved"
echo ""
echo "  Backups (rollback if needed):"
echo "    cp ${CLAUDE_CODE}.orbit-install.bak ${CLAUDE_CODE}"
[[ "$(uname -s)" == "Darwin" ]] && echo "    cp \"${CLAUDE_DESKTOP}.orbit-install.bak\" \"${CLAUDE_DESKTOP}\""
echo ""
echo "  ⚠ RESTART REQUIRED:"
echo "    1. Quit Claude Code completely   (Cmd+Q, not just close)"
echo "    2. Quit Claude Desktop           (Cmd+Q)"
echo "    3. Reopen both"
echo "    4. Test: 'what tools do I have?' — should see ${#ALLOWED[@]} Orbit MCPs"
if [[ "$FAILED" -gt 0 ]]; then
  echo ""
  echo "  ⚠ $FAILED endpoint(s) failed verification."
  echo "    Check brain.posimyth.com is reachable and your key is valid."
fi
echo "════════════════════════════════════════════════════"
