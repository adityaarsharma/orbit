#!/usr/bin/env bash
# seed-brain.sh — Bootstrap Orbit starter brain on brain-posimyth
#
# Usage:
#   bash brain/seed-brain.sh --key <orbit-admin-key>
#   bash brain/seed-brain.sh --key <key> --dry-run      # preview only
#   bash brain/seed-brain.sh --key <key> --namespace custom/ns  # override namespace
#
# Requires: curl, jq
# Brain endpoint: brain.posimyth.com/connectors (orbit tenant)

set -euo pipefail

BRAIN_URL="https://brain.posimyth.com/connectors"
NAMESPACE="orbit/00-cto/hard-rules"
DRY_RUN=false
ADMIN_KEY=""

# ── Arg parsing ───────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --key)         ADMIN_KEY="$2";    shift 2 ;;
    --namespace)   NAMESPACE="$2";   shift 2 ;;
    --dry-run)     DRY_RUN=true;     shift   ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

if [[ -z "$ADMIN_KEY" ]]; then
  echo "ERROR: --key <orbit-admin-key> is required."
  echo "       Get your Admin key from brain.posimyth.com admin panel → Tenants → orbit"
  exit 1
fi

# ── Helpers ───────────────────────────────────────────────────────────────────
ingest() {
  local label="$1"
  local tags="$2"   # JSON array string
  local body="$3"

  if $DRY_RUN; then
    echo "  [dry-run] WOULD ingest: $label"
    return
  fi

  # Brain connectors API: POST /connectors with a JSON-RPC tools/call envelope invoking
  # posimyth_brain_add_note. Field is `content`; scope is wing+room. wing="orbit" room="knowledge"
  # keeps all knowledge drawers in the Orbit wing, isolated from the general/GC brain.
  local payload
  payload=$(jq -n \
    --arg body "$body" \
    --argjson tags "$tags" \
    '{jsonrpc:"2.0",id:1,method:"tools/call",params:{name:"posimyth_brain_add_note",arguments:{content:$body,wing:"orbit",room:"knowledge",tags:$tags}}}')

  local resp
  resp=$(curl -s -m 25 \
    -X POST "$BRAIN_URL" \
    -H "Authorization: Bearer $ADMIN_KEY" \
    -H "Content-Type: application/json" \
    -d "$payload")

  if echo "$resp" | grep -q 'drawer_id'; then
    echo "  ✓ $label"
  else
    echo "  ✗ $label — ${resp:0:160}"
  fi
}

check_deps() {
  for dep in curl jq; do
    if ! command -v "$dep" &>/dev/null; then
      echo "ERROR: $dep is required. Install it and retry."
      exit 1
    fi
  done
}

# ── Pre-flight ────────────────────────────────────────────────────────────────
check_deps

echo ""
echo "🪐 Orbit Brain Seeder — v3.0"
echo "   Endpoint : $BRAIN_URL"
echo "   Namespace: $NAMESPACE"
$DRY_RUN && echo "   Mode     : DRY RUN (no writes)"
echo ""

# Test connectivity + key validity (whoami is the read-only auth endpoint)
if ! $DRY_RUN; then
  test_status=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer $ADMIN_KEY" \
    "$BRAIN_URL/whoami" 2>/dev/null || echo "000")
  if [[ "$test_status" != "200" ]]; then
    echo "ERROR: Could not reach $BRAIN_URL/whoami (HTTP $test_status)"
    echo "       Check your Admin key and network connection."
    exit 1
  fi
  echo "✓ Brain connection verified"
  echo ""
fi

# ── Category 1: WordPress Coding Standards ────────────────────────────────────
echo "── WP Standards (8 drawers)"

ingest "WP escaping rules" \
  '["orbit","knowledge","wp-standards","escaping"]' \
  "WordPress output escaping rules:
- esc_html() — any plain text output
- esc_attr() — HTML attribute values
- esc_url() — URLs in href/src
- esc_js() — inline JavaScript values
- wp_kses_post() — HTML with allowed tags (post content)
- Never echo untrusted input without escaping
- Always escape at output time, not at input time
Source: https://developer.wordpress.org/apis/security/escaping/"

ingest "WP nonce patterns" \
  '["orbit","knowledge","wp-standards","nonces"]' \
  "WordPress nonce patterns:
- wp_create_nonce('action-name') — create nonce in PHP
- wp_nonce_field('action', '_wpnonce') — add to form
- check_admin_referer('action') — verify in form handlers
- check_ajax_referer('action', 'nonce') — verify in AJAX
- wp_verify_nonce(\$_POST['_wpnonce'], 'action') — manual check
- Nonces expire after 12-24 hours; never cache pages with nonces
Source: https://developer.wordpress.org/apis/security/nonces/"

ingest "WP capability checks" \
  '["orbit","knowledge","wp-standards","capabilities"]' \
  "WordPress capability check patterns:
- current_user_can('manage_options') — admin settings
- current_user_can('edit_posts') — post editing
- current_user_can('upload_files') — media library
- map_meta_cap() for object-level caps (edit_post, \$post_id)
- NEVER use user role directly (if (\$user->role === 'administrator'))
- Always check capability, not role
- REST: permission_callback must not be __return_true on sensitive endpoints
Source: https://developer.wordpress.org/apis/security/user-capabilities/"

ingest "WP sanitization rules" \
  '["orbit","knowledge","wp-standards","sanitization"]' \
  "WordPress input sanitization:
- sanitize_text_field() — single-line text inputs
- sanitize_textarea_field() — multi-line text
- sanitize_email() — email addresses
- absint() — positive integers
- intval() — integers
- sanitize_key() — slugs, keys, identifiers
- sanitize_title() — post slugs
- wp_kses_post() — HTML input where HTML is expected
- Sanitize at input time (save), escape at output time
Source: https://developer.wordpress.org/apis/security/sanitizing/"

ingest "WP database patterns (\$wpdb)" \
  '["orbit","knowledge","wp-standards","wpdb"]' \
  "WordPress \$wpdb safe patterns:
