# Orbit — Starter Brain Pack

> 40 pre-loaded knowledge drawers. Seed these on first install via `brain/seed-brain.sh`.
> Every new Orbit user gets day-1 intelligence instead of a cold start.
> These live in `orbit/knowledge/` namespace — read-only for Team key.

---

## How to seed

```bash
# Admin key required
bash brain/seed-brain.sh --key <your-admin-key>

# Or manually: add each drawer via posimyth_brain_add_note
# Tag format: [orbit, knowledge, <area>, starter-pack]
```

---

## The 40 Starter Drawers

### 🏗️ WP Standards (8 drawers)

**WP-STD-01: Escaping rules**
```
Tag: [orbit, knowledge, wp-standards, escaping]
Content:
- esc_html() — for text content inside HTML elements
- esc_attr() — for HTML attribute values
- esc_url() — for URLs in href/src attributes
- esc_js() — for strings inside JS (use wp_json_encode when possible)
- wp_kses_post() — for user-generated HTML content
- Never echo unescaped user input. Never use $_GET/$_POST directly in output.
- Late escaping rule: escape as close to output as possible, not at input.
```

**WP-STD-02: Nonce verification**
```
Tag: [orbit, knowledge, wp-standards, nonces]
Content:
- wp_create_nonce('action-name') — create. wp_verify_nonce($_POST['_wpnonce'], 'action-name') — verify.
- check_admin_referer() — admin forms. check_ajax_referer() — AJAX handlers.
- Every POST form needs a nonce field. Every AJAX write handler needs nonce verification.
- Nonce failure: wp_die() with 403. Never silently ignore.
- Nonce lifetime: 12-24 hours. Use wp_nonce_field() in forms.
```

**WP-STD-03: Capability checks**
```
Tag: [orbit, knowledge, wp-standards, capabilities]
Content:
- current_user_can('manage_options') — admin settings
- current_user_can('edit_posts') — content editing
- current_user_can('upload_files') — media upload
- Always check capabilities BEFORE processing any admin action.
- AJAX handlers need both nonce AND capability check — nonce alone is not enough.
- Custom capabilities: register with add_role() or add_cap(). Never hardcode role names.
```

**WP-STD-04: Input sanitization**
```
Tag: [orbit, knowledge, wp-standards, sanitization]
Content:
- sanitize_text_field() — plain text input
- sanitize_email() — email addresses
- sanitize_url() — URLs (input side)
- absint() — positive integers (IDs, counts)
- wp_kses() — HTML with allowed tags
- sanitize_key() — option keys, slugs
- Sanitize on input/save. Escape on output. These are different operations.
```

**WP-STD-05: $wpdb usage**
```
Tag: [orbit, knowledge, wp-standards, wpdb]
Content:
- Always use $wpdb->prepare() for any query with variables.
- Never concatenate user input into SQL strings.
- $wpdb->prefix — always use table prefix, never hardcode wp_
- $wpdb->get_results() returns array of objects. Check for WP_Error.
- Custom tables: CREATE TABLE in activation hook, remove in uninstall.php.
- Use autoload=no for large option values.
```

**WP-STD-06: Plugin file structure**
```
Tag: [orbit, knowledge, wp-standards, file-structure]
Content:
- Main file: plugin-name/plugin-name.php with correct plugin header
- Plugin header must include: Plugin Name, Version, Requires at least, Tested up to, Requires PHP, Text Domain
- Activation: register_activation_hook(). Deactivation: register_deactivation_hook(). Uninstall: uninstall.php (not hook)
- Never use __FILE__ in hooked functions — use plugin_dir_path()/plugin_dir_url() with main file constant
- ABSPATH check at top of every PHP file: if (!defined('ABSPATH')) exit;
```

**WP-STD-07: i18n rules**
```
Tag: [orbit, knowledge, wp-standards, i18n]
Content:
- All strings: __('text', 'text-domain') or esc_html__() for output
- Text domain must match plugin slug in plugin header
- load_plugin_textdomain() in init hook (WP 4.6+ auto-loads, but still register)
- printf() with placeholders: printf(esc_html__('Hello %s', 'td'), esc_html($name))
- Never concatenate translated strings — use placeholders
- POT file required. WP.org expects it in /languages/
```

