#!/usr/bin/env bash
# Orbit — Version parity check
#
# Every release, 3 (sometimes 4) places must agree on the version number:
#   1. Plugin header (main PHP file): `Version: X.Y.Z`
#   2. readme.txt: `Stable tag: X.Y.Z`
#   3. CHANGELOG.md: `## [X.Y.Z]` or `## X.Y.Z`
#   4. (If tagging) git tag: `vX.Y.Z`
#
# Divergence = WP.org users get "update available" but the zip still has old
# version, or vice versa. Classic release-day bug.

set -e

PLUGIN_PATH="${1:-}"
EXPECTED_TAG="${2:-}"  # optional — compares git tag too if passed
[ -z "$PLUGIN_PATH" ] && { echo "Usage: $0 /path/to/plugin [expected-version-tag]"; exit 1; }
[ ! -d "$PLUGIN_PATH" ] && { echo "Not a dir: $PLUGIN_PATH"; exit 1; }

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

# 1. Find main plugin file (first .php with "Plugin Name:" header)
MAIN_FILE=$(grep -lE "^\s*\*?\s*Plugin Name:" "$PLUGIN_PATH"/*.php 2>/dev/null | head -1)
if [ -z "$MAIN_FILE" ]; then
  echo -e "${RED}✗ No main plugin file found (none has 'Plugin Name:' header)${NC}"
  exit 1
fi

# 2. Extract version from plugin header
HEADER_VER=$(grep -E "^[[:space:]]*\*?[[:space:]]*Version:" "$MAIN_FILE" | head -1 | sed -E 's/.*Version:[[:space:]]*//' | tr -d ' \r')

# 3. Extract stable tag from readme.txt
README_VER=""
if [ -f "$PLUGIN_PATH/readme.txt" ]; then
  README_VER=$(grep "^Stable tag:" "$PLUGIN_PATH/readme.txt" | head -1 | sed -E 's/^Stable tag:[[:space:]]*//' | tr -d ' \r')
fi

# 4. Extract top version from CHANGELOG.md
CHANGELOG_VER=""
if [ -f "$PLUGIN_PATH/CHANGELOG.md" ]; then
  # Match "## [1.2.3]" or "## 1.2.3" or "## v1.2.3"
  CHANGELOG_VER=$(grep -E "^##\s+v?\[?[0-9]+\.[0-9]+(\.[0-9]+)?\]?" "$PLUGIN_PATH/CHANGELOG.md" | \
    head -1 | sed -E 's/^##[[:space:]]+v?\[?//; s/\].*//; s/[[:space:]].*//' | tr -d ' \r')
fi

# Summary
echo "Plugin header (${MAIN_FILE##*/}):  ${HEADER_VER:-(missing)}"
echo "readme.txt Stable tag:             ${README_VER:-(no readme.txt)}"
echo "CHANGELOG.md top entry:            ${CHANGELOG_VER:-(no CHANGELOG.md)}"
[ -n "$EXPECTED_TAG" ] && echo "Expected git tag:                  ${EXPECTED_TAG}"
echo ""

FAIL=0

# Header version required
if [ -z "$HEADER_VER" ]; then
  echo -e "${RED}✗ Plugin header has no Version: field${NC}"
  exit 1
fi

# Compare header vs readme
if [ -n "$README_VER" ] && [ "$HEADER_VER" != "$README_VER" ]; then
  echo -e "${RED}✗ Mismatch: plugin header ($HEADER_VER) ≠ readme.txt Stable tag ($README_VER)${NC}"
  FAIL=1
fi

# Compare header vs changelog
if [ -n "$CHANGELOG_VER" ] && [ "$HEADER_VER" != "$CHANGELOG_VER" ]; then
  echo -e "${RED}✗ Mismatch: plugin header ($HEADER_VER) ≠ CHANGELOG.md ($CHANGELOG_VER)${NC}"
  FAIL=1
fi

# Compare header vs expected git tag
if [ -n "$EXPECTED_TAG" ]; then
  TAG_CLEAN=$(echo "$EXPECTED_TAG" | sed 's/^v//')
  if [ "$HEADER_VER" != "$TAG_CLEAN" ]; then
    echo -e "${RED}✗ Mismatch: plugin header ($HEADER_VER) ≠ expected tag ($TAG_CLEAN)${NC}"
    FAIL=1
  fi
fi

# Check semver format
if ! echo "$HEADER_VER" | grep -qE '^[0-9]+\.[0-9]+(\.[0-9]+)?(-[a-zA-Z0-9.]+)?$'; then
  echo -e "${YELLOW}⚠ Version $HEADER_VER doesn't look like semver (expected X.Y.Z)${NC}"
fi

if [ "$FAIL" -eq 1 ]; then
  echo -e "\n${RED}Version parity: FAIL — fix all versions before tagging${NC}"
  exit 1
fi
echo -e "${GREEN}Version parity: PASS — all locations agree on $HEADER_VER${NC}"
exit 0