- \$wpdb->prepare() REQUIRED for all queries with user input
- \$wpdb->get_results(\$wpdb->prepare('SELECT ... WHERE id = %d', \$id))
- Use %d for integers, %s for strings, %f for floats in prepare()
- Never interpolate variables directly into SQL
- Always use \$wpdb->prefix for table names
- Custom tables: create with dbDelta() in activation hook
Source: https://developer.wordpress.org/reference/classes/wpdb/"

ingest "WP plugin file structure" \
  '["orbit","knowledge","wp-standards","file-structure"]' \
  "WordPress plugin file structure requirements:
- Main plugin file: plugin-slug/plugin-slug.php with Plugin header
- Required header fields: Plugin Name, Description, Version, Requires at least, Requires PHP, Author, License
- readme.txt: follows WordPress.org format (== sections ==)
- Uninstall: uninstall.php (not register_uninstall_hook for security)
- Class file naming: class-plugin-name.php (lowercase, hyphens)
- Functions: prefixed with plugin slug (myplugin_function_name)
Source: https://developer.wordpress.org/plugins/plugin-basics/header-requirements/"

ingest "WP i18n patterns" \
  '["orbit","knowledge","wp-standards","i18n"]' \
  "WordPress i18n (internationalisation) patterns:
- __('string', 'textdomain') — translate and return
- _e('string', 'textdomain') — translate and echo
- esc_html__() / esc_html_e() — translate + escape
- _n('singular', 'plural', \$count, 'textdomain') — plurals
- _x('string', 'context', 'textdomain') — with context for translators
- sprintf() with translated strings for variables
- NEVER concatenate translated strings with variables
- load_plugin_textdomain() in 'init' hook (not 'plugins_loaded' for block plugins)
Source: https://developer.wordpress.org/plugins/internationalization/"

ingest "WP hooks best practices" \
  '["orbit","knowledge","wp-standards","hooks"]' \
  "WordPress hooks best practices:
- Use specific hook names; avoid action/filter soup
- Priority 10 is default; use 5 for early, 20 for late; avoid 1 and 999
- add_filter() must return a value; missing return = content deleted
- remove_action/filter needs exact priority + accepted_args match
- Prefer actions over direct function calls for extensibility
- Hook names: plugin-slug/hookname (slash-namespaced, WP 6.1+)
- NEVER hook into 'plugins_loaded' for heavy work; use appropriate late hooks
Source: https://developer.wordpress.org/plugins/hooks/"

# ── Category 2: Block Editor ──────────────────────────────────────────────────
echo ""
echo "── Block Editor (6 drawers)"

ingest "block.json required fields" \
  '["orbit","knowledge","block-editor","block-json"]' \
  "block.json required and important fields (apiVersion 3, WP 6.3+):
Required: \$schema, name (namespace/block-name format), version, title, category, editorScript
Strongly recommended: description, icon, textdomain, attributes, supports, example
- apiVersion: 3 (current, enables block hooks + style variations)
- name: must be 'namespace/block-name' — namespace must be plugin slug
- textdomain: must match plugin textdomain
- editorScript: 'file:./index.js' (relative path)
- viewScript: 'file:./view.js' (only if needed on frontend)
- render: 'file:./render.php' (for dynamic/server-side blocks)
- style/editorStyle: use block.json, not wp_register_style() for block styles
Source: https://developer.wordpress.org/block-editor/reference-guides/block-api/block-metadata/"

ingest "Block save vs SSR" \
  '["orbit","knowledge","block-editor","save-vs-ssr"]' \
  "Block save() vs server-side rendering (SSR):
- save() → static HTML saved in post_content. Must be stable. Breaking changes require deprecations.
- render.php → dynamic block. Re-renders on every frontend request. No deprecation needed.
- Dynamic blocks (render.php): always return 'null' from save() or use useBlockProps.save()
- When to use SSR: block output depends on current state (user, date, query results)
- When to use save(): purely static content (heading, image, button)
- save() validation: if saved HTML doesn't match, block becomes 'invalid' — shows red error in editor
- NEVER use random values (Math.random, Date.now) in save() — they break validation
Source: https://developer.wordpress.org/block-editor/reference-guides/block-api/block-edit-save/"

ingest "Block attributes best practices" \
  '["orbit","knowledge","block-editor","attributes"]' \
  "Block attributes best practices:
- Declare ALL data in attributes (not component state) — attributes are serialised to post_content
- attribute types: string, number, boolean, array, object, null
- source: 'attribute' (read from DOM), 'html' (inner HTML), 'query' (repeated), 'text', 'raw'
- Default values: always set defaults for all attributes
- Never store derived data as attributes
- Use useBlockProps() in edit() and useBlockProps.save() in save()
- RichText: use value prop + onChange, allowedFormats for control
- InnerBlocks: use template + templateLock for structured content
Source: https://developer.wordpress.org/block-editor/reference-guides/block-api/block-attributes/"

ingest "Block editor hooks" \
  '["orbit","knowledge","block-editor","editor-hooks"]' \
  "Block editor hook patterns:
- register_block_type() — register with block.json path (preferred over array args)
- render_block filter — modify block HTML on frontend (use sparingly)
- blocks.registerBlockType JS filter — modify block settings
- editor.BlockEdit JS filter — wrap block edit with HOC
- blocks.getSaveElement JS filter — DANGEROUS: breaks post validation; avoid
- enqueue_block_editor_assets — only for editor-side scripts
- enqueue_block_assets — editor + frontend (use block.json editorStyle/style instead)
- register_block_type in 'init' hook; never on 'wp_enqueue_scripts'
Source: https://developer.wordpress.org/block-editor/reference-guides/filters/block-filters/"

ingest "Interactivity API patterns" \
  '["orbit","knowledge","block-editor","interactivity-api"]' \
  "WordPress Interactivity API (WP 6.5+ stable):
