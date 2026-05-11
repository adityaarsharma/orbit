#!/usr/bin/env bash
# Orbit — Test Scaffolder
#
# Reads a plugin directory and produces:
#   1. qa.config.json            — starter config with everything Orbit detected
#   2. qa-scenarios.md           — human-readable QA cases (one per code entry point)
#   3. tests/playwright/flows/scaffold-*.spec.js — draft Playwright specs
#
# Every output is a STARTING POINT. Review it, adjust the selectors, fill in
# the business logic — but you don't start from a blank page.
#
# Usage:
#   bash scripts/scaffold-tests.sh /path/to/plugin [--deep]
#
#   --deep   Invokes /orbit-scaffold-tests skill for AI-augmented scenarios
#            (requires `claude` CLI installed and authenticated)

set -e

PLUGIN_PATH="${1:-}"
DEEP=0
[ "${2:-}" = "--deep" ] && DEEP=1
[ -z "$PLUGIN_PATH" ] && { echo "Usage: $0 /path/to/plugin [--deep]"; exit 1; }
[ ! -d "$PLUGIN_PATH" ] && { echo "Not a dir: $PLUGIN_PATH"; exit 1; }

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
PLUGIN_SLUG=$(basename "$PLUGIN_PATH")
OUT_DIR="scaffold-out/$PLUGIN_SLUG"
mkdir -p "$OUT_DIR" "tests/playwright/flows"

echo -e "${CYAN}Orbit Test Scaffolder — $PLUGIN_SLUG${NC}"
echo "Reading plugin code..."
echo ""