**WP-STD-08: Hooks and filters**
```
Tag: [orbit, knowledge, wp-standards, hooks]
Content:
- add_action() priority: default 10. Earlier = lower number. Later = higher.
- Remove hooks: remove_action() must use same priority as add_action()
- Prefix all custom hooks: 'plugin-slug/action-name' (slash format) or 'plugin_slug_action'
- apply_filters() must have a default value as second arg
- Never call wp_enqueue_scripts() outside of wp_enqueue_scripts hook
- admin_enqueue_scripts — for admin assets. wp_enqueue_scripts — for frontend.
```

---

### 🧱 Block Editor (6 drawers)

**BE-01: block.json required fields**
```
Tag: [orbit, knowledge, block-editor, block-json-required]
Content:
- apiVersion: 3 (current). Never omit.
- name: "namespace/block-name" — kebab-case, must match registered name
- title: human-readable, must be i18n-translatable
- category: one of core (text/media/design/widgets/theme/embed) or custom registered
- icon: dashicon string ('block-default') or SVG object
- textdomain: must match plugin text domain exactly
- Every attribute must declare a type (string/boolean/number/array/object)
- supports.anchor and supports.customClassName should be declared explicitly
```

**BE-02: Save vs ServerSideRender**
```
Tag: [orbit, knowledge, block-editor, save-vs-ssr]
Content:
- Dynamic blocks (PHP render_callback): save() must return null. Use ServerSideRender in edit().
- Static blocks: save() must be deterministic — same attributes always produce same markup
- Block validation errors caused by: save() output changed after content saved, attributes not matching
- If changing static to dynamic: provide deprecated[] entry with old save function
- Never put non-deterministic content in save() — no Date.now(), no Math.random()
```

**BE-03: Block attributes best practices**
```
Tag: [orbit, knowledge, block-editor, attributes]
Content:
- Always set 'default' for every attribute — undefined props cause editor errors
- 'source' attribute binding: 'html' binds to element content, 'attribute' to HTML attr
- Array/Object attributes need 'items' or 'properties' schema for type safety
- Don't store computed values as attributes — derive them in render
- Attribute names: camelCase. Never use reserved names (className, style already handled by supports)
```

**BE-04: Block Editor hooks (most used)**
```
Tag: [orbit, knowledge, block-editor, editor-hooks]
Content:
- blocks.registerBlockType — register (or use block.json)
- editor.BlockEdit — wrap block edit component
- editor.BlockListBlock — add classes to block wrapper
- blocks.getSaveContent.extraProps — add props to save output
- blocks.getBlockDefaultClassName — customize default class
- useBlockProps() — required in edit/save (apiVersion 2+)
- InspectorControls — right sidebar panel. BlockControls — toolbar.
```

**BE-05: Interactivity API (WP 6.5+)**
```
Tag: [orbit, knowledge, block-editor, interactivity-api]
Content:
- wp_interactivity_state() — define server-side state
- wp_interactivity_config() — pass config to frontend
- data-wp-interactive, data-wp-context, data-wp-bind — directives
- Directives run client-side only. Never use for SEO-critical content.
- Store: { state: {}, actions: {}, callbacks: {} }
- wp_interactivity_process_directives() — process on server for SSR
- Avoid DOM manipulation outside the store — use state instead
```

**BE-06: Full Site Editing**
```
Tag: [orbit, knowledge, block-editor, fse]
Content:
- theme.json controls: typography, color palette, spacing, shadow
- Block templates: templates/single.html, templates/archive.html, etc.
- Template parts: parts/header.html, parts/footer.html
- Block patterns in FSE: should use core blocks where possible
- __experimentalLayout support in blocks for FSE alignment
- get_block_template() — programmatic template access
- FSE blocks shouldn't hardcode URLs — use core/site-title, core/navigation
```

---

### 🎨 Elementor (4 drawers)

**EL-01: Widget registration**
```
Tag: [orbit, knowledge, elementor, widget-registration]
Content:
- Register via: elementor/widgets/register action (not deprecated init)
- Widget class extends \Elementor\Widget_Base
- get_name(): must be unique, kebab-case
- get_title(): wrapped in __() for i18n
- get_icon(): 'eicon-*' prefix for Elementor icons, 'fa fa-*' for Font Awesome
- get_categories(): array — default Elementor cats or custom registered
- _register_controls(): define all controls here. Don't use deprecated register_controls()
```

