#!/usr/bin/env bash
# Orbit — GPL License Compliance Check
#
# WordPress.org requires all plugin code (including bundled third-party libraries)
# to be GPL-compatible. Common non-compatible licenses: proprietary, CC-NC, CC-ND,
# JSON License (old), unmodified LGPL-3 (debated). This script scans vendor/ and
# node_modules/ for declared licenses and flags incompatible ones.
# Ref: https://developer.wordpress.org/plugins/wordpress-org/detailed-plugin-guidelines/#1-plugins-must-be-compatible-with-the-gnu-general-public-license

set -e

PLUGIN_PATH="${1:-}"
[ -z "$PLUGIN_PATH" ] && { echo "Usage: $0 /path/to/plugin"; exit 1; }
[ ! -d "$PLUGIN_PATH" ] && { echo "Not a dir: $PLUGIN_PATH"; exit 1; }

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

# GPL-compatible licenses (per gnu.org)
COMPATIBLE='GPL|GPL-2|GPL-3|GPL-2.0|GPL-3.0|LGPL-2.1|LGPL-2|AGPL|MIT|BSD|BSD-2|BSD-3|Apache-2|Apache 2|ISC|Unlicense|WTFPL|CC0|Public Domain'

# Known incompatible
INCOMPATIBLE='CC-BY-NC|CC-BY-ND|Creative Commons Attribution-NonCommercial|Proprietary|All rights reserved|MPL-1.1|EPL-1.0|CDDL|JSON License'

FAIL=0
WARN=0

echo "Scanning for bundled library licenses..."

# Composer vendor scan
if [ -d "$PLUGIN_PATH/vendor" ]; then
  COMPOSER_FILES=$(find "$PLUGIN_PATH/vendor" -maxdepth 3 -name "composer.json" 2>/dev/null)
  for f in $COMPOSER_FILES; do
    PKG=$(python3 -c "import json; d=json.load(open('$f')); print(d.get('name',''))" 2>/dev/null)
    LICENSE=$(python3 -c "import json; d=json.load(open('$f')); l=d.get('license',''); print(l if isinstance(l,str) else (','.join(l) if l else ''))" 2>/dev/null)
    [ -z "$LICENSE" ] && continue

    if echo "$LICENSE" | grep -qiE "$INCOMPATIBLE"; then
      echo -e "${RED}✗ Incompatible: $PKG ($LICENSE)${NC}"
      FAIL=1
    elif echo "$LICENSE" | grep -qiE "$COMPATIBLE"; then
      :  # OK
    else
      echo -e "${YELLOW}⚠ Unknown license: $PKG ($LICENSE)${NC}"
      WARN=1
    fi
  done
fi

# npm node_modules scan (NOTE: should typically not ship with production)
if [ -d "$PLUGIN_PATH/node_modules" ]; then
  echo -e "${YELLOW}⚠ node_modules/ present in plugin — these should NOT ship with a production release${NC}"
  WARN=1
  NPM_FILES=$(find "$PLUGIN_PATH/node_modules" -maxdepth 2 -name "package.json" 2>/dev/null | head -50)
  for f in $NPM_FILES; do
    PKG=$(python3 -c "import json; d=json.load(open('$f')); print(d.get('name',''))" 2>/dev/null)
    LICENSE=$(python3 -c "import json; d=json.load(open('$f')); print(d.get('license','') if isinstance(d.get('license'),str) else (d.get('license',{}).get('type','') if d.get('license') else ''))" 2>/dev/null)
    [ -z "$LICENSE" ] && continue
    if echo "$LICENSE" | grep -qiE "$INCOMPATIBLE"; then
      echo -e "${RED}✗ Incompatible (bundled JS): $PKG ($LICENSE)${NC}"
      FAIL=1
    fi
  done
fi

# Plugin's own declared license (in main header)
MAIN_FILE=$(grep -lE "^\s*\*?\s*Plugin Name:" "$PLUGIN_PATH"/*.php 2>/dev/null | head -1 || true)
if [ -n "$MAIN_FILE" ]; then
  PLUGIN_LICENSE=$(grep -iE "^[[:space:]]*\*?[[:space:]]*License:" "$MAIN_FILE" | head -1 | sed -E 's/.*License:[[:space:]]*//' | tr -d ' \r' || true)
  if [ -z "$PLUGIN_LICENSE" ]; then
    echo -e "${RED}✗ Plugin header missing License: field (WP.org requires GPL v2 or later)${NC}"
    FAIL=1
  elif ! echo "$PLUGIN_LICENSE" | grep -qiE "GPL"; then
    echo -e "${RED}✗ Plugin license '$PLUGIN_LICENSE' is not GPL-compatible${NC}"
    FAIL=1
  fi
fi

echo ""
if [ "$FAIL" -eq 1 ]; then
  echo -e "${RED}License compliance: FAIL — WP.org will reject${NC}"
  exit 1
fi
if [ "$WARN" -eq 1 ]; then
  echo -e "${YELLOW}License compliance: WARN — review unknowns${NC}"
  exit 0
fi
echo -e "${GREEN}License compliance: PASS (all GPL-compatible)${NC}"
exit 0