- Replaces custom frontend JS for interactive blocks
- Server: wp_interactivity_state() to set initial state
- Block: data-wp-interactive='namespace' on root element
- Actions: data-wp-on--click='actions.toggle'
- State: data-wp-bind--class='state.isOpen'
- Context: data-wp-context='{\"isOpen\": false}'
- Directives: wp-bind, wp-class, wp-style, wp-text, wp-on, wp-watch, wp-init, wp-context, wp-each
- viewScriptModule in block.json for ES module (not viewScript)
- INP signal: avoid heavy synchronous JS in actions
Source: https://developer.wordpress.org/block-editor/reference-guides/packages/packages-interactivity/"

ingest "FSE (Full-Site Editing) compat" \
  '["orbit","knowledge","block-editor","fse"]' \
  "Full-Site Editing (FSE) compatibility rules:
- theme.json schema v3 (WP 6.6+): supports fluid typography, layout sizing
- Block templates: registered via block.json templateTypes array
- Block template parts: 'header', 'footer', 'sidebar'
- Style variations: theme.json fragments in /styles directory
- Block locking: lock attribute controls move/remove in editor
- Synced patterns (formerly reusable blocks): wp_block post type
- Query Loop: avoid overriding WP_Query; use query filters instead
- Site editor compatibility check: test with Twenty Twenty-Four (reference FSE theme)
Source: https://developer.wordpress.org/themes/global-settings-and-styles/"

# ── Category 3: Elementor ─────────────────────────────────────────────────────
echo ""
echo "── Elementor (4 drawers)"

ingest "Elementor widget registration" \
  '["orbit","knowledge","elementor","widget-registration"]' \
  "Elementor widget registration patterns:
- Extend \Elementor\Widget_Base
- get_name(): must return unique slug (POSIMYTH prefix: 'tp-widget-slug')
- get_title(): translated display name
- get_icon(): Elementor icon class (eicon-*) or custom font icon
- get_categories(): ['basic'] or custom category slug
- register in elementor/widgets/register action (NOT elementor_widgets_registered, deprecated)
- Unregister deprecated widgets: elementor/widgets/unregister
- File naming: class-widget-name.php in /widgets/ directory
- NEVER directly instantiate; always register via Plugin::instance()->widgets_manager
Source: fetch live from https://developers.elementor.com/docs/widgets/creating-a-new-widget/"

ingest "Elementor control types" \
  '["orbit","knowledge","elementor","controls"]' \
  "Elementor control types reference:
- TEXT, TEXTAREA — string inputs
- NUMBER — numeric input
- SELECT, SELECT2 — dropdowns
- CHOOSE — visual button group
- SWITCHER — toggle boolean
- COLOR — color picker (use global colors)
- TYPOGRAPHY — typography composite (font, size, weight, etc.)
- DIMENSIONS — top/right/bottom/left with link
- SLIDER — range with units
- MEDIA — image/video selector (returns array with url, id)
- ICONS — icon picker (Elementor icon library)
- URL — link with target/nofollow options
- REPEATER — repeatable field group
- SECTION/TAB — visual grouping only (no value)
- Pro: GALLERY, DATE_TIME, CODE, WYSIWYG
Selectors: use CSS selectors with {{WRAPPER}} placeholder
Source: fetch live from https://developers.elementor.com/docs/controls/"

ingest "Elementor skin system" \
  '["orbit","knowledge","elementor","skins"]' \
  "Elementor skin (style variant) system:
- Extend \Elementor\Skin_Base
- get_id(): unique skin identifier
- get_title(): translated skin name
- register via \$this->add_skin() inside _register_skins() in widget
- Skins inherit all parent widget controls; add skin-specific controls with parent::_register_controls()
- Use \$this->get_instance_value('control_name') to read controls inside skin
- render() method in skin overrides widget's render()
- When to use skins: same widget data, different visual output (card vs list vs grid)
- When NOT to use skins: genuinely different functionality → separate widget
Source: fetch live from https://developers.elementor.com/docs/skins/"

ingest "Elementor dynamic tags" \
  '["orbit","knowledge","elementor","dynamic-tags"]' \
  "Elementor dynamic tags:
- Extend \Elementor\Core\DynamicTags\Tag (text) or \Elementor\Core\DynamicTags\Data_Tag (structured)
- get_name(): unique tag identifier
- get_title(): translated display name
- get_group(): tag category ('post', 'site', 'media', 'author', 'archive', 'contact', 'url', 'action')
- get_categories(): which control types accept this tag (TEXT, URL, IMAGE, MEDIA, etc.)
- render(): outputs the dynamic value — ALWAYS escape output
- Pro-only check: wrap Pro controls with \Elementor\Plugin::elementor()->is_pro()
- Register via elementor/dynamic_tags/register action
- NEVER store sensitive data in tag defaults
Source: fetch live from https://developers.elementor.com/docs/dynamic-tags/"

# ── Category 4: Security Patterns ─────────────────────────────────────────────
echo ""
echo "── Security (5 drawers)"

ingest "XSS patterns in WordPress plugins" \
  '["orbit","knowledge","security","xss"]' \
  "Common XSS patterns in WordPress plugins to catch:
HIGH RISK:
- echo \$_GET['param'] — direct reflected XSS
- echo get_option('setting') without escaping — stored XSS
- echo \$_POST['content'] — form input XSS
- innerHTML in JS with untrusted data
MEDIUM RISK:
- echo \$atts['title'] in shortcode output without esc_html()
- wp_localize_script() passing unescaped PHP values to JS
- Elementor widget render() without esc_html() on attribute values
FIXES:
- PHP output: always esc_html(), esc_attr(), esc_url() at echo
- JS: use textContent not innerHTML; escape with wp_json_encode() for localize
Source: https://patchstack.com/articles/common-wordpress-plugin-vulnerabilities/"

ingest "SQL injection patterns" \
  '["orbit","knowledge","security","sql-injection"]' \
  "SQL injection patterns in WordPress:
VULNERABLE:
- \$wpdb->query('SELECT * FROM table WHERE id = ' . \$_GET['id'])
- \$wpdb->get_results('SELECT * WHERE slug = \"' . \$slug . '\"')
- Direct variable interpolation in any \$wpdb method
SAFE:
- \$wpdb->prepare('SELECT * WHERE id = %d', absint(\$_GET['id']))
- \$wpdb->prepare('SELECT * WHERE slug = %s', sanitize_text_field(\$slug))
- Use %d for integers, %s for strings, %f for floats
GOTCHAS:
- prepare() with IN() clause: use implode + array_fill for placeholder list
- LIKE queries: use \$wpdb->esc_like() before prepare()
- ORDER BY column: whitelist allowed columns (cannot use prepare for column names)
Source: https://developer.wordpress.org/apis/security/sql-injection/"

ingest "CSRF nonce verification in AJAX" \
  '["orbit","knowledge","security","csrf-ajax"]' \
  "CSRF protection for AJAX handlers:
FORM AJAX (wp_ajax_*):
  PHP:
    add_action('wp_ajax_my_action', 'my_handler');
    add_action('wp_ajax_nopriv_my_action', 'my_public_handler');
    function my_handler() {
      check_ajax_referer('my-action-nonce', 'nonce');
      // ... handler code
    }
  JS:
    wp_localize_script('handle', 'myPlugin', ['nonce' => wp_create_nonce('my-action-nonce')])
    data: { action: 'my_action', nonce: myPlugin.nonce }

REST API:
  register_rest_route with permission_callback — never '__return_true' for sensitive routes
  WP sends nonce via X-WP-Nonce header automatically (wp.apiFetch)

CRITICAL:
  wp_ajax_nopriv_* handlers MUST verify nonce AND check what data is exposed
  Omitting check_ajax_referer on nopriv handlers = unauthenticated CSRF
Source: https://developer.wordpress.org/plugins/security/nonces/"

ingest "Path traversal and file inclusion" \
  '["orbit","knowledge","security","path-traversal"]' \
  "Path traversal and file inclusion patterns:
VULNERABLE:
- include \$_GET['template'] . '.php'
- file_get_contents(PLUGIN_DIR . '/' . \$user_input)
- require_once(get_template_directory() . '/' . \$_REQUEST['file'])

SAFE PATTERNS:
- Whitelist allowed files: \$allowed = ['header', 'footer']; if (!in_array(\$input, \$allowed)) wp_die()
- Use basename() to strip directory traversal: \$file = basename(\$_GET['file'])
- Validate file exists within expected directory: realpath() check
- NEVER include user-controlled paths directly

ABSPATH guard:
  Add at top of every PHP file:
  if (!defined('ABSPATH')) exit;  // prevents direct file access
Source: https://patchstack.com/articles/wordpress-plugin-vulnerabilities/#file-inclusion"

ingest "Secrets exposure patterns" \
  '["orbit","knowledge","security","secrets"]' \
  "API key and secrets exposure patterns:
RISK VECTORS:
- API key stored in wp_options and exposed in REST API (public endpoint)
- Secret key in JavaScript (wp_localize_script) — visible in browser source
- License key in error messages or debug logs
- .env file committed to git or in plugin zip
- Stripe live key in client-side code (must be secret-key on server only)

SAFE PATTERNS:
- Store secrets in wp_options with autoload='no', retrieve server-side only
- Never pass secret keys to wp_localize_script; use only public keys
- Stripe: public key (pk_live_) in JS is fine; secret key (sk_live_) server-side only
- License keys: encrypt at rest, never log, never include in REST responses
- .gitignore: .env, local-config.php, wp-config.php
Source: https://patchstack.com/articles/wordpress-plugin-vulnerabilities/#information-disclosure"

# ── Category 5: Performance ───────────────────────────────────────────────────
echo ""
echo "── Performance (4 drawers)"

ingest "Hook weight and autoload rules" \
  '["orbit","knowledge","performance","hook-weight"]' \
  "WordPress performance: hook weight and autoload rules:
HOOK PERFORMANCE:
- add_action/filter with heavy callback on every request = performance tax
- Move expensive setup to specific hooks (admin_init, not init for admin-only work)
- Use is_admin() guards to skip frontend work in admin context
- Lazy-load: initialize objects only when first used
- Transients: cache expensive computations (get_transient / set_transient)

AUTOLOAD OPTIONS (autoload='yes' loads every request):
- Maximum total autoload data: 800KB guideline (orbit threshold: flag > 1MB)
- Never autoload large serialized arrays (use get_option() on-demand instead)
- Per-option size: individual option > 100KB is a flag
- Audit: SELECT option_name, LENGTH(option_value) FROM wp_options WHERE autoload='yes' ORDER BY 2 DESC

TRANSIENT EXPLOSION:
- Custom transients without expiry pile up in wp_options
- Always set expiry: set_transient('key', \$val, HOUR_IN_SECONDS)
Source: https://developer.wordpress.org/plugins/settings/options-api/"

ingest "N+1 query patterns" \
  '["orbit","knowledge","performance","n-plus-one"]' \
  "N+1 query patterns in WordPress plugins:
PATTERNS TO CATCH:
- foreach (\$posts as \$post) { get_post_meta(\$post->ID, 'key', true) }
  → Use: get_posts(['meta_key' => 'key', 'fields' => 'all']) or prime meta cache
- foreach (\$user_ids as \$id) { get_userdata(\$id) }
  → Use: get_users(['include' => \$user_ids]) to batch
- Multiple WP_Query calls in a loop
  → Use: 'post__in' or 'meta_query' to combine

CACHE PRIMING:
- update_post_meta_cache(\$post_ids) — prime post meta cache before loop
- update_object_term_cache(\$post_ids, 'post') — prime taxonomy cache
- WP_Query with 'update_post_meta_cache' => true (default) does this automatically

DETECTION:
- Use Query Monitor plugin or \$wpdb->num_queries before/after
- Orbit threshold: > 5 new queries per page vs baseline = flag
Source: https://developer.wordpress.org/reference/functions/update_post_meta_cache/"

ingest "Asset loading best practices" \
  '["orbit","knowledge","performance","asset-loading"]' \
  "WordPress asset loading best practices:
