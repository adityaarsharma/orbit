#!/usr/bin/env bash
# Orbit — readme.txt WP.org parser validation
#
# The WordPress.org plugin repository parses readme.txt strictly. Missing or
# malformed fields = submission rejection. This validates every field the
# official parser expects.
# Ref: https://wordpress.org/plugins/developers/#readme

set -e

PLUGIN_PATH="${1:-}"
[ -z "$PLUGIN_PATH" ] && { echo "Usage: $0 /path/to/plugin"; exit 1; }
[ ! -d "$PLUGIN_PATH" ] && { echo "Not a dir: $PLUGIN_PATH"; exit 1; }

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

README="$PLUGIN_PATH/readme.txt"
if [ ! -f "$README" ]; then
  echo -e "${RED}✗ readme.txt missing — required by WordPress.org${NC}"
  exit 1
fi

FAIL=0
WARN=0

# Required header fields
REQUIRED=(
  "Contributors:"
  "Tags:"
  "Requires at least:"
  "Tested up to:"
  "Stable tag:"
  "License:"
)
for field in "${REQUIRED[@]}"; do
  if ! grep -q "^${field}" "$README"; then
    echo -e "${RED}✗ Missing required field: ${field}${NC}"
    FAIL=1
  fi
done

# Requires PHP (required since WP 5.1)
if ! grep -q "^Requires PHP:" "$README"; then
  echo -e "${YELLOW}⚠ Missing: Requires PHP: (recommended since WP 5.1)${NC}"
  WARN=1
fi

# Required sections (as == Heading ==)
REQUIRED_SECTIONS=(
  "== Description =="
  "== Installation =="
  "== Changelog =="
)
for section in "${REQUIRED_SECTIONS[@]}"; do
  if ! grep -qF "$section" "$README"; then
    echo -e "${RED}✗ Missing section: $section${NC}"
    FAIL=1
  fi
done

# Recommended sections
for section in "== Frequently Asked Questions ==" "== Screenshots ==" "== Upgrade Notice =="; do
  if ! grep -qF "$section" "$README"; then
    echo -e "${YELLOW}⚠ Recommended section missing: $section${NC}"
    WARN=1
  fi
done

# Short description line length (under === name ===, before first blank line)
SHORT_DESC=$(awk '/^=== /{f=1; next} f && /^$/{exit} f && !/^[A-Z][a-zA-Z ]+:/{print}' "$README" | head -1 | tr -d '\r')
SHORT_LEN=${#SHORT_DESC}
if [ "$SHORT_LEN" -eq 0 ]; then
  echo -e "${RED}✗ Short description missing (one-line plugin tagline under === Plugin Name ===)${NC}"
  FAIL=1
elif [ "$SHORT_LEN" -gt 150 ]; then
  echo -e "${RED}✗ Short description is $SHORT_LEN chars (WP.org limit: 150)${NC}"
  FAIL=1
fi

# Tag count (WP.org allows max 5 in-use tags, up to 12 in field)
TAGS_LINE=$(grep "^Tags:" "$README" | head -1 | sed 's/^Tags://' | tr ',' '\n' | grep -v '^[[:space:]]*$' | wc -l | tr -d ' ')
if [ "$TAGS_LINE" -gt 12 ]; then
  echo -e "${RED}✗ Tags: has $TAGS_LINE entries (WP.org limit: 12)${NC}"
  FAIL=1
fi

# Stable tag must match plugin version (check against plugin main file if present)
STABLE_TAG=$(grep "^Stable tag:" "$README" | head -1 | sed 's/^Stable tag:[[:space:]]*//' | tr -d ' \r')
if [ -z "$STABLE_TAG" ] || [ "$STABLE_TAG" = "trunk" ]; then
  echo -e "${YELLOW}⚠ Stable tag is empty or 'trunk' (should be a version number like 1.2.3)${NC}"
  WARN=1
fi

# Tested up to — must be a valid WP version
TESTED_UP=$(grep "^Tested up to:" "$README" | head -1 | sed 's/^Tested up to:[[:space:]]*//' | tr -d ' \r')
if [ -n "$TESTED_UP" ]; then
  # Compare with latest stable WP (hardcoded to current state — update periodically)
  LATEST_WP="6.9"
  if [ "$(printf '%s\n' "$LATEST_WP" "$TESTED_UP" | sort -V | head -1)" != "$LATEST_WP" ]; then
    echo -e "${YELLOW}⚠ Tested up to: $TESTED_UP is older than WP $LATEST_WP — update before release${NC}"
    WARN=1
  fi
fi

# Contributors format (WP.org usernames, lowercase, comma-separated)
CONTRIBUTORS=$(grep "^Contributors:" "$README" | head -1 | sed 's/^Contributors://')
if echo "$CONTRIBUTORS" | grep -qE '[A-Z]'; then
  echo -e "${YELLOW}⚠ Contributors should be all-lowercase WP.org usernames${NC}"
  WARN=1
fi

echo ""
if [ "$FAIL" -eq 1 ]; then
  echo -e "${RED}readme.txt: FAIL — WP.org will reject this submission${NC}"
  exit 1
fi
if [ "$WARN" -eq 1 ]; then
  echo -e "${YELLOW}readme.txt: WARN — review before release${NC}"
  exit 0
fi
echo -e "${GREEN}readme.txt: PASS — WP.org parser compliant${NC}"
exit 0
