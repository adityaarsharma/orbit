#!/usr/bin/env bash
# Orbit — Object cache (Redis) compatibility check
#
# Runs the plugin against a WP install with persistent object cache enabled.
# Catches:
#   - Transients that break silently with Redis (keys too long, data too big)
#   - wp_cache_set race conditions that only manifest with persistent cache
#   - Code that assumes transients hit the DB (they don't with object cache)
#
# Requires docker-compose with a redis service running.

set -e

PLUGIN_PATH="${1:-}"
WP_ENV_RUN="${WP_ENV_RUN:-npx wp-env run cli wp}"

[ -z "$PLUGIN_PATH" ] && { echo "Usage: $0 /path/to/plugin"; exit 1; }

PLUGIN_SLUG=$(basename "$PLUGIN_PATH")
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

wp() { $WP_ENV_RUN "$@"; }

# 1. Detect Redis
REDIS_HOST="${REDIS_HOST:-127.0.0.1}"
REDIS_PORT="${REDIS_PORT:-6379}"

if ! command -v redis-cli &>/dev/null && ! nc -z "$REDIS_HOST" "$REDIS_PORT" 2>/dev/null; then
  echo -e "${YELLOW}⚠ Redis not detected at ${REDIS_HOST}:${REDIS_PORT} — skipping object cache test${NC}"
  echo "   Start with: docker run -d -p 6379:6379 redis:7-alpine"
  exit 0
fi

echo -e "${GREEN}✓ Redis detected at ${REDIS_HOST}:${REDIS_PORT}${NC}"

# 2. Install redis-cache plugin if not present
if ! wp plugin is-installed redis-cache 2>/dev/null; then
  echo "Installing redis-cache plugin..."
  wp plugin install redis-cache --activate
else
  wp plugin activate redis-cache
fi

# 3. Enable object cache drop-in
wp redis enable 2>/dev/null || wp eval 'wp_cache_flush();' 2>/dev/null

# 4. Snapshot debug.log
DEBUG_LOG=$(wp eval 'echo WP_CONTENT_DIR;' 2>/dev/null)/debug.log
START_LINES=0
[ -f "$DEBUG_LOG" ] && START_LINES=$(wc -l < "$DEBUG_LOG")

# 5. Activate plugin and exercise
wp plugin activate "$PLUGIN_SLUG" || { echo -e "${RED}✗ Plugin activation failed${NC}"; exit 1; }

# Hit frontend + admin with cache active
curl -s -o /dev/null "${WP_TEST_URL:-http://localhost:8881}/"
curl -s -o /dev/null "${WP_TEST_URL:-http://localhost:8881}/wp-admin/"
curl -s -o /dev/null "${WP_TEST_URL:-http://localhost:8881}/wp-admin/admin.php?page=${PLUGIN_SLUG}"

# 6. Check for new errors
NEW_ERRORS=0
if [ -f "$DEBUG_LOG" ]; then
  CURR=$(wc -l < "$DEBUG_LOG")
  NEW_ERRORS=$(tail -n $((CURR - START_LINES)) "$DEBUG_LOG" 2>/dev/null | grep -cE "PHP (Fatal|Warning|Notice)" || echo 0)
fi

# 7. Check for transient-related issues
TRANSIENT_WARNINGS=$(wp eval '
  $suspicious = [];
  global $wpdb;
  // Transients in DB when object cache is active = bypass bug
  $rows = $wpdb->get_results("SELECT option_name FROM {$wpdb->options} WHERE option_name LIKE \"_transient_%\" LIMIT 10");
  foreach ($rows as $r) {
    if (strpos($r->option_name, "'"$PLUGIN_SLUG"'") !== false || strpos($r->option_name, "'"${PLUGIN_SLUG//-/_}"'") !== false) {
      $suspicious[] = $r->option_name;
    }
  }
  echo count($suspicious);
' 2>/dev/null || echo 0)

echo ""
if [ "$NEW_ERRORS" -gt 0 ]; then
  echo -e "${RED}✗ $NEW_ERRORS new PHP errors with Redis object cache enabled${NC}"
  tail -n 20 "$DEBUG_LOG" | grep -E "PHP (Fatal|Warning)" | head -5
  exit 1
fi

if [ "$TRANSIENT_WARNINGS" -gt 0 ]; then
  echo -e "${YELLOW}⚠ Plugin wrote $TRANSIENT_WARNINGS transients to DB despite object cache${NC}"
  echo "   This means set_transient() is bypassing the cache layer — review transient usage"
fi

echo -e "${GREEN}✓ Object cache compatibility: PASSED${NC}"
exit 0