SCRIPTS:
- wp_register_script() + conditional wp_enqueue_script() (only load where needed)
- 'in_footer' => true for non-critical scripts (not render-blocking)
- 'strategy' => 'defer' or 'async' for WP 6.3+ (Script Strategy API)
- wp_script_add_data(\$handle, 'defer', true) for older compat
- wp_add_inline_script() for small JS config (not wp_localize_script for non-data)
- Dependency array: always declare ['jquery', 'wp-element'] etc.

STYLES:
- wp_register_style() + conditional enqueue
- media='print' for print-only styles
- Preload critical CSS: wp_add_inline_style() for above-fold

BLOCK EDITOR:
- Use block.json editorScript/editorStyle/script/style — auto-enqueues per block presence
- viewScriptModule for ES modules with Interactivity API
- NEVER wp_enqueue_scripts for block editor assets — use block.json or enqueue_block_editor_assets
Source: https://developer.wordpress.org/reference/functions/wp_enqueue_script/"

ingest "Transient and object cache patterns" \
  '["orbit","knowledge","performance","cache"]' \
  "Transient and object cache patterns:
TRANSIENTS (persistent cache, stored in wp_options or object cache):
- set_transient(\$key, \$value, \$expiration) — always set expiration
- get_transient(\$key) — returns false on miss
- delete_transient(\$key) — invalidate on data change
- Multisite: set_site_transient() for network-wide cache
- Key length max: 172 characters (including _transient_ prefix)

OBJECT CACHE (in-memory, non-persistent by default):
- wp_cache_get(\$key, \$group) / wp_cache_set(\$key, \$value, \$group, \$ttl)
- wp_cache_delete(\$key, \$group)
- Group by plugin slug to avoid collisions
- Object cache survives within a single request even without Redis/Memcached
- With Redis/Memcached: survives across requests (like persistent transients but faster)

INVALIDATION RULE:
- Delete/update transient on any write that changes the cached data
- Use add_action hooks on save_post, update_option etc. to trigger invalidation
Source: https://developer.wordpress.org/apis/transients/"

# ── Category 6: Release ───────────────────────────────────────────────────────
echo ""
echo "── Release (5 drawers)"

ingest "readme.txt WordPress.org fields" \
  '["orbit","knowledge","release","readme-txt"]' \
  "WordPress.org readme.txt required fields and format:
HEADER FIELDS (must be present):
  === Plugin Name ===
  Contributors: comma-separated-slugs
  Tags: up-to-5-comma-separated-tags
  Requires at least: 6.3
  Tested up to: 6.7
  Stable tag: 1.2.3
  Requires PHP: 7.4
  License: GPLv2 or later
  License URI: https://www.gnu.org/licenses/gpl-2.0.html

REQUIRED SECTIONS:
  == Description == (marketing copy; shown on WP.org plugin page)
  == Installation == (numbered steps)
  == Changelog == (version entries, newest first)

RECOMMENDED SECTIONS:
  == Frequently Asked Questions ==
  == Screenshots == (filename: screenshot-1.png)
  == Upgrade Notice ==

GOTCHAS:
  - Stable tag must match plugin header Version exactly
  - Tested up to must be current WP version (update before each release)
  - Tags: only allowed tags from WP.org taxonomy (no invented tags)
Source: https://developer.wordpress.org/plugins/wordpress-org/how-your-readme-txt-works/"

ingest "WP.org plugin rejection reasons" \
  '["orbit","knowledge","release","rejection-reasons"]' \
  "Common WordPress.org plugin rejection reasons:
INSTANT REJECTION:
- Using external CDN for scripts/styles (must be bundled or use WP core)
- Calling remote URLs without user consent (privacy issue)
- Encrypted/obfuscated PHP code
- Selling plugins/features from wp-admin (upsells must be external links only)
- Trademark violation in plugin name (e.g. 'Elementor Pro by X')
- Plugin name that implies official WP/Automattic affiliation

HIGH REJECTION RISK:
- Missing security checks (nonces, capability checks, sanitization)
- Direct database calls without \$wpdb->prepare()
- wp_die() in production code (use return false or admin notices instead)
- Hardcoded domain/email addresses
- Generic plugin slug already taken (check wp.org/plugins/your-slug first)

COMMON REVISIONS REQUESTED:
- Plugin header missing Requires PHP
- i18n: missing textdomain or using wrong textdomain
- Scripts/styles loaded on all pages (should be conditional)
- Calling file_get_contents() for external URLs (use wp_remote_get())
Source: https://developer.wordpress.org/plugins/wordpress-org/detailed-plugin-guidelines/"

ingest "Semantic versioning for WP plugins" \
  '["orbit","knowledge","release","semver"]' \
  "Semantic versioning for WordPress plugins:
FORMAT: MAJOR.MINOR.PATCH (e.g. 1.4.2)
- MAJOR: breaking changes (requires migration, removes old features)
- MINOR: new features (backwards compatible)
- PATCH: bug fixes only (no new features)

WP PLUGIN CONVENTIONS:
- Version in plugin header, readme.txt Stable tag, AND package.json must all match
- Never skip versions (1.0.0 → 1.0.1 → 1.0.2, not 1.0.0 → 1.0.3)
- Pre-release: 1.5.0-beta.1, 1.5.0-rc.1 (not distributed on WP.org)
- Security fix: PATCH bump + add to Upgrade Notice in readme.txt
- WP.org SVN: tag your release (svn cp trunk tags/1.4.2)

POSIMYTH CONVENTION:
- Free plugins: public semver (WP.org)
- Pro plugins: semver (Freemius distribution)
- All version files updated in single commit before tag"

ingest "Zip hygiene for WP.org release" \
  '["orbit","knowledge","release","zip-hygiene"]' \
  "WordPress plugin zip hygiene rules:
MUST NOT INCLUDE in release zip:
- .git/ directory or .gitignore
- node_modules/ (bundle assets only; never include node_modules)
- vendor/ dev-only packages (composer --no-dev)
- .env or wp-config.php or any secrets files
- tests/ directory (not needed by end users)
- .DS_Store, Thumbs.db, *.log files
- Source maps (.map files) — only if bundled for debugging; exclude from production zip
- AI editor directories (.cursor/, .claude/, .aider/, .continue/, .windsurf/)
- phpunit.xml, phpcs.xml, .phpcs.xml.dist

