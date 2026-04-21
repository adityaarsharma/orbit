#!/usr/bin/env bash
# Orbit — Login Page Asset Leak Check
#
# Many plugins accidentally enqueue scripts/styles on wp-login.php because
# they hook to 'wp_enqueue_scripts' without conditions. This:
#   - Slows login page for all users
#   - Causes JS errors (admin-specific code running on login)
#   - Leaks plugin info to unauthenticated visitors
#
# This script fetches wp-login.php and flags assets from the plugin slug.

set -e

PLUGIN_SLUG="${1:-}"
WP_URL="${WP_TEST_URL:-http://localhost:8881}"

[ -z "$PLUGIN_SLUG" ] && { echo "Usage: $0 <plugin-slug> [wp-url]"; exit 1; }
[ -n "$2" ] && WP_URL="$2"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

LOGIN_HTML=$(curl -sL "${WP_URL}/wp-login.php" 2>/dev/null || echo "")
if [ -z "$LOGIN_HTML" ]; then
  echo -e "${YELLOW}⚠ Could not fetch $WP_URL/wp-login.php — skipping${NC}"
  exit 0
fi

# Find plugin assets loaded on login page
LEAKED_ASSETS=$(echo "$LOGIN_HTML" | grep -oE "(src|href)=['\"][^'\"]*wp-content/plugins/${PLUGIN_SLUG}/[^'\"]+" | sort -u || true)

if [ -z "$LEAKED_ASSETS" ]; then
  echo -e "${GREEN}✓ No ${PLUGIN_SLUG} assets leaked on wp-login.php${NC}"
  exit 0
fi

ASSET_COUNT=$(echo "$LEAKED_ASSETS" | wc -l | tr -d ' ')
echo -e "${RED}✗ Found $ASSET_COUNT leaked assets on wp-login.php:${NC}"
echo "$LEAKED_ASSETS"
echo ""
echo "Fix: guard your wp_enqueue_scripts callback:"
echo "  if ( 'wp-login.php' === (isset(\$GLOBALS['pagenow']) ? \$GLOBALS['pagenow'] : '') ) return;"
echo "Or use a conditional like is_admin() + specific pages only."
exit 1
