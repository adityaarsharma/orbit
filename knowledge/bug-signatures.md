# Orbit — WordPress Bug-Signature Database

> A general detection knowledge base so an Orbit agent catches these end-to-end, even when the operator never names them. Each signature = the code pattern → a detection hint (grep/AST target) → edge/backward cases. Sourced from Patchstack/WPScan/WordPress-core/PHP-manual (2025–2026). Public CVEs are named as examples; no vendor-specific content.

## Landscape (weighting)
2025: ~11,334 WP-ecosystem vulns (+42% YoY); 91% in plugins. Type mix (H1 2025): **XSS 34.7% · CSRF 19% · LFI 12.6% · Broken Access Control 10.9% · SQLi 7.2%** — top 5 ≈ 85% of the surface, ~57% unauthenticated. Weight static analysis toward these; attackers mass-exploit *old* versions, so version-matrix testing matters as much as latest-WP.

## Category A — Security
- **A1 XSS, unescaped output:** `echo` of `get_option`/`$_REQUEST`/meta into HTML without `esc_html|esc_attr|esc_url|wp_kses`. Trace taint superglobals+DB reads → output sinks. Edge: safe-on-save but wrong-context-on-render (escape late, per-context); old DB rows unescaped; contributor-reachable admin output.
- **A2 wrong-function XSS:** `sanitize_text_field` used as an escaper (doesn't escape quotes); `esc_url_raw` for display; `__()`/`_e()` echoed without `esc_html__`/`esc_html_e`.
- **A3 shortcode-attr XSS:** `extract(shortcode_atts(...))` then unescaped `$atts` in style/attr (contributor+). Flag every `add_shortcode` callback.
- **A4 block render_callback XSS:** dynamic block echoes attrs/meta without `wp_kses_post`; `get_block_wrapper_attributes()` then raw `style=`.
- **A5 SQLi concat:** `$wpdb->get_var("...=".$_REQUEST)`. Flag `$wpdb->(query|get_*)` with `.$`/`{$var}` of request data and no `->prepare`.
- **A6 esc_sql/sanitize mistaken for prepare** (unquoted numeric context stays unprotected).
- **A7 unprepared identifiers:** `ORDER BY $col`, `IN($csv)`, dynamic table/column — placeholders don't cover identifiers; require allowlist.
- **A8 CSRF:** `wp_ajax_*`/`admin_post_*` that writes (`update_option`/meta/`$wpdb`/file) with **no nonce**. Require `wp_verify_nonce`/`check_admin_referer`/`check_ajax_referer`.
- **A9 broken nonce logic:** `if (isset($_POST['action']) && !wp_verify_nonce(...))` — omitting the param skips the check. Fail-closed: `if (!isset() || !wp_verify_nonce())`. Also require `wp_unslash`+`sanitize` on nonce.
- **A10 broken access control:** `wp_ajax_*`/`admin_init`/`admin_post_*` assumed privileged (only subscriber+). Require `current_user_can()` matching op sensitivity; `nopriv` = unauthenticated.
- **A11 REST permission_callback:** `=> '__return_true'` or missing on a mutating/disclosing route.
- **A12 auth bypass / priv-esc:** role/cap from request (`update_user_meta` `wp_capabilities`), `==` on hashes/tokens (use `hash_equals`), weak token randomness.
- **A13 arbitrary file upload:** `move_uploaded_file($_FILES...['name'])` with no type/ext/MIME allowlist; route via `wp_handle_upload`+`mimes`. Edge: `shell.php.jpg` double-ext, `.phtml`/`.svg`, CSRF-chained.
- **A14 path traversal → file read:** `file_get_contents($_GET['file'])`; require `realpath()` containment. Edge: `%2e%2e`, null-byte, reads `wp-config`.
- **A15 arbitrary file delete:** `unlink($dir.$_GET)` — deleting `wp-config` forces install-reset takeover.
- **A16 LFI/RFI:** `include`/`require($_GET)`. **A17 SSRF:** `wp_remote_get($_GET['url'])` — use `wp_safe_remote_get` + host allowlist (blind SSRF hits `169.254.169.254`).
- **A18 PHP Object Injection:** `unserialize`/`maybe_unserialize` of request/cookie/meta → POP chain. Public CVE examples: GiveWP, Forminator (CVE-2025-6464). Flag absence of `['allowed_classes'=>false]`; prefer JSON.
- **A19 information disclosure:** `var_dump`/`print_r` of sensitive data, `WP_DEBUG_DISPLAY` on, REST `/users` author enum, readme version leak.
- **A20 hardcoded secrets / weak crypto:** `md5`/`sha1`/`mt_rand`/`uniqid` as security tokens (use `random_bytes`/`wp_generate_password`); keys in `.js`/`.bak`.

## Category B — WordPress Core Compatibility (6.5 → 7.0.x)
- **B1 (highest-frequency break) translations too early (WP 6.7+):** `__()`/`_e()`/`load_plugin_textdomain` before `init` → `_load_textdomain_just_in_time` notice. Hook to `init`. Silent on <6.7, so hides unless CI tests 6.7+.
- **B2 autoload change (WP 6.6):** `autoload` col now `yes/no/auto/auto-on/auto-off`; large options (~150KB+) default **not** autoloaded. Flag code assuming `'yes'`/`'no'`.
- **B3 block registration (6.7):** many `register_block_type` each parsing `block.json` → `wp_register_block_metadata_collection` on 6.7+ (feature-detect for <6.7).
- **B4 Interactivity API breaking changes** 6.5→6.7 (`data-wp-*`, `store()`, `getContext`).
- **B5 Block Bindings (6.7):** `__experimental` prefix dropped.
- **B6 FSE/HTML-API surface:** contributor-role injection in template parts / `WP_HTML_Tag_Processor`.
- **B7 deprecated/removed core fns** (`get_page_by_title` deprecated 6.2, etc.) — capture `_deprecated_function`/`_doing_it_wrong`.
- **B8 WP <7.0.2 REST batch-route confusion + SQLi** — add 7.0.x to the matrix if the plugin uses batch REST / dynamic SQL.
- **Server:** WP ≥6.8 incompatible with PHP 7.4 on Debian 11; core compatible PHP 8.1/8.2/8.3.

## Category C — WooCommerce (HPOS + block checkout)
- **C1 HPOS direct post/postmeta on orders:** `get_post_meta($order_id, ...)` — under HPOS orders aren't in `wp_posts`/`postmeta`. Use `wc_get_order()->get_meta()/save()`. Edge: compatibility-mode hides it (breaks when sync off); test CPT **and** HPOS.
- **C2 HPOS querying:** `WP_Query`/`get_posts` `post_type=shop_order` → `wc_get_orders()`.
- **C3 HPOS order-screen hooks:** `manage_edit-shop_order_columns` → `manage_woocommerce_page_wc-orders_columns`; metabox `$post_or_order` may be `WP_Post` OR order.
- **C4 HPOS compat not declared:** missing `FeaturesUtil::declare_compatibility('custom_order_tables', __FILE__, true)`.
- **C5 Cart/Checkout Blocks compat not declared** (`'cart_checkout_blocks'`).
- **C6 checkout custom fields via legacy filter only** → renders on shortcode not block checkout; needs Additional Checkout Fields API + Store API.
- **C7 payment gateway with no block integration** (`AbstractPaymentMethodType` + JS `registerPaymentMethod`).
- **C8 Store API extension without namespace/schema** (filtering HTML instead of `ExtendSchema`).
- **C9 Woo translation early-loading** (mirrors B1).

## Category D — i18n
- **D1 text domain ≠ plugin slug** → translate.wordpress.org never loads. Assert domain == slug; flag variable domains.
- **D2 `load_plugin_textdomain` wrong relative path or pre-`init` timing.**
- **D3 JS/block strings without `wp_set_script_translations($handle,$domain,$path)`** → UI stays English; verify `wp-i18n` in `index.asset.php` deps.
- **D4 JSON translation md5 mismatch:** `.po`→JSON not built via `wp i18n make-json` → not named `${domain}-${locale}-${md5}.json`.
- **D5 JS↔PHP label parity drift:** label in PHP `.pot` but not JS extraction. Edge: `%1$s` ordering differs; `_n()` plural PHP-only.
- **D6 stale `.pot` / JSON_UNESCAPED_UNICODE corruption:** custom `json_encode` without `JSON_UNESCAPED_UNICODE` mangles non-Latin. Require the flag in hand-built translation JSON.

## Category E — Performance & Database
- **E1 autoload bloat:** `add_option($k,$big)` autoloaded → unserialized every request. Check `SELECT SUM(LENGTH(option_value)) FROM wp_options WHERE autoload IN('yes','auto-on','auto')` < 1MB.
- **E2 N+1:** per-item `get_post_meta`/`get_term_meta` inside a loop without priming caches.
- **E3 missing `$wpdb->prepare` / unindexed custom tables:** `dbDelta` schema lacking `KEY`/`INDEX`; full-table `LIKE '%..%'`.
- **E4 uninstall cleanup missing:** no `uninstall.php`/`register_uninstall_hook`; verify removes prefixed options, drops tables, clears cron, guarded by `WP_UNINSTALL_PLUGIN`.
- **E5 blocking/over-eager assets:** enqueue on every page regardless of block/shortcode presence; render-blocking `<script>` in head; raw echoes.
- **E6 transients misused:** `set_transient(...,0)` no expiry; high-churn write storms.

## Category F — PHP 8.0–8.3 Breaking Changes
- **F1 `create_function()` removed 8.0 → FATAL.** grep `create_function(` → closures. (Most common hard break.)
- **F2 `each()` removed 8.0 → FATAL.**
- **F3 curly-brace offset `$str{0}` removed 8.0 → parse/fatal → `[]`.**
- **F4 null to non-nullable internal param** (8.1 deprecation → 9.0 error): `trim(get_option('maybe_null'))`. Data-dependent; silent 8.0, deprecation 8.1–8.3, FATAL php9. Guard with `?? ''`.
- **F5 dynamic (undeclared) properties deprecated 8.2 → 9.0 error:** `$this->foo` where `foo` undeclared and no `#[AllowDynamicProperties]`.
- **F6 optional-before-required param 8.0; named-arg calls into core fns** (param names not a stable contract).
- **F7 `utf8_encode`/`utf8_decode` deprecated 8.2 → `mb_convert_encoding`.**
- **F8 return-type deprecations on `ArrayAccess`/`Iterator`/`Countable`/`JsonSerializable`** without `#[\ReturnTypeWillChange]` (8.1).
- **F9 `@` no longer silences fatals 8.0;** handlers checking `error_reporting()==0` break.
- **F10 stricter `TypeError`/LSP fatals 8.0.** Run under 8.1/8.2/8.3 capturing fatals.

## How Orbit uses this
- **Static/SAST pass** (A1–A20, C1–C3, E3, F1–F3, F6–F9): taint from superglobals + DB reads → sinks.
- **Version matrix** (B1–B8, F4–F5, F10): WP 6.5/6.6/6.7/6.8/7.0.x × PHP 8.0/8.1/8.2/8.3, capturing `_doing_it_wrong`/`_deprecated_*`/fatals — many are data- and version-dependent, invisible on single-version CI.
- **WooCommerce matrix** (C1–C9): HPOS on (sync off) / compat-mode / legacy CPT × block + shortcode checkout.
- **i18n pass** (D1–D6) · **Perf/DB pass** (E1–E6).