MUST INCLUDE:
- All PHP files, JS/CSS bundles, images
- readme.txt (exactly)
- uninstall.php
- languages/ directory (POT + MO/PO files)
- LICENSE or license.txt

VERIFICATION:
  unzip -l plugin.zip | grep -E '(\.git|node_modules|\.env|vendor/.*dev)'
Source: https://developer.wordpress.org/plugins/wordpress-org/plugin-assets/"

ingest "Changelog format POSIMYTH" \
  '["orbit","knowledge","release","changelog-format"]' \
  "POSIMYTH changelog format rules (POSIMYTH voice):
FORMAT:
  = 1.4.2 =
  * [Fix] Settings page — save button unresponsive on Safari 17
  * [Improvement] Checkout widget — 40% faster on mobile (lazy-load media)
  * [New] Timeline block — scroll-triggered animations with 6 presets

POSIMYTH VOICE RULES:
  - Lead with USER BENEFIT, not technical action
    BAD:  'Refactored database query for performance'
    GOOD: 'Dashboard loads 2× faster — rewrote the settings query'
  - < 15 words per entry
  - No ticket/issue numbers
  - No internal jargon (no 'PR', 'refactor', 'hotfix', 'deploy')
  - Security entries: include CVE if assigned (= 1.4.3 = / * [Security] Fix XSS via ?search= — CVE-2026-12345)
  - Prefix: [New], [Fix], [Improvement], [Security], [Removed]

IN RELEASE NOTES (blog/email):
  - Expand the top 3-5 items with user-benefit context
  - Screenshots/GIFs for [New] items
  - Migration guide for [Removed] items"

# ── Category 7: Accessibility ─────────────────────────────────────────────────
echo ""
echo "── Accessibility (4 drawers)"

ingest "WCAG 2.2 AA admin checklist" \
  '["orbit","knowledge","accessibility","wcag-aa"]' \
  "WCAG 2.2 AA checklist for WordPress admin UI:
CRITICAL (must pass — blocks release):
  ✓ All form inputs have <label> or aria-label
  ✓ No keyboard traps (user can Tab into and out of all components)
  ✓ Color alone not used to convey meaning (add icon/text alongside color)
  ✓ Contrast ratio ≥ 4.5:1 for normal text (< 18pt)
  ✓ Contrast ratio ≥ 3:1 for large text (≥ 18pt or 14pt bold)
  ✓ All interactive elements have accessible names

HIGH (blocks release):
  ✓ Focus indicators visible on all interactive elements
  ✓ Error messages associated with input via aria-describedby
  ✓ Modal dialogs trap focus + restore focus on close (focus management)
  ✓ Touch targets ≥ 44×44px

MEDIUM:
  ✓ RTL layout mirrors correctly
  ✓ Dark mode uses CSS variables (not hardcoded)
  ✓ Empty states have actionable text + CTA

NEW IN WCAG 2.2 (2023):
  ✓ 2.4.11 — Focus not obscured (focused element at least partially visible)
  ✓ 2.5.3 — Label in name (visible label part of accessible name)
  ✓ 3.2.6 — Consistent help (help links same relative order across pages)
Source: https://www.w3.org/TR/WCAG22/"

ingest "Keyboard navigation patterns" \
  '["orbit","knowledge","accessibility","keyboard-nav"]' \
  "Keyboard navigation patterns for WP admin:
TAB ORDER:
- Must follow visual reading order (left→right, top→bottom)
- Skip link at top: 'Skip to main content' (#main-content)
- Logical group order: nav → main → sidebar → footer

INTERACTIVE ELEMENTS:
- All buttons, links, inputs reachable by Tab
- Custom widgets (modals, dropdowns, tabs): follow ARIA APG patterns
- Modal: Tab cycles within modal; Escape closes; focus returns to trigger
- Dropdown: arrow keys navigate items; Enter/Space select; Escape closes
- Tab component: arrow keys switch tabs; Tab moves to tab content

FOCUS STYLES:
- NEVER: :focus { outline: none } without alternative
- WP admin default: outline: 2px solid #2271b1 (blue, visible on white/dark)
- Custom: use outline not box-shadow (box-shadow ignored in Windows high contrast)
- Test with keyboard only — no mouse

ARIA ROLES:
- role='dialog' + aria-modal='true' + aria-labelledby for modals
- role='tablist' + role='tab' + role='tabpanel' for tabs
- role='menu' + role='menuitem' for dropdown menus
- aria-expanded on toggles; aria-live for dynamic updates
Source: https://www.w3.org/WAI/ARIA/apg/patterns/"

ingest "RTL layout rules" \
  '["orbit","knowledge","accessibility","rtl"]' \
  "RTL (Right-to-Left) layout rules for WordPress plugins:
CSS LOGICAL PROPERTIES (use instead of directional):
  margin-left    → margin-inline-start
  margin-right   → margin-inline-end
  padding-left   → padding-inline-start
  padding-right  → padding-inline-end
  border-left    → border-inline-start
  border-right   → border-inline-end
  left: 0        → inset-inline-start: 0
  right: 0       → inset-inline-end: 0
  text-align: left → text-align: start (or use :is([dir='rtl']) selector)
  float: left    → float: inline-start

WP RTL SUPPORT:
- Enqueue RTL stylesheet: wp_style_add_data(\$handle, 'rtl', 'replace')
- RTL stylesheet name: style-name-rtl.css
- Or: use logical properties throughout (no separate RTL file needed)
- Test with: <html dir='rtl' lang='ar'>

ICONS WITH DIRECTIONAL MEANING:
- Arrow icons (→, ←) must mirror in RTL
- Use transform: scaleX(-1) on .rtl .arrow-icon
- Or: use separate RTL icon

POSIMYTH NOTE: Products are used by Arabic/Persian users — RTL is mandatory, not optional.
Source: https://developer.wordpress.org/coding-standards/wordpress-coding-standards/css/#rtl-css"

ingest "Empty and error state requirements" \
  '["orbit","knowledge","accessibility","empty-error-states"]' \
  "Empty state and error state requirements:
EMPTY STATES (when list/table has no items):
  Required elements:
  - Descriptive message: 'No [items] found' (not just blank space)
  - Context: why it's empty when relevant ('You haven't added any X yet')
  - CTA (call to action): 'Add your first [item]' button/link
  - Illustration: optional, but helps (SVG icon of the item type)

  Orbit minimum severity: Medium (never just Info)