# ─── 1. Main plugin file + version + prefix ──────────────────────────────────
MAIN_FILE=$(grep -lE "^\s*\*?\s*Plugin Name:" "$PLUGIN_PATH"/*.php 2>/dev/null | head -1 || echo "")
if [ -n "$MAIN_FILE" ]; then
  VERSION=$(grep -E "^[[:space:]]*\*?[[:space:]]*Version:" "$MAIN_FILE" | head -1 | sed -E 's/.*Version:[[:space:]]*//' | tr -d ' \r')
  TEXT_DOMAIN=$(grep -iE "^[[:space:]]*\*?[[:space:]]*Text Domain:" "$MAIN_FILE" | head -1 | sed -E 's/.*Text Domain:[[:space:]]*//' | tr -d ' \r')
else
  VERSION=""
  TEXT_DOMAIN="$PLUGIN_SLUG"
fi
# Derive plugin prefix from slug (most conventional — foo-bar → foo_bar)
PREFIX=$(echo "$PLUGIN_SLUG" | tr '-' '_')

# ─── 2. Admin pages (add_menu_page / add_submenu_page) ───────────────────────
echo "→ Admin pages"
ADMIN_PAGES=$(grep -rEh "add_(menu|submenu|options|dashboard|management|plugins|theme|users|tools)_page\s*\(" "$PLUGIN_PATH" \
  --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | \
  grep -oE "['\"][a-z0-9_-]+['\"]" | \
  sort -u | head -20 | sed "s/['\"]//g" | grep -vE '^(read|manage_options|administrator|edit_posts)$' || true)
ADMIN_SLUGS_JSON=$(echo "$ADMIN_PAGES" | awk 'NF{print "    \""$0"\""}' | paste -sd ',' - 2>/dev/null || echo "")

# ─── 3. Shortcodes ───────────────────────────────────────────────────────────
echo "→ Shortcodes"
SHORTCODES=$(grep -rEh "add_shortcode\s*\(\s*['\"]([^'\"]+)['\"]" "$PLUGIN_PATH" \
  --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | \
  sed -E "s/.*add_shortcode[[:space:]]*\([[:space:]]*['\"]([^'\"]+)['\"].*/\1/" | sort -u || true)

# ─── 4. REST routes ──────────────────────────────────────────────────────────
echo "→ REST routes"
REST_ROUTES=$(grep -rEh "register_rest_route\s*\(\s*['\"]([^'\"]+)['\"]" "$PLUGIN_PATH" \
  --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | \
  sed -E "s/.*register_rest_route[[:space:]]*\([[:space:]]*['\"]([^'\"]+)['\"].*/\1/" | sort -u || true)

# ─── 5. AJAX actions ─────────────────────────────────────────────────────────
echo "→ AJAX actions"
AJAX_PRIV=$(grep -rEh "add_action\s*\(\s*['\"]wp_ajax_([^'\"]+)['\"]" "$PLUGIN_PATH" \
  --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | \
  grep -v "wp_ajax_nopriv_" | \
  sed -E "s/.*wp_ajax_([^'\"]+)['\"].*/\1/" | sort -u || true)
AJAX_NOPRIV=$(grep -rEh "add_action\s*\(\s*['\"]wp_ajax_nopriv_([^'\"]+)['\"]" "$PLUGIN_PATH" \
  --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | \
  sed -E "s/.*wp_ajax_nopriv_([^'\"]+)['\"].*/\1/" | sort -u || true)

# ─── 6. Cron hooks ───────────────────────────────────────────────────────────
echo "→ Cron hooks"
CRON_HOOKS=$(grep -rEh "wp_(schedule_event|schedule_single_event)\s*\([^,]+,\s*['\"]([^'\"]+)['\"]" "$PLUGIN_PATH" \
  --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | \
  sed -E "s/.*['\"]([a-z0-9_-]+)['\"][^'\"]*$/\1/" | sort -u || true)

# ─── 7. Gutenberg blocks ─────────────────────────────────────────────────────
echo "→ Gutenberg blocks"
BLOCKS=$(find "$PLUGIN_PATH" -name "block.json" -not -path "*/node_modules/*" -not -path "*/vendor/*" 2>/dev/null | \
  while read -r bjson; do
    python3 -c "import json; print(json.load(open('$bjson')).get('name',''))" 2>/dev/null
  done | grep -v '^$' | sort -u || true)

# ─── 8. Custom post types ────────────────────────────────────────────────────
echo "→ Custom post types"
CPTS=$(grep -rEh "register_post_type\s*\(\s*['\"]([^'\"]+)['\"]" "$PLUGIN_PATH" \
  --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | \
  sed -E "s/.*register_post_type[[:space:]]*\([[:space:]]*['\"]([^'\"]+)['\"].*/\1/" | sort -u || true)

# ─── 9. Custom tables (dbDelta) ──────────────────────────────────────────────
echo "→ Custom tables"
TABLES=$(grep -rEh "\\\$wpdb->prefix\s*\.\s*['\"]([a-z0-9_]+)['\"]|\\\$table_name\s*=\s*\\\$wpdb->prefix\s*\.\s*['\"]([a-z0-9_]+)['\"]" "$PLUGIN_PATH" \
  --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | \
  grep -oE "['\"][a-z0-9_]+['\"]" | sort -u | sed "s/['\"]//g" | \
  grep -vE '^(options|posts|postmeta|users|usermeta|terms|termmeta|term_relationships|term_taxonomy)$' | head -10 || true)

# ─── 10. Uses WooCommerce? ───────────────────────────────────────────────────
USES_WC=$(grep -rEl "wc_get_order|WC_Order|woocommerce_init|before_woocommerce_init" "$PLUGIN_PATH" \
  --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d ' ')
# Python-capitalized booleans — embedded into Python heredoc below
WC_FLAG=False
[ "$USES_WC" -gt 0 ] && WC_FLAG=True

# ─── 11. Uses Elementor? ─────────────────────────────────────────────────────
USES_ELEMENTOR=$(grep -rEl "Elementor\\\\Widget_Base|elementor/widgets/widgets_registered" "$PLUGIN_PATH" \
  --include="*.php" --exclude-dir=vendor --exclude-dir=node_modules 2>/dev/null | wc -l | tr -d ' ')

# ─── 12. Plugin type heuristic ───────────────────────────────────────────────
PLUGIN_TYPE="general"
[ -n "$BLOCKS" ] && PLUGIN_TYPE="gutenberg-blocks"
[ "$USES_ELEMENTOR" -gt 0 ] && PLUGIN_TYPE="elementor-addon"
[ "$WC_FLAG" = "True" ] && PLUGIN_TYPE="woocommerce-extension"
[ -n "$REST_ROUTES" ] && [ -z "$ADMIN_PAGES" ] && PLUGIN_TYPE="rest-api"

# ─── Report what we found ────────────────────────────────────────────────────
# Count non-empty lines. Guard against empty var (grep -c . of empty stdin
# returns 0 but `|| echo 0` doubles it → "0\n0" → arithmetic error under set -e)
count_lines() {
  [ -z "$1" ] && echo 0 && return
  printf '%s\n' "$1" | grep -c . 2>/dev/null || echo 0
}

COUNT_ADMIN=$(count_lines "$ADMIN_PAGES")
COUNT_SHORT=$(count_lines "$SHORTCODES")
COUNT_REST=$(count_lines "$REST_ROUTES")
COUNT_AJAX_PRIV=$(count_lines "$AJAX_PRIV")
COUNT_AJAX_NOPRIV=$(count_lines "$AJAX_NOPRIV")
COUNT_AJAX=$(( COUNT_AJAX_PRIV + COUNT_AJAX_NOPRIV ))
COUNT_CRON=$(count_lines "$CRON_HOOKS")
COUNT_BLOCKS=$(count_lines "$BLOCKS")
COUNT_CPT=$(count_lines "$CPTS")

echo ""
echo -e "${CYAN}── Detected entry points ──${NC}"
printf "  %-25s %d\n" "Admin pages:"     "$COUNT_ADMIN"
printf "  %-25s %d\n" "Shortcodes:"      "$COUNT_SHORT"
printf "  %-25s %d\n" "REST routes:"     "$COUNT_REST"
printf "  %-25s %d\n" "AJAX actions:"    "$COUNT_AJAX"
printf "  %-25s %d\n" "Cron hooks:"      "$COUNT_CRON"
printf "  %-25s %d\n" "Gutenberg blocks:" "$COUNT_BLOCKS"
printf "  %-25s %d\n" "Custom post types:" "$COUNT_CPT"
printf "  %-25s %s\n" "Plugin type:"     "$PLUGIN_TYPE"
echo ""

# ─── Generate qa.config.json ─────────────────────────────────────────────────
FIRST_ADMIN=$(echo "$ADMIN_PAGES" | head -1)
FIRST_REST=$(echo "$REST_ROUTES" | head -1)

python3 - <<PYEOF > "$OUT_DIR/qa.config.json"
import json

config = {
    "plugin": {
        "name": "$PLUGIN_SLUG",
        "slug": "$PLUGIN_SLUG",
        "path": "$PLUGIN_PATH",
        "type": "$PLUGIN_TYPE",
        "prefix": "$PREFIX",
        "text_domain": "${TEXT_DOMAIN:-$PLUGIN_SLUG}",
        "version": "$VERSION",
        "admin_slug": "$FIRST_ADMIN",
        "admin_slugs": [s for s in """$ADMIN_PAGES""".strip().split("\n") if s],
        "shortcodes":  [s for s in """$SHORTCODES""".strip().split("\n") if s],
        "rest_routes": [s for s in """$REST_ROUTES""".strip().split("\n") if s],
        "rest_admin_endpoint": "/wp-json/" + ("$FIRST_REST" if "$FIRST_REST" else "$PREFIX/v1/settings"),
        "ajax_actions": {
            "authenticated":   [s for s in """$AJAX_PRIV""".strip().split("\n") if s],
            "unauthenticated": [s for s in """$AJAX_NOPRIV""".strip().split("\n") if s],
        },
        "cron_hooks":   [s for s in """$CRON_HOOKS""".strip().split("\n") if s],
        "blocks":       [s for s in """$BLOCKS""".strip().split("\n") if s],
        "post_types":   [s for s in """$CPTS""".strip().split("\n") if s],
        "custom_tables": [s for s in """$TABLES""".strip().split("\n") if s],
        "uses_woocommerce": $WC_FLAG,
    },
    "gauntlet": {
        "mode": "full",
        "env":  "local",
    },
    "_orbit_scaffold_version": "1.0",
    "_note": "Generated by scripts/scaffold-tests.sh. Review every field — selectors and flows need human judgment."
}
print(json.dumps(config, indent=2))
PYEOF

echo -e "${GREEN}✓${NC} Wrote $OUT_DIR/qa.config.json"

# ─── Generate qa-scenarios.md ────────────────────────────────────────────────
cat > "$OUT_DIR/qa-scenarios.md" << SCENARIOS_EOF
# QA Scenarios — $PLUGIN_SLUG

_Auto-generated by Orbit test scaffolder. Review and edit before using as a
real test plan._

Plugin type: **$PLUGIN_TYPE** &nbsp;·&nbsp; Version: \`$VERSION\`

---

## Smoke scenarios (MUST PASS on every release)

### S-01 — Activation does not fatal
Steps: Fresh WP install → upload plugin zip → activate.
Pass: no white screen, no PHP fatal in debug.log, plugin appears in active list.

### S-02 — Deactivation does not fatal
Steps: From active plugin → Deactivate.
Pass: no error notice, no admin page inaccessible.

### S-03 — Uninstall cleans up
Steps: Deactivate → Delete.
Pass: \`scripts/check-zip-hygiene.sh\` after delete shows no \`$PREFIX*\` options, transients, or custom tables remaining. Covered by \`tests/playwright/flows/uninstall-cleanup.spec.js\`.

SCENARIOS_EOF

# Admin page scenarios
if [ "$COUNT_ADMIN" -gt 0 ]; then
  echo "" >> "$OUT_DIR/qa-scenarios.md"
  echo "## Admin page scenarios" >> "$OUT_DIR/qa-scenarios.md"
  N=10
  for slug in $ADMIN_PAGES; do
    [ -z "$slug" ] && continue
    cat >> "$OUT_DIR/qa-scenarios.md" << EOF

### A-$N — Admin page loads: \`$slug\`
Steps: Log in as admin → navigate to \`/wp-admin/admin.php?page=$slug\`.
Pass: 200 OK, no permission error, no PHP warning in debug.log, keyboard-navigable, works under all 9 admin color schemes.
Verified by: \`keyboard-nav.spec.js\`, \`admin-color-schemes.spec.js\`.
EOF
    N=$((N + 1))
  done
fi

# Shortcode scenarios
if [ "$COUNT_SHORT" -gt 0 ]; then
  echo "" >> "$OUT_DIR/qa-scenarios.md"
  echo "## Shortcode scenarios" >> "$OUT_DIR/qa-scenarios.md"
  N=20
  for sc in $SHORTCODES; do
    [ -z "$sc" ] && continue
    cat >> "$OUT_DIR/qa-scenarios.md" << EOF

### SC-$N — Shortcode \`[$sc]\` renders without error
Steps: Create a page → add the block \`[$sc]\` → publish → view front-end.
Pass: rendered HTML doesn't contain the literal string \`[$sc]\` (would mean shortcode didn't resolve), no JS console errors.
Security check: test with malformed attributes (\`[$sc evil="<script>alert(1)</script>"]\`) — output must be escaped.
EOF
    N=$((N + 1))
  done
fi

# REST scenarios
if [ "$COUNT_REST" -gt 0 ]; then
  echo "" >> "$OUT_DIR/qa-scenarios.md"
  echo "## REST API scenarios" >> "$OUT_DIR/qa-scenarios.md"
  N=30
  for route in $REST_ROUTES; do
    [ -z "$route" ] && continue
    cat >> "$OUT_DIR/qa-scenarios.md" << EOF

### R-$N — REST route \`/wp-json/$route\` enforces auth
Steps: Call GET/POST with (a) no auth, (b) subscriber app password, (c) admin app password.
Pass: (a) returns 401 or schema permits anonymous, (b) returns 401/403 for admin endpoints, (c) returns 2xx with schema-compliant body.
IDOR check: if route has \`(?P<id>\d+)\`, test that a user cannot access another user's object.
Verified by: \`app-passwords.spec.js\`.
EOF
    N=$((N + 1))
  done
fi

# AJAX scenarios
if [ "$COUNT_AJAX" -gt 0 ]; then
  echo "" >> "$OUT_DIR/qa-scenarios.md"
  echo "## AJAX action scenarios" >> "$OUT_DIR/qa-scenarios.md"
  N=40
  for a in $AJAX_PRIV; do
    [ -z "$a" ] && continue
    cat >> "$OUT_DIR/qa-scenarios.md" << EOF

### AJ-$N — \`wp_ajax_$a\` rejects unauthenticated
Steps: POST to \`/wp-admin/admin-ajax.php\` with \`action=$a\` (a) logged out, (b) nonce missing, (c) nonce invalid, (d) subscriber, (e) admin.
Pass: (a)-(d) return 401/403 OR die('0'), (e) returns success. Capability check must match the sensitivity of the action.
EOF
    N=$((N + 1))
  done
  for a in $AJAX_NOPRIV; do
    [ -z "$a" ] && continue
    cat >> "$OUT_DIR/qa-scenarios.md" << EOF

### AJ-$N — \`wp_ajax_nopriv_$a\` is safe for unauthenticated callers
WARNING: nopriv AJAX is public. Steps: spam the endpoint with garbage POST + XSS payloads + SQLi payloads.
Pass: no DB writes that change auth state, no \`update_option\` called, all input sanitized, all output escaped.
EOF
    N=$((N + 1))
  done
fi

# Cron scenarios
if [ "$COUNT_CRON" -gt 0 ]; then
  echo "" >> "$OUT_DIR/qa-scenarios.md"
  echo "## Cron scenarios" >> "$OUT_DIR/qa-scenarios.md"
  N=50
  for hook in $CRON_HOOKS; do
    [ -z "$hook" ] && continue
    cat >> "$OUT_DIR/qa-scenarios.md" << EOF

### C-$N — Cron hook \`$hook\` registers + clears
Steps: Activate plugin → \`wp cron event list\` should include \`$hook\`. Deactivate → hook should be removed.
Pass: exact-match presence and absence. Deactivation leaving cron events = memory leak on real sites.
EOF
    N=$((N + 1))
  done
fi

# Block scenarios
if [ "$COUNT_BLOCKS" -gt 0 ]; then
  echo "" >> "$OUT_DIR/qa-scenarios.md"
  echo "## Gutenberg block scenarios" >> "$OUT_DIR/qa-scenarios.md"
  N=60
  for b in $BLOCKS; do
    [ -z "$b" ] && continue
    cat >> "$OUT_DIR/qa-scenarios.md" << EOF

### B-$N — Block \`$b\` inserts + saves + reloads
Steps: Editor → "+" → search "$b" → insert → save post → reload edit screen.
Pass: no "block validation error", no console errors, block.json apiVersion: 3 (required for iframe sandbox, WP 6.3+).
Verified by: \`block-deprecation.spec.js\`.
EOF
    N=$((N + 1))
  done
fi

# WC-specific
if [ "$WC_FLAG" = "True" ]; then
  cat >> "$OUT_DIR/qa-scenarios.md" << EOF

## WooCommerce scenarios

### W-01 — HPOS compatibility declared
Steps: Activate plugin on WC 8.2+ with HPOS enabled.
Pass: \`FeaturesUtil::declare_compatibility('custom_order_tables', __FILE__, true)\` fires on \`before_woocommerce_init\`. No "incompatible" banner in WC → Status.

### W-02 — Uses wc_get_order, not get_post_meta(\$order_id)
Steps: Under HPOS, any code path that reads order meta.
Pass: uses \`\$order->get_meta()\` — verified by \`check-hpos-declaration.sh\`.
EOF
fi

# Closing — security + perf checklist
cat >> "$OUT_DIR/qa-scenarios.md" << 'EOF'

---

## Cross-cutting checks (all of the above must also pass)

- [ ] No PHP Deprecation notices on PHP 8.1 / 8.3 (debug.log clean)
- [ ] axe-core WCAG 2.2 AA: 0 critical, 0 serious
- [ ] Peak memory < 32MB per request
- [ ] No N+1 DB queries on any admin page
- [ ] Every form submit has a nonce + capability check
- [ ] Every echoed DB value goes through esc_html / esc_attr / esc_url
- [ ] Plugin works alongside top 20 popular plugins (see `plugin-conflict.spec.js`)
- [ ] RTL layout in Arabic locale — no horizontal overflow
- [ ] Uninstall removes every `<prefix>*` option + transient + user_meta + capability

EOF

echo -e "${GREEN}✓${NC} Wrote $OUT_DIR/qa-scenarios.md ($(wc -l < "$OUT_DIR/qa-scenarios.md") lines)"

# ─── Generate a draft Playwright spec for the first admin page ───────────────
if [ -n "$FIRST_ADMIN" ]; then
  SPEC_FILE="tests/playwright/flows/scaffold-${PLUGIN_SLUG}-smoke.spec.js"
  cat > "$SPEC_FILE" << EOF
// @ts-check
// Orbit scaffold — $PLUGIN_SLUG smoke
// Auto-generated. Tune selectors and assertions to match actual UI.

const { test, expect } = require('@playwright/test');
const { attachConsoleErrorGuard, assertPageReady } = require('../helpers');

const PLUGIN_SLUG = process.env.PLUGIN_SLUG || '$PLUGIN_SLUG';

test.describe('$PLUGIN_SLUG — smoke', () => {
  test('first admin page loads cleanly', async ({ page }) => {
    const guard = attachConsoleErrorGuard(page);
    await page.goto('/wp-admin/admin.php?page=$FIRST_ADMIN');
    await assertPageReady(page, '$FIRST_ADMIN');
    await expect(page.locator('#wpbody-content')).toBeVisible();
    guard.assertClean('$FIRST_ADMIN');
  });
EOF

  # Add one smoke check per shortcode
  for sc in $SHORTCODES; do
    [ -z "$sc" ] && continue
    cat >> "$SPEC_FILE" << EOF

  test('shortcode [$sc] renders (not left literal)', async ({ page }) => {
    // You need a page/post that contains [$sc] — create via fixture or WP-CLI.
    const url = process.env.TEST_URL_SHORTCODE_$(echo "$sc" | tr 'a-z-' 'A-Z_');
    test.skip(!url, 'Set TEST_URL_SHORTCODE_$(echo "$sc" | tr 'a-z-' 'A-Z_') to a page containing this shortcode');
    await page.goto(url);
    const body = await page.locator('body').innerText();
    expect(body, 'Shortcode should not be left as literal text').not.toContain('[$sc');
  });
EOF
  done

  echo "});" >> "$SPEC_FILE"
  echo -e "${GREEN}✓${NC} Wrote $SPEC_FILE"
fi

# ─── Optional: deep AI scaffolding ───────────────────────────────────────────
if [ "$DEEP" -eq 1 ]; then
  if command -v claude &>/dev/null; then
    echo ""
    echo -e "${CYAN}→ Running /orbit-scaffold-tests for AI-augmented scenarios...${NC}"
    claude "/orbit-scaffold-tests
Read the plugin source at: $PLUGIN_PATH
Generate:
1. Business-logic QA scenarios (not auto-detectable entry-point ones, but the actual feature flows).
2. Edge cases specific to what this plugin does (not generic WP checks).
3. One Playwright spec per high-value flow.

Output Markdown to stdout. Be concrete — file:line references, exact selectors,
actual user intent. No generic 'test that it works' — write the steps a human
QA engineer would write after 30 minutes of reading the code." \
    > "$OUT_DIR/ai-scenarios.md" 2>"$OUT_DIR/ai-scenarios.err" || true
    if [ -s "$OUT_DIR/ai-scenarios.md" ]; then
      echo -e "${GREEN}✓${NC} Wrote $OUT_DIR/ai-scenarios.md"
    else
      echo -e "${YELLOW}⚠${NC} AI scenarios generation produced no output — check $OUT_DIR/ai-scenarios.err"
    fi
  else
    echo -e "${YELLOW}⚠${NC} --deep requested but 'claude' CLI not installed. Skipping AI step."
  fi
fi

echo ""
echo -e "${CYAN}── Done ──${NC}"
echo "  Config:       $OUT_DIR/qa.config.json"
echo "  Scenarios:    $OUT_DIR/qa-scenarios.md"
[ -n "$FIRST_ADMIN" ] && echo "  Smoke spec:   tests/playwright/flows/scaffold-${PLUGIN_SLUG}-smoke.spec.js"
[ "$DEEP" -eq 1 ] && [ -s "$OUT_DIR/ai-scenarios.md" ] && echo "  AI scenarios: $OUT_DIR/ai-scenarios.md"
echo ""
echo "Next:"
echo "  1. Review $OUT_DIR/qa.config.json — tune any wrong guesses"
echo "  2. Copy to your plugin: cp $OUT_DIR/qa.config.json ~/plugins/$PLUGIN_SLUG/qa.config.json"
echo "  3. Edit the scaffolded spec with real selectors + user intent"
echo "  4. Run:  bash scripts/gauntlet.sh --plugin $PLUGIN_PATH --mode full"