**EL-02: Control types reference**
```
Tag: [orbit, knowledge, elementor, controls]
Content:
- TEXT: single line text. TEXTAREA: multi-line. WYSIWYG: rich text
- NUMBER: numeric. SLIDER: range slider with unit. DIMENSIONS: top/right/bottom/left
- COLOR: color picker. MEDIA: image/video upload. ICON: icon picker
- SELECT: dropdown. CHOOSE: button group. SWITCHER: toggle
- REPEATER: dynamic list of controls. POPOVER_TOGGLE: popover panel trigger
- Conditions: 'condition' => ['control_name' => 'value'] — show/hide based on another control
- Responsive controls: add_responsive_control() for device-specific values
```

**EL-03: Skin system**
```
Tag: [orbit, knowledge, elementor, skins]
Content:
- Skin class extends \Elementor\Skin_Base
- get_id(): unique skin ID. get_title(): human-readable.
- _register_controls_content_tab() and _register_controls_style_tab() — add skin controls
- register skin: $widget->add_skin(new Skin_Class())
- Access skin in render: $this->get_active_skin_id() and $this->get_skin()
- Skins should not override parent controls — add new ones only
- Skin controls inherit parent widget's base controls automatically
```

**EL-04: Dynamic tags**
```
Tag: [orbit, knowledge, elementor, dynamic-tags]
Content:
- Register via: elementor/dynamic_tags/register action
- Tag class extends \Elementor\Core\DynamicTags\Tag
- get_name(): unique, kebab-case. get_title(): human-readable.
- get_group(): which group this tag appears in (URL/TEXT/COLOR/IMAGE/MEDIA/NUMBER/POST_META)
- get_categories(): which control types accept this tag
- render(): outputs the dynamic value (escaping required)
- Dynamic tags must handle null/empty case — never assume value exists
```

---

### 🔒 Security (5 drawers)

**SEC-01: XSS patterns in WP plugins**
```
Tag: [orbit, knowledge, security, xss-patterns]
Content:
- Reflected XSS: unescaped $_GET/$_POST in output — most common
- Stored XSS: unescaped DB value in output — high severity
- DOM XSS: unescaped JS variable from PHP output — check wp_localize_script() data
- WP-specific risk: add_action('wp_footer') echo with unescaped user data
- widget_text filter — applied to widget content, bypasses esc_html if misconfigured
- Shortcode attributes: always sanitize_text_field() in shortcode callback
- Fix pattern: always esc_html()/esc_attr() at output, never rely on input sanitization alone
```

**SEC-02: SQL injection in $wpdb**
```
Tag: [orbit, knowledge, security, sql-injection]
Content:
- Vulnerable: $wpdb->query("SELECT * FROM {$wpdb->prefix}table WHERE id = " . $_GET['id'])
- Safe: $wpdb->get_row($wpdb->prepare("SELECT * FROM {$wpdb->prefix}table WHERE id = %d", absint($_GET['id'])))
- %d = integer, %s = string (quoted), %f = float. Never use sprintf with SQL.
- $wpdb->prepare() with arrays: use vsprintf pattern or multiple placeholders
- IN() clause: build with implode + prepare individually — no array placeholder exists
- Meta queries: WP_Query meta_query is safe. Direct meta table queries need prepare().
```

**SEC-03: CSRF/nonce in AJAX**
```
Tag: [orbit, knowledge, security, csrf-ajax]
Content:
- All wp_ajax_* handlers need: check_ajax_referer('action', '_wpnonce') + current_user_can()
- wp_ajax_nopriv_* — public AJAX. Still needs nonce for write operations.
- Enqueue nonce: wp_localize_script('handle', 'obj', ['nonce' => wp_create_nonce('action')])
- Pass in AJAX: data: { nonce: obj.nonce, ... }
- Verify: check_ajax_referer('action', 'nonce') — dies on failure
- Missing nonce = CSRF. Missing cap check = privilege escalation. Both needed.
```