ERROR STATES (form validation, save failures, API errors):
  Required elements:
  - Error message visible near the field or top of form
  - aria-describedby linking input to error message
  - role='alert' or aria-live='assertive' for dynamically injected errors
  - Specific message: 'Email is required' not 'Field required'
  - For API errors: offer retry or alternative (not just 'Error')

ASYNC LOADING STATES:
  - Loading spinner + aria-busy='true' on container
  - Success: clear confirmation ('Settings saved' notice)
  - Error: clear failure notice with recovery path
  - Never leave user wondering if action worked

WP ADMIN NOTICE PATTERN:
  <div class='notice notice-error is-dismissible'><p>[message]</p></div>
Source: https://make.wordpress.org/design/handbook/patterns/notifications/"

# ── Category 8: Compatibility ──────────────────────────────────────────────────
echo ""
echo "── Compat (4 drawers)"

ingest "WPML compatibility requirements" \
  '["orbit","knowledge","compat","wpml"]' \
  "WPML compatibility requirements:
WPML CONFIG (wpml-config.xml):
- File location: plugin-root/wpml-config.xml
- Registers: admin_texts (translatable option names), custom_fields, custom_types, taxonomies
- Without this file: WPML users can't translate plugin content

STRING TRANSLATION:
- Use ICL_LANGUAGE_CODE constant for current language (not get_locale())
- do_action('wpml_register_single_string', 'plugin-name', 'string-name', \$string)
- apply_filters('wpml_translate_single_string', \$string, 'plugin-name', 'string-name')
- Never store language-specific content in generic options

URL HANDLING:
- Never hardcode admin URLs — use admin_url() (WPML rewrites these)
- apply_filters('wpml_permalink', \$url) for frontend URLs
- get_home_url(null, '', 'language') for language-specific home

POST/TAXONOMY COMPAT:
- Never query posts without language filter (WPML adds it automatically to WP_Query)
- apply_filters('wpml_object_id', \$post_id, 'post', true) to get translated post
Source: fetch live from https://wpml.org/documentation/support/wpml-coding-api/"

ingest "Cache plugin compatibility" \
  '["orbit","knowledge","compat","cache-plugins"]' \
  "Caching plugin compatibility rules:
WP ROCKET / LITESPEED / W3TC:
- Dynamic content (cart totals, user-specific data): exclude from page cache
  WP Rocket: use wprocket_define_excluded_pages filter or mark DONOTCACHEPAGE
  LiteSpeed: do_action('litespeed_tag_add', 'private') for private content
- AJAX: exclude AJAX URLs from caching
- Logged-in pages: WP Rocket/LiteSpeed auto-exclude by default

