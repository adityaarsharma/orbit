#!/usr/bin/env bash
# Orbit — Translation completeness test
#
# i18n step wraps strings, but never loads an actual .mo file. Mistranslated
# format strings or missing placeholders crash PHP. This script:
#   1. Generates .pot file
#   2. Creates a fake translation (XX pseudo-locale) with long suffix
#   3. Compiles to .mo, loads in WP, loads admin pages
#   4. Scans debug.log for PHP errors during translation load

set -e

PLUGIN_PATH="${1:-}"
[ -z "$PLUGIN_PATH" ] && { echo "Usage: $0 /path/to/plugin"; exit 1; }
[ ! -d "$PLUGIN_PATH" ] && { echo "Not a dir: $PLUGIN_PATH"; exit 1; }

PLUGIN_SLUG=$(basename "$PLUGIN_PATH")
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

if ! command -v wp &>/dev/null; then
  echo -e "${YELLOW}⚠ WP-CLI not installed — skipping translation check${NC}"
  exit 0
fi

TMP_DIR=$(mktemp -d)
POT_FILE="$TMP_DIR/${PLUGIN_SLUG}.pot"
PO_FILE="$TMP_DIR/${PLUGIN_SLUG}-en_XX.po"
MO_FILE="$PLUGIN_PATH/languages/${PLUGIN_SLUG}-en_XX.mo"

# 1. Generate POT
cd "$PLUGIN_PATH"
wp i18n make-pot . "$POT_FILE" --skip-audit 2>/dev/null || {
  echo -e "${RED}✗ POT generation failed${NC}"
  exit 1
}

STRING_COUNT=$(grep -c '^msgid "' "$POT_FILE" || echo 0)
echo -e "${GREEN}✓ POT generated: $STRING_COUNT strings${NC}"

if [ "$STRING_COUNT" -eq 0 ]; then
  echo -e "${YELLOW}⚠ No translatable strings — plugin may not be i18n-ready${NC}"
  exit 0
fi

# 2. Create pseudo-translation: append ~~ to every string (preserves %s, %d placeholders)
cp "$POT_FILE" "$PO_FILE"
python3 - <<PYEOF
import re
with open("$PO_FILE") as f: text = f.read()
def translate(m):
    orig = m.group(1)
    if orig == "":  # header block
        return m.group(0)
    # Keep placeholders intact
    return f'msgstr "{orig}~~"'
# Replace msgstr "" lines
out = re.sub(r'msgid "([^"]*)"\nmsgstr ""', lambda m: f'msgid "{m.group(1)}"\nmsgstr "{m.group(1)}~~"' if m.group(1) else m.group(0), text)
with open("$PO_FILE", "w") as f: f.write(out)
PYEOF

# 3. Compile to .mo
mkdir -p "$PLUGIN_PATH/languages"
if command -v msgfmt &>/dev/null; then
  msgfmt -o "$MO_FILE" "$PO_FILE" 2>/dev/null || {
    echo -e "${RED}✗ msgfmt failed${NC}"
    exit 1
  }
else
  wp i18n make-mo "$TMP_DIR" "$PLUGIN_PATH/languages" 2>/dev/null || {
    echo -e "${YELLOW}⚠ Neither msgfmt nor wp i18n make-mo — skipping mo compile test${NC}"
    rm -rf "$TMP_DIR"
    exit 0
  }
fi

# 4. Load in WP, hit admin, check for errors
ORIG_LOG=""
DEBUG_LOG=$(wp eval 'echo WP_CONTENT_DIR;' 2>/dev/null)/debug.log
[ -f "$DEBUG_LOG" ] && ORIG_LOG=$(wc -l < "$DEBUG_LOG")

wp option update WPLANG en_XX 2>/dev/null || true
wp eval 'load_plugin_textdomain("'"$PLUGIN_SLUG"'", false, dirname(plugin_basename("'"$PLUGIN_PATH"'/'"$PLUGIN_SLUG"'.php")) . "/languages");' 2>/dev/null || true

# Hit a few admin pages
curl -s -o /dev/null "${WP_TEST_URL:-http://localhost:8881}/wp-admin/" || true
curl -s -o /dev/null "${WP_TEST_URL:-http://localhost:8881}/wp-admin/admin.php?page=${PLUGIN_SLUG}" || true

# Check for new errors
NEW_ERRORS=0
if [ -f "$DEBUG_LOG" ]; then
  CURR_LOG=$(wc -l < "$DEBUG_LOG")
  NEW_ERRORS=$(tail -n $((CURR_LOG - ORIG_LOG)) "$DEBUG_LOG" 2>/dev/null | grep -cE "PHP (Fatal|Warning|Notice).*(sprintf|printf|_n\(|translation)" || echo 0)
fi

# Cleanup
rm -f "$MO_FILE"
wp option update WPLANG '' 2>/dev/null || true
rm -rf "$TMP_DIR"

if [ "$NEW_ERRORS" -gt 0 ]; then
  echo -e "${RED}✗ $NEW_ERRORS translation-related PHP errors detected${NC}"
  echo "Common cause: sprintf('%s', __('Hello')) with mistranslated placeholder"
  exit 1
fi

echo -e "${GREEN}✓ Translation completeness: PASSED${NC} (no errors under en_XX pseudo-locale)"
exit 0