**SEC-04: File inclusion vulnerabilities**
```
Tag: [orbit, knowledge, security, file-inclusion]
Content:
- Never: include($_GET['file']) or require($user_input . '.php')
- Path traversal: ../../../wp-config.php via directory traversal
- Fix: use realpath() + validate against allowed directory before include
- Plugin upload handlers: validate file type by content (finfo), not extension
- Never allow PHP file uploads in plugin upload handlers — whitelist specific types
- wp_check_filetype_and_ext() — use for file type validation
```

**SEC-05: Secrets and credential exposure**
```
Tag: [orbit, knowledge, security, secrets]
Content:
- Never hardcode API keys, secret tokens, DB passwords in plugin code
- Use get_option() or define() in wp-config.php for credentials
- wp-config.php is outside webroot in standard WP installs — safe location
- REST API should never return raw API keys or license keys
- Error messages must not expose internal paths, DB structure, or credentials
- Debug logs (WP_DEBUG_LOG) should be in /wp-content/debug.log, not web-accessible
- .env files in plugin dir = HIGH severity. Check for .env in git history too.
```

---

### ⚡ Performance (4 drawers)

**PERF-01: WP hook weight rules**
```
Tag: [orbit, knowledge, performance, hooks]
Content:
- wp_head / wp_footer: high cost. Only add what's needed. Check if not already enqueued.
- the_content filter: runs on every post in loops. Heavy processing here = N×cost.
- posts_clauses: modifies every WP_Query. Expensive if not conditional.
- Use add_action conditionally: if (is_admin()) or if (is_singular('post'))
- Avoid global variable lookups in every hook — cache in class property
- Hook priority: lower numbers run earlier. Avoid 99999 — hard to override.
- Pre-check: if (has_action('hook_name')) before adding expensive hooks
```

**PERF-02: N+1 query patterns**
```
Tag: [orbit, knowledge, performance, n-plus-1]
Content:
- Classic N+1: for each post, run get_post_meta() = N+1 DB queries
- Fix: use WP_Query with meta_query to get all at once, or get_post_meta() outside loop with update_post_meta_cache
- posts_per_page: -1 is dangerous. Always set a limit. Use pagination.
- WP_Query 'no_found_rows' => true when not paginating — removes COUNT(*) query
- 'update_post_meta_cache' => false — disable meta cache if not using meta in loop
- 'update_post_term_cache' => false — disable term cache if not using terms in loop
- Transients: cache expensive queries. Use delete_transient() on data update hooks.
```

**PERF-03: Asset loading**
```
Tag: [orbit, knowledge, performance, assets]
Content:
- Never load plugin assets on every page — use conditional loading
- wp_enqueue_scripts with is_singular('post-type') or has_shortcode() check
- Minify JS/CSS before shipping. Never ship unminified in production zip.
- defer/async: add via wp_script_add_data($handle, 'strategy', 'defer')
- Critical CSS: inline with wp_add_inline_style() for above-the-fold
- Bundle related scripts — one request better than five small ones
- Remove assets other plugins load if not needed: wp_dequeue_script()
```

**PERF-04: Transient and object cache**
```
Tag: [orbit, knowledge, performance, caching]
Content:
- set_transient('key', $data, HOUR_IN_SECONDS) — store. get_transient('key') — retrieve.
- Transients stored in wp_options by default. Set autoload=no for large values.
- Object cache: wp_cache_set() / wp_cache_get() — in-memory, faster than transients
- Cache groups: wp_cache_set('key', $val, 'my-plugin') — avoids collisions
- Cache invalidation: hook into save_post, update_option, etc. to delete stale cache
- Never cache for too long — stale data worse than no cache for real-time data
- Persistent object cache (Redis/Memcached): use if available — auto-detected by WP
```

---

### 📦 Release (5 drawers)

**REL-01: readme.txt required fields**
```
Tag: [orbit, knowledge, release, readme-fields]
Content:
- === Plugin Name === — exact match to plugin header
- Contributors: WordPress.org username (not email)
- Tags: 5 tags max, lowercase, relevant to search
- Requires at least: minimum WP version
- Tested up to: CURRENT WP stable release (update every release)
- Requires PHP: minimum PHP version (8.0 minimum recommended 2026)
- Stable tag: must match version in plugin header
- License: GPLv2 or later (required for WP.org)
- == Description == required. == Installation == recommended. == Changelog == required.
```