COOKIES:
- Setting cookies forces cache bypass on WP Rocket (respects PHPSESSID + WOOCOMMERCE_SESSION)
- Custom cookies: register with plugin settings (don't set random cookies)

OBJECT CACHE (Redis/Memcached):
- Use wp_cache_get/set with group (never rely on in-memory arrays surviving between requests when object cache is active)
- Flush group after writes: wp_cache_delete(\$key, 'my-plugin')

DYNAMIC CONTENT IN CACHED PAGES:
- Use fragment caching or AJAX to load user-specific parts
- Output buffering: never use ob_start/ob_end_clean on full pages (breaks cache)
- nonces: NEVER cache pages with nonces (they expire); use AJAX to fetch nonce
Source: https://docs.wp-rocket.me/category/531-developers"

ingest "Multisite requirements" \
  '["orbit","knowledge","compat","multisite"]' \
  "WordPress multisite requirements:
ACTIVATION:
- Network activate: register_activation_hook runs once per site (switch_to_blog loop)
  Or use wpmu_new_blog action for per-site setup on network activation
- is_multisite() check before network-specific code
- is_plugin_active_for_network() vs is_plugin_active()

OPTIONS STORAGE:
- Per-site: get_option() / update_option() (uses current site context)
- Network-wide: get_site_option() / update_site_option() (stored in wp_sitemeta)
- NEVER mix them; decide one strategy and document it

TABLE PREFIX:
- Always \$wpdb->prefix for per-site tables (\$wpdb->prefix = wpXY_ for sub-sites)
- Network-wide tables: \$wpdb->base_prefix (always wp_)
- Custom tables: {prefix}pluginname_tablename pattern

UNINSTALL:
- Network uninstall: loop through all sites with get_sites() and clean per-site data
- Also delete network options from wp_sitemeta

CAPS:
- manage_network for super-admin operations
- manage_options for site-admin operations (per site)
- Never assume user is super-admin just because they can manage_options
Source: https://developer.wordpress.org/plugins/multisite/"

ingest "Hosting environment constraints" \
  '["orbit","knowledge","compat","hosting"]' \
  "Hosting environment constraints for WordPress plugins:
WP ENGINE:
- Disallowed functions: exec(), shell_exec(), passthru(), system(), popen()
- No persistent write to plugin directory (uploads only)
- Memcached object cache (not Redis) — use wp_cache_* not Redis directly
- Custom cron scheduler (replaces WP-Cron) — don't disable WP-Cron; WP Engine handles it

KINSTA:
- Nginx only (no .htaccess rules) — use wp-config.php or filter for server config
- Redis object cache available (must use WP Redis plugin or wp_cache_*)
- CDN/edge caching: headers matter (Cache-Control: private for user content)
- Quicksilver equivalent: hooks for deploy events

SHARED HOSTING:
- PHP memory limit: as low as 64MB — avoid large operations; chunk big tasks
- Execution time: 30s max — batch processes with wp_cron
- No shell functions (exec, passthru disabled)
- No file writes to plugin directory — use wp-content/uploads/plugin-slug/
- mod_security may block requests with certain patterns (avoid eval-like patterns in output)

CLOUDWAYS:
- Varnish/Nginx stack — page cache aggressive; set Vary: Cookie headers
- Breeze cache plugin — similar to WP Rocket in terms of configuration
- Redis available — same pattern as Kinsta

ALL HOSTS:
- Never assume writable plugin directory
- Never assume shell access
- Never hardcode absolute paths — use ABSPATH, WP_CONTENT_DIR, plugin_dir_path()
Source: https://wpengine.com/support/disallowed-functions-wordpress/"

# ── Category 9: IP / Clean-Room (generic, public-safe) ────────────────────────
# NOTE: only generic engineering knowledge is seeded here (this file is in the
# public repo). The org-specific RUNBOOK — escalation contact, authorization
# checklist, internal asset/vendor policy — is seeded SEPARATELY by an admin via
# the brain MCP into orbit/07-security and is NEVER committed to this file.
echo ""
echo "── IP / Clean-Room (4 drawers)"

ingest "IP clean-room — the two copying myths" \
  '["orbit","knowledge","ip-cleanroom","gpl-myth"]' \
  "IP clean-room — kill these two myths before touching any reference plugin:
1. 'WordPress is all GPL so I can copy their code' = FALSE. GPL is a license with conditions, not a transfer of copyright. The author keeps copyright. Copying their GPL PHP into our plugin and shipping as ours (especially after stripping their headers) is BOTH copyright infringement AND a GPL violation. GPL lets us reuse the WP APIs and ideas freely; it does NOT let us lift another author's expression.
2. 'I'll just rewrite it in my own words' = still a derivative work. Structure/sequence/organization is protected (abstraction-filtration-comparison test). Only clean path for derived logic: rebuild-from-spec by an actor that never saw their code.
STOP condition: obfuscated/ionCube/encrypted PRO plugin being decompiled/deobfuscated → likely breaches vendor EULA + DMCA anti-circumvention (17 USC 1201), a separate offense. STOP and escalate to legal. Skill: /orbit-ip-cleanroom."

ingest "IP clean-room — WordPress leak signals" \
  '["orbit","knowledge","ip-cleanroom","leak-signals"]' \
  "WordPress plugin leak signals (the reference author's expression — reusing them = copy signal):
🔴 text domain; function/class/namespace prefixes; custom hook/filter names; option/transient/post-meta keys; DB table names; cron event hooks; REST namespace/routes; AJAX actions; nonce action strings; block names (namespace/block); shortcode tags; widget IDs; verbatim/paraphrased PHP/JS blocks; copied UI strings; readme.txt/FAQ wording; bundled images/icons/fonts from the reference.
🟡 CSS class prefixes; JS/CSS handle names; changelog phrasing; plugin header fields mirroring theirs; error/notice strings.
🟢 file names mirroring theirs (low weight, still scrub).
WordPress's OWN names (add_action, wp_enqueue_script, init, the_content) are the platform API — required and fine. Only author-INVENTED names are expression. Triage 🔴 → reimplement from spec with our prefix/text-domain; do NOT rename-and-ship. Skill: /orbit-ip-cleanroom."

ingest "IP clean-room — GPL/licensing & bundling reality" \
  '["orbit","knowledge","ip-cleanroom","licensing"]' \
  "Licensing reality for WP plugins:
- Free WP.org plugins are GPL: studying ideas fine, copying expression not.
- Commercial/freemium 'pro' plugins are usually GPL on code but distributed under a vendor EULA adding terms (no redistribution of the paid package, license gating). Code license != distribution contract.
- AGPL/Affero adds a network/SaaS clause — flag on intake. LGPL = weaker copyleft. MPL-2 = file-level copyleft.
- BUNDLING = redistribution. Most stock-asset licenses forbid extractable redistribution without an extended license. For bundled assets prefer own work / verified-CC0 / permissive icon sets (MIT/ISC/BSD) / OFL fonts self-hosted.
- Ship THIRD-PARTY-NOTICES/CREDITS listing every bundled lib + license; retain MIT/BSD notices. WP.org requires 100% GPL-compatible. Skill: /orbit-ip-cleanroom reference gpl-and-licensing.md."

ingest "IP clean-room — release gate & provenance" \
  '["orbit","knowledge","ip-cleanroom","release-gate"]' \
  "IP clean-room release gate (orbit-release runs as a hard pre-ship gate; orbit-security owns; orbit-code-reviewer flags during PR):
Block release unless ALL true:
- leak-scan clean: no reference identifier/string/readme-meta wording/asset in our plugin
- 🔴 items reimplemented from spec; low similarity to reference
- 100% GPL-compatible; THIRD-PARTY-NOTICES shipped; bundled assets cleared for redistribution
- plugin name/slug/tagline trademark-cleared (WP.org slug, USPTO/EUIPO, domain)
- provenance manifest written (ip-manifest.sh)
- if a premium/obfuscated plugin was involved → escalated to legal, not silently used
Engineering risk-reduction, NOT legal advice. The org escalation contact + authorization checklist live in the orbit/07-security ip-cleanroom RUNBOOK (admin-seeded, not in the public repo)."

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "────────────────────────────────────────────"
echo "✓ Orbit starter brain seeded successfully"
echo ""
echo "  44 knowledge drawers ingested:"
echo "  8 × WP Standards"
echo "  6 × Block Editor"
echo "  4 × Elementor"
echo "  5 × Security"
echo "  4 × Performance"
echo "  5 × Release"
echo "  4 × Accessibility"
echo "  4 × Compat"
echo "  4 × IP / Clean-Room"
echo ""
echo "  Namespace: $NAMESPACE"
echo "  Brain:     $BRAIN_URL"
echo ""
echo "  Next: set ORBIT_TEAM_KEY and ORBIT_ADMIN_KEY in your"
echo "  CLAUDE.md or environment before invoking agents."
echo "  See: docs/team-access.md"
echo "────────────────────────────────────────────"
