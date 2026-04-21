#!/usr/bin/env bash
# Orbit — GDPR / WordPress Privacy API compliance check
#
# WP 4.9.6+ requires any plugin that stores personal user data to register:
#   - wp_privacy_personal_data_exporters  (for "Export Personal Data" tool)
#   - wp_privacy_personal_data_erasers    (for "Erase Personal Data" tool)
#
# This script scans a plugin for user-data indicators and flags missing hooks.

set -e

PLUGIN_PATH="${1:-}"
[ -z "$PLUGIN_PATH" ] && { echo "Usage: $0 /path/to/plugin"; exit 1; }
[ ! -d "$PLUGIN_PATH" ] && { echo "Not a dir: $PLUGIN_PATH"; exit 1; }

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

# Indicators that the plugin stores user data
USER_DATA_PATTERNS=(
  'add_user_meta'
  'update_user_meta'
  'wp_create_user'
  'wp_insert_user'
  'CREATE TABLE.*user_id'
  'wp_mail'
  'get_userdata'
  '\$_POST\[.email.\]'
  '\$_POST\[.name.\]'
  'stripe_'
  'checkout'
  'payment'
)

# Search for user-data indicators
USER_DATA_HITS=0
for pattern in "${USER_DATA_PATTERNS[@]}"; do
  COUNT=$(grep -rEl "$pattern" "$PLUGIN_PATH" \
    --include="*.php" \
    --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d ' ')
  USER_DATA_HITS=$((USER_DATA_HITS + COUNT))
done

if [ "$USER_DATA_HITS" -eq 0 ]; then
  echo -e "${GREEN}✓ No user data indicators found — GDPR hooks not required${NC}"
  exit 0
fi

echo "Plugin stores user data ($USER_DATA_HITS indicator files). Checking GDPR hooks..."
echo ""

# Required hooks
EXPORTER_FOUND=$(grep -rEl "wp_privacy_personal_data_exporters" "$PLUGIN_PATH" \
  --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d ' ')
ERASER_FOUND=$(grep -rEl "wp_privacy_personal_data_erasers" "$PLUGIN_PATH" \
  --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d ' ')

# Privacy policy content (WP 4.9.6+ feature)
POLICY_FOUND=$(grep -rEl "wp_add_privacy_policy_content" "$PLUGIN_PATH" \
  --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d ' ')

FAIL=0

if [ "$EXPORTER_FOUND" -eq 0 ]; then
  echo -e "${RED}✗ Missing: wp_privacy_personal_data_exporters filter${NC}"
  echo "   Add: add_filter('wp_privacy_personal_data_exporters', 'myplugin_register_exporter');"
  FAIL=1
else
  echo -e "${GREEN}✓ Data exporter registered${NC}"
fi

if [ "$ERASER_FOUND" -eq 0 ]; then
  echo -e "${RED}✗ Missing: wp_privacy_personal_data_erasers filter${NC}"
  echo "   Add: add_filter('wp_privacy_personal_data_erasers', 'myplugin_register_eraser');"
  FAIL=1
else
  echo -e "${GREEN}✓ Data eraser registered${NC}"
fi

if [ "$POLICY_FOUND" -eq 0 ]; then
  echo -e "${YELLOW}⚠ Recommended: wp_add_privacy_policy_content${NC}"
  echo "   Add suggested privacy policy text for site admins to include"
fi

if [ "$FAIL" -eq 1 ]; then
  echo ""
  echo -e "${RED}GDPR check: FAILED${NC} — required Privacy API hooks missing"
  echo "Reference: https://developer.wordpress.org/plugins/privacy/"
  exit 1
fi

echo ""
echo -e "${GREEN}GDPR check: PASSED${NC}"
exit 0
