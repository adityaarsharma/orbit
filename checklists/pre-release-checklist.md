# Pre-Release Checklist
> Run every item before tagging a release for your WordPress plugin.

---

## Code Quality

- [ ] `bash scripts/gauntlet.sh --plugin /path/to/plugin` — zero failures
- [ ] PHP lint: no syntax errors in any `.php` file
- [ ] PHPCS: zero `ERROR` level violations
- [ ] PHPStan: no level-5 type errors
- [ ] Version numbers synced in all 3 places (plugin header, constant, readme.txt)
- [ ] CHANGELOG updated with `## [X.Y.Z] - YYYY-MM-DD` section

## Database

- [ ] Query count per page not regressed vs previous release (`bash scripts/db-profile.sh`)
- [ ] No queries >100ms on key pages
- [ ] No N+1 query patterns (same query firing in a loop)
- [ ] New `wp_options` entries have correct `autoload` setting

## Performance

- [ ] Lighthouse performance score ≥ 75 (target: 85+)
- [ ] No CSS/JS 404s
- [ ] JS bundle size not increased >10% without justification
- [ ] New assets enqueued conditionally (not on every page)
- [ ] No synchronous external HTTP calls blocking page render

## Security

- [ ] All user-facing inputs sanitized (`sanitize_text_field`, `absint`, etc.)
- [ ] All outputs escaped (`esc_html`, `esc_attr`, `wp_kses_post`)
- [ ] All forms and AJAX handlers have nonce verification
- [ ] All REST endpoints have `permission_callback`
- [ ] No direct DB queries without `$wpdb->prepare()`
- [ ] No `eval()`, `system()`, `exec()`, `shell_exec()` usage

## Functional Tests

- [ ] Playwright suite: 0 failing tests
- [ ] Admin panel loads without PHP fatal errors
- [ ] Plugin activates cleanly on a fresh WordPress install
- [ ] Plugin deactivates cleanly (no fatal on deactivation hook)
- [ ] Plugin uninstalls cleanly (data removed if opted in)

## UI/UX

- [ ] [UI/UX Checklist](ui-ux-checklist.md) reviewed
- [ ] No horizontal scroll at 375px, 768px, 1440px
- [ ] No broken images
- [ ] Hit areas ≥ 44×44px on mobile

## Compatibility

- [ ] Tested on PHP 7.4, 8.0, 8.1, 8.2
- [ ] Tested on WordPress latest - 1 version
- [ ] Tested with conflicting plugins active: Rank Math, Yoast, WooCommerce, Elementor
- [ ] No fatal errors with `WP_DEBUG=true`

## WP.org Submission Compliance

- [ ] Plugin slug is ≤ 50 characters (count all chars including hyphens)
- [ ] Plugin name does not begin with a third-party trademark (OK at end: "My Tool for Elementor")
- [ ] All functions, classes, options, transients, AJAX actions have a unique 4+ char prefix
- [ ] No variables passed as first arg to `__()` or `_e()` — must be string literals
- [ ] No hardcoded paths using `ABSPATH`, `WP_PLUGIN_DIR`, or `WP_CONTENT_DIR` to locate plugin files — use `plugin_dir_path(__FILE__)` / `plugin_dir_url(__FILE__)`
- [ ] No files written inside the plugin folder — write only to `wp_upload_dir()`
- [ ] No direct `require_once` of `wp-admin/includes/*.php`, `wp-config.php`, or `wp-load.php` without immediately calling a function from that file
- [ ] No HEREDOC (`<<<`) syntax anywhere in PHP files
- [ ] Every `ob_start()` is closed with `ob_get_clean()` / `ob_end_flush()` in the same function scope
- [ ] If plugin calls any external API: `== External Services ==` section in readme.txt with purpose, data sent, ToS URL, Privacy URL — all links return 200
- [ ] No direct rewrite of `active_plugins` or `active_sitewide_plugins` options
- [ ] No global WP constants defined at runtime: `SAVEQUERIES`, `DONOTCACHEPAGE`, `WP_DEBUG`, `DISALLOW_FILE_EDIT`
- [ ] No `wp_set_current_user()`, `wp_set_auth_cookie()`, or `WP_Application_Passwords::create_new_application_password()` calls
- [ ] All URLs in readme.txt (Plugin URI, Author URI, License URI, ToS, Privacy) return HTTP 200

## Release Process

- [ ] Branch: `release/vX.Y.Z` (never push directly to main)
- [ ] GitHub Actions: all checks green
- [ ] Plugin zip: root folder matches the plugin slug (e.g. `your-plugin-slug/`)
- [ ] Zip tested: fresh install → activate → spot-check
- [ ] Release notes written (non-technical, user-focused)

---

**Sign-off**: Only release when all `[ ]` above are checked. For hotfix releases, minimum required: PHP lint, activation test, deactivation test.