**REL-02: WP.org rejection reasons (most common)**
```
Tag: [orbit, knowledge, release, wp-org-rejections]
Content:
- Generic function names (no prefix): my_function() — must be plugin_name_function()
- Unescaped output: echo $variable — must escape
- Missing nonce verification on POST handlers
- Direct DB calls without $wpdb->prepare()
- Calling files outside plugin directory
- Hardcoded plugin path (use plugin_dir_path())
- No uninstall.php (or register_uninstall_hook) — data left behind
- Including unnecessary files (.git, node_modules, tests, .env)
- Phoning home without consent (calling external API without user knowledge/opt-in)
```

**REL-03: Semantic versioning for WP plugins**
```
Tag: [orbit, knowledge, release, versioning]
Content:
- Format: MAJOR.MINOR.PATCH (e.g. 2.3.1)
- MAJOR: breaking changes (new minimum WP/PHP, removed features, DB changes)
- MINOR: new features, backwards compatible
- PATCH: bug fixes, security patches
- Tested up to: always bump to latest WP release. Update on every release.
- All these must match: plugin header Version:, readme.txt Stable tag:, package.json version
- Tag in git: git tag vX.Y.Z — WP.org pulls from SVN tag
```

**REL-04: Zip hygiene**
```
Tag: [orbit, knowledge, release, zip-hygiene]
Content:
- Exclude: .git/, node_modules/, .env, .env.*, tests/, *.test.js, *.spec.php, phpunit.xml
- Exclude: .DS_Store, Thumbs.db, .gitignore, .gitattributes, .editorconfig
- Exclude: composer.lock (include composer.json if needed)
- Include: all PHP, JS (minified), CSS (minified), images, languages/, readme.txt
- Directory name must match slug: my-plugin/my-plugin.php (not plugin/my-plugin.php)
- Zip root must be single directory — not files at root level
- Max size: WP.org has no hard limit but keep under 10MB for fast installs
```

**REL-05: Keep a Changelog format**
```
Tag: [orbit, knowledge, release, changelog-format]
Content:
- [Unreleased] section at top. Move to version on release.
- Sections: Added / Changed / Deprecated / Removed / Fixed / Security
- Version entries: ## [X.Y.Z] — YYYY-MM-DD
- WP.org == Changelog == uses asterisk bullets: * Fixed: description
- Don't list internal refactors users don't see — focus on user impact
- Security fixes: "Security: Fixed XSS in widget output (CVE-XXXX-XXXX if assigned)"
- Keep entries short. One line per change. User-facing language.
```

---

### ♿ Accessibility (4 drawers)

**A11Y-01: WCAG 2.2 AA checklist (WP admin)**
```
Tag: [orbit, knowledge, accessibility, wcag-admin]
Content:
- All form inputs need <label> or aria-label
- Buttons need accessible text (not just icons — add aria-label or .screen-reader-text)
- Color contrast: 4.5:1 for normal text, 3:1 for large text (18pt/14pt bold)
- Focus indicators: visible on all interactive elements. WP admin has defaults — don't override without replacing.
- Error messages: associated with input via aria-describedby
- Tables need <th> with scope. Complex tables need headers + id association.
- No content conveyed by color alone — always add icon or text pattern.
```

**A11Y-02: WCAG 2.2 AA — keyboard navigation**
```
Tag: [orbit, knowledge, accessibility, keyboard-nav]
Content:
- Tab order must be logical (matches visual order)
- No keyboard traps — can tab through AND out of all UI
- Modal dialogs: trap focus while open, return to trigger on close
- Dropdown menus: arrow keys to navigate, Escape to close
- Custom controls (accordion, tabs): follow ARIA authoring patterns
- Skip links: if complex navigation, provide "Skip to content" link
- Focus management: after dynamic content loads, move focus to new content
```

