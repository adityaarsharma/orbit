#!/usr/bin/env bash
# ip-intake-scan.sh — quarantine a competitor plugin reference and extract its reserved identifiers.
# Usage: ip-intake-scan.sh <reference.zip-or-dir> <run-dir>
# Output: run-dir/reference/ (quarantine), reserved-identifiers.txt, intake-record.md (template),
#         and a license/obfuscation classification to stdout.
#
# Engineering risk-reduction, NOT legal advice. Anything marked STOP → escalate to legal before use.
set -uo pipefail

REF="${1:?usage: ip-intake-scan.sh <reference.zip-or-dir> <run-dir>}"
RUN="${2:?usage: ip-intake-scan.sh <reference.zip-or-dir> <run-dir>}"
QUAR="$RUN/reference"
mkdir -p "$QUAR"

# --- Unpack into quarantine ---
if [[ -f "$REF" && "$REF" == *.zip ]]; then
  if command -v unzip >/dev/null 2>&1; then
    unzip -oq "$REF" -d "$QUAR" && echo "Unpacked zip into quarantine: $QUAR"
  else
    echo "ERROR: unzip not found; unzip '$REF' into '$QUAR' manually." >&2; exit 1
  fi
elif [[ -d "$REF" ]]; then
  cp -R "$REF/." "$QUAR/" && echo "Copied reference into quarantine: $QUAR"
else
  echo "ERROR: '$REF' is not a .zip or directory" >&2; exit 1
fi

SEARCH() { if command -v rg >/dev/null 2>&1; then rg "$@" "$QUAR" 2>/dev/null; else grep -rE "$@" "$QUAR" 2>/dev/null; fi; }
ONLY()   { if command -v rg >/dev/null 2>&1; then rg -oN "$@" "$QUAR" 2>/dev/null; else grep -rhoE "$@" "$QUAR" 2>/dev/null; fi; }

echo
echo "=== LICENSE / OBFUSCATION CLASSIFICATION ==="
LIC="$(SEARCH -ni -m1 -e 'License *URI?:|License:' | head -5)"
echo "${LIC:-  (no explicit License: header found — investigate manually)}"
if SEARCH -li -e 'ionCube|eval\(gz|eval\(base64|<\?php @?eval|obfuscat' >/dev/null 2>&1; then
  echo "  ⛔ OBFUSCATED/ENCRYPTED CODE DETECTED — likely a protected pro plugin."
  echo "     STOP. Decompiling/deobfuscating risks EULA + DMCA §1201. Escalate to legal."
fi
if SEARCH -li -e 'AGPL|Affero' >/dev/null 2>&1; then
  echo "  ⚠️  AGPL detected — network/SaaS clause. Check before reusing anything."
fi

echo
echo "=== EXTRACTING RESERVED IDENTIFIERS (do NOT reuse these in our plugin) ==="
{
  echo "# Reserved identifiers from reference — our plugin must NOT reuse any of these."
  echo "## Text domains"; ONLY -e "load_plugin_textdomain\(\s*['\"][^'\"]+" | sed -E "s/.*['\"]//" | sort -u
  echo "## Custom hook/filter names"; ONLY -e "(do_action|apply_filters)\(\s*['\"][^'\"]+" | sed -E "s/.*['\"]//" | sort -u
  echo "## Option / transient keys"; ONLY -e "(get_option|update_option|set_transient|get_transient)\(\s*['\"][^'\"]+" | sed -E "s/.*['\"]//" | sort -u
  echo "## REST namespaces / routes"; ONLY -e "register_rest_route\(\s*['\"][^'\"]+" | sed -E "s/.*['\"]//" | sort -u
  echo "## AJAX actions"; ONLY -e "wp_ajax_[a-zA-Z0-9_]+" | sort -u
  echo "## Shortcodes"; ONLY -e "add_shortcode\(\s*['\"][^'\"]+" | sed -E "s/.*['\"]//" | sort -u
  echo "## Block names"; ONLY -e "\"name\"\s*:\s*\"[a-z0-9-]+/[a-z0-9-]+\"" | sed -E 's/.*"name"\s*:\s*"//; s/"$//' | sort -u
  echo "## Script/style handles"; ONLY -e "wp_(enqueue|register)_(script|style)\(\s*['\"][^'\"]+" | sed -E "s/.*['\"]//" | sort -u
  echo "## Function/class prefixes (top tokens — review by eye)"; ONLY -e "(function|class)\s+[a-zA-Z_][a-zA-Z0-9_]+" | sed -E 's/(function|class)\s+//' | grep -oE '^[a-zA-Z]+_?' | sort | uniq -c | sort -rn | head -20
} > "$RUN/reserved-identifiers.txt"
echo "Wrote $RUN/reserved-identifiers.txt"

# --- Intake record template ---
if [[ ! -f "$RUN/intake-record.md" ]]; then
cat > "$RUN/intake-record.md" <<EOF
# Reference intake record
- Plugin name / version: <fill>
- Source / how obtained: <WP.org | purchased pro | partner | other>
- Authorization to study: <GPL free | pro EULA reviewed | NDA | ⛔ grey source>
- License classification: <see stdout>
- Obfuscated/encrypted?: <yes → STOP/escalate | no>
- Studied by (who saw the reference code): <name(s)>
- Date: $(date -u +%Y-%m-%d 2>/dev/null || echo '<date>')
- Quarantine path: $QUAR (gitignored; never inside our plugin tree)
EOF
echo "Wrote $RUN/intake-record.md (fill it in)"
fi

echo
echo "NEXT: review intake-record.md, then build from a behavioral spec (never copy from $QUAR)."
echo "Add '$RUN/' to .gitignore so quarantined reference code never ships."