**A11Y-03: RTL layout rules**
```
Tag: [orbit, knowledge, accessibility, rtl]
Content:
- Use logical properties: margin-inline-start vs margin-left
- Or: [dir="rtl"] .class { margin-left: auto; margin-right: 10px; }
- Text alignment: text-align: start (not left/right) for RTL-safe alignment
- Float reversal: float:left becomes float:right in RTL
- Transform: translateX() values need sign reversal in RTL
- Padding/margin: most need to mirror (left⟷right) in RTL
- Icons with directional meaning (arrow →): should mirror in RTL. Decorative icons: don't flip.
- Test with: <html dir="rtl"> or WP's built-in RTL detection
```

**A11Y-04: Empty and error states**
```
Tag: [orbit, knowledge, accessibility, empty-error-states]
Content:
- Empty state: must have visible text (not just icon). Include actionable CTA.
- Pattern: [Icon] "No items yet." + [Button: "Add your first item"]
- Error state: visible error icon + descriptive text + how to fix
- Form validation: show error inline, near the field, not just at top
- Loading state: show spinner/skeleton. aria-live="polite" for status updates.
- Success state: confirmation message after action. aria-live="polite" for async.
- Never use placeholder text as the only label — disappears on focus.
```

---

### 🔌 Compat (4 drawers)

**COMPAT-01: WPML compat rules**
```
Tag: [orbit, knowledge, compat, wpml]
Content:
- All strings for translation must be registered via wpml-config.xml or icl_register_string()
- Custom post types: register wpml-config.xml with translatable fields
- URLs: use get_permalink() — WPML filters this for language. Never hardcode URLs.
- Queries: add suppress_filters=false so WPML language filter applies
- Meta values: use icl_t() for translatable meta values
- Don't hook directly into WPML internal filters — use documented API
- Test: activate WPML, switch language, verify content + URLs correct
```

**COMPAT-02: Caching plugin compat**
```
Tag: [orbit, knowledge, compat, caching]
Content:
- WP Rocket: exclude AJAX URLs from caching via config. Dynamic content (cart) needs cache exclusion.
- LiteSpeed Cache: test with .htaccess caching enabled. REST endpoints may need exclusion.
- W3 Total Cache: object cache can conflict with transients — test get_transient() return values
- All cache plugins: test that plugin admin pages are NOT cached (causes settings not saving)
- AJAX responses: set correct Cache-Control headers. nocache_headers() for logged-in responses.
- Avoid: relying on output buffering — conflicts with caching plugins.
```

**COMPAT-03: Multisite requirements**
```
Tag: [orbit, knowledge, compat, multisite]
Content:
- Network activation: add Multisite Compatible: true to plugin header if supported
- Per-site options: use blog_id in option keys or use switch_to_blog()
- Network options: use get_site_option() — stored once for whole network
- Table creation: run activation per blog. Network activation hook = once.
- Uploads: use get_upload_dir() — different path per site in multisite
- User roles: site-specific roles via add_role() — affect current blog only
- Current blog: get_current_blog_id(). Switch: switch_to_blog(). Restore: restore_current_blog().
```

**COMPAT-04: Hosting constraints (shared/managed)**
```
Tag: [orbit, knowledge, compat, hosting]
Content:
- PHP memory limit: minimum 128MB needed. Check with ini_get('memory_limit'). Recommend 256MB.
- Max execution time: 30s default. Long operations need set_time_limit() or background processing.
- WP Engine: no dangerous PHP functions (exec, passthru, etc.). Object cache = Memcached.
- Kinsta: Nginx (no .htaccess). Redis object cache available. Cron must use WP-Cron or Kinsta scheduler.
- Pantheon: read-only filesystem except /files. No file writes to plugin dir.
- Shared hosting: sftp only, no shell exec. Low PHP memory. WP-Cron unreliable — use Action Scheduler.
```

### ⚠️ WP Runtime Traps (14 drawers — patterns that pass static review and break only on live install)

> **The bug class that pass every linter, every unit test, and every code review — and only manifest when WordPress runtime contracts bite (host config, plugin load order, Settings API null-coalescing, third-party plugin token resolution).** Plugin-agnostic patterns. Code Reviewer §10 enforces these; `/orbit-code-quality` §6 detects them with grep recipes.

**TRAP-01: Settings API cross-nulling**
```
Tag: [orbit, knowledge, wp-runtime-traps, settings-api]
Content:
- register_setting($GROUP, $OPT) adds $OPT to WP's allowed_options[$GROUP]
- ANY form posting to options.php for $GROUP nulls every registered option not in $_POST
- sanitize_on_off(null)='off' → silent feature regression on save
- Rule: every option registered to a group must appear in every form posting to that group,
  as visible control OR hidden preservation row: <input type="hidden" name="$OPT" value="<?php echo esc_attr(get_option($OPT,$default)); ?>" />
- Severity: Critical (silent disable)
```

**TRAP-02: DISABLE_WP_CRON assumption**
```
Tag: [orbit, knowledge, wp-runtime-traps, cron]
Content:
- wp_schedule_single_event / wp_schedule_event assumes wp-cron will fire
- Kinsta, WP Engine, Cloudways, Pantheon and any system-cron site set DISABLE_WP_CRON=true
- Jobs queue in cron_array forever, never execute
- Fix: expose direct synchronous run_now() trigger via admin/REST/WP-CLI
- Add admin notice if DISABLE_WP_CRON detected
- Consider Action Scheduler as fallback
- Severity: High (broken on common managed hosts)
```

**TRAP-03: Conditional add_rewrite_rule at init**
```
Tag: [orbit, knowledge, wp-runtime-traps, rewrite]
Content:
- if (get_option('feature')=='on') { add_rewrite_rule(...); } inside init hook
- Toggling option in admin doesn't add the rule for this request (init already fired)
- flush_rewrite_rules() flushes nothing — rule not in array yet
- Result: persistent 404 on the new route until next init
- Fix: in toggle handler, call add_rewrite_rule() directly THEN flush_rewrite_rules(false)
- OR inject rule into rewrite_rules option directly
- Severity: Critical (user thinks feature broken)
```

**TRAP-04: Bulk option restore wipes user data**
```
Tag: [orbit, knowledge, wp-runtime-traps, options]
Content:
- "Reset to defaults" / "first-run install" loops update_option($opt, $defaults[$opt])
- Doesn't check whether option already has non-default value
- Common in onboarding wizards. Wipes power-user config silently.
- Fix: if (get_option($opt, $SENTINEL) === $SENTINEL) update_option($opt, $default);
- Severity: High (silent overwrite)
```

**TRAP-05: Auto-gen hook only on publish_post**
```
Tag: [orbit, knowledge, wp-runtime-traps, hooks]
Content:
- add_action('publish_post', 'generate_summary') only fires on initial publish
- Pre-existing posts never trigger generation
- Re-edits never re-trigger generation
- Fix: hook save_post or post_updated AND add idempotency guard via content-hash meta
- Confirm generation is idempotent before allowing the broader hook
- Severity: High (feature appears non-functional on existing content)
```

**TRAP-06: Superglobal reads without wp_unslash**
```
Tag: [orbit, knowledge, wp-runtime-traps, superglobals]
Content:
- $x = $_POST['key']; or if ($_GET['key']==='value') — WP slash-escapes superglobals on load
- Raw reads leave stray backslashes in saved data
- Trips WP.org Plugin Check / phpcs ValidatedSanitizedInput warning
- Fix: sanitize_text_field(wp_unslash($_POST['key'] ?? ''))
- Bare isset() / empty() checks are safe (don't read the value)
- Severity: High (WP.org gate warning + data corruption)
```

**TRAP-07: Meta value type drift (JSON string vs PHP array)**
```
Tag: [orbit, knowledge, wp-runtime-traps, meta]
Content:
- Writers use wp_json_encode() → meta stored as string
- Readers do is_array() / count() / foreach → silent fail
- Pick one canonical shape per meta key and enforce
- Recommended: pass array directly to update_post_meta(), let WP serialize
- If JSON needed for portability: every reader must json_decode($v ?: '[]', true) first
- Severity: High (silent data loss in features consuming meta)
```

**TRAP-08: %currentyear% literals in third-party SEO meta**
```
Tag: [orbit, knowledge, wp-runtime-traps, seo-tokens]
Content:
- Rank Math / Yoast / SEOPress resolve their %token% syntax only on user-typed save
- Programmatic update_post_meta() writes the token as literal
- Resolver never runs on programmatic insertion
- Result: SERP shows "Title for %currentyear%"
- Fix: resolve before writing — str_replace('%currentyear%', wp_date('Y'), $v)
- OR call the SEO plugin's replacement filter: apply_filters('rank_math/replacements', $v)
- Yoast: wpseo_replace_vars($v, $post)
- Severity: High (user-visible SERP regression)
```

**TRAP-09: Text-stats miscount Gutenberg block delimiters**
```
Tag: [orbit, knowledge, wp-runtime-traps, gutenberg]
Content:
- Em-dash counter, readability scorer, banned-phrase check on raw post_content
- Gutenberg delimiters <!-- wp:foo {"bar":"…"} --> contain characters that get miscounted
- Result: false positives — every Gutenberg post fails the check
- Fix: strip block delimiters first
  preg_replace('/<!--\s*\/?wp:[^>]+-->/', '', $content)
- BETTER: render via apply_filters('the_content', $c) then wp_strip_all_tags()
- Severity: Medium (false positives only)
```

**TRAP-10: Tab / REST route slug mismatch**
```
Tag: [orbit, knowledge, wp-runtime-traps, routing]
Content:
- Admin links to ?page=plugin&tab=content-ai
- Router only switches on tab=content → falls through to dashboard
- OR JS posts to myplugin/v1/foos but route registered as myplugin/v1/foo
- Silent navigation failure
- Fix: single source of truth for slugs (const TAB_SLUGS = [...])
- Audit: collect every tab=$slug link AND every register_rest_route path
- Cross-ref every case '$slug': in router. Diff. Broken links surface immediately.
- Severity: Medium (broken UX, no error surfaced)
```

**TRAP-11: Cache invalidation forgets new bucket**
```
Tag: [orbit, knowledge, wp-runtime-traps, cache]
Content:
- v1.1 adds new transient/object-cache key
- flush_all_caches() still only deletes v1.0 keys
- Stale cache wins after upgrade — new feature appears broken
- Fix: every set_transient("$prefix_*") must have matching delete_transient in central flush
- Upgrade routine must call flush when DB schema or option shape changes
- Audit: list all cache set sites, list all cache delete sites, diff
- Severity: High (silent feature regression after upgrade)
```

**TRAP-12: Free/Pro dual-class shadow conflict**
```
Tag: [orbit, knowledge, wp-runtime-traps, dual-class]
Content:
- Free defines class Plugin_Foo; Pro defines class Plugin_Foo
- PSR-4 autoloader: fatal on redeclaration
- require_once: silently wrong class wins (load-order dependent)
- Fix: both files must use class_exists() guards
- BETTER: Pro extends Free under different name (Plugin_Foo_Pro extends Plugin_Foo)
- Pro hooks itself into a filter Free exposes
- Audit: intersect class names across Free and Pro codebases
- Severity: Critical (fatal OR silently wrong behavior)
```

**TRAP-13: Cross-plugin filter timing (consumer before producer)**
```
Tag: [orbit, knowledge, wp-runtime-traps, filter-timing]
Content:
- Free reads apply_filters('myplugin_is_pro', false) at plugins_loaded priority 10
- Pro registers callback at plugins_loaded priority 10
- Plugin load order = alphabetical by folder name
- If Free folder sorts first, reader fires before Pro can hook in
- Pro features stay locked even when Pro active
- Fix: reader priority ≥20 on plugins_loaded, OR on init / later
- Cross-check reader priority vs producer priority for every cross-plugin filter
- Severity: Critical (paying customers see locked features)
```

**TRAP-14: Activation hook references unloaded constants/classes**
```
Tag: [orbit, knowledge, wp-runtime-traps, activation]
Content:
- Bootstrap defines MYPLUGIN_VERSION, requires class files, then registers activation hook
- register_activation_hook can fire callback before bootstrap fully loads in:
  network-activate, WP-CLI bulk-activate, upload-and-activate flows
- Callback that uses MYPLUGIN_VERSION or MyPlugin_Welcome::flag_activation() fatals
- Fix: every plugin-namespaced reference must be guarded
  if (defined('MYPLUGIN_VERSION')) { ... }
  if (class_exists('MyPlugin_Welcome')) MyPlugin_Welcome::flag_activation();
- Same rule for register_deactivation_hook and register_uninstall_hook
- Severity: High (activation fatal on a subset of WP environments)
```
