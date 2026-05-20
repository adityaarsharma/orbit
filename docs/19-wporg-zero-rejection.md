# WP.org Zero-Rejection Release Flow

> One page. Run this exact sequence before every WordPress.org submission. If every step exits 0, the plugin will not be auto-rejected. Manual review is still a human in the loop — but the mechanical reject reasons are gone.

---

## Prerequisites (one-time)

- Docker Desktop installed and running
- `wp-env` installed (`npm install -g @wordpress/env`)
- Orbit installed (`bash install.sh`)

That's it. No host WP-CLI required — Orbit bootstraps a Dockerized WP automatically.

---

## The release command

```bash
cd /path/to/your-plugin

# Single command. Auto-bootstraps Docker, installs plugin-check, runs all gates.
bash ~/Claude/orbit/scripts/gauntlet.sh --plugin . --mode release
```

`--mode release` makes every WP.org-relevant check a **hard fail**:

- If Plugin Check can't run via host wp-cli or Docker wp-env → fails the gate
- If Plugin Check returns any ERROR → fails the gate
- If readme.txt, plugin header, or version parity is wrong → fails the gate
- If GPL license is missing or incompatible → fails the gate
- If zip hygiene flags `.git/`, source maps, or dev deps → fails the gate

Exit 0 = green to tag. Exit 1 = do not submit.

---

## What blocks an WP.org submission, and which Orbit skill catches it

| WP.org reject reason | Orbit check | Action if it fires |
|---|---|---|
| Unescaped output (XSS) | `orbit-wp-security`, Plugin Check | Wrap with `esc_html()`, `esc_attr()`, `wp_kses_post()` per context |
| Unsanitized input | `orbit-wp-security`, Plugin Check | `sanitize_text_field()`, `absint()`, `sanitize_email()` at the boundary |
| Missing nonces on form/AJAX | `orbit-wp-security`, Plugin Check | `wp_nonce_field()` + `check_admin_referer()` / `wp_verify_nonce()` |
| Missing capability checks | `orbit-broken-access-control` | `current_user_can( 'manage_options' )` before admin actions |
| `eval()`, `base64_decode()`, `create_function()` | Plugin Check, `orbit-wp-standards` | Remove. No exceptions. |
| Calling external services without consent | `orbit-gdpr`, `orbit-wp-standards` | Privacy policy + opt-in + Privacy API hooks |
| Bundling non-GPL libraries | `check-license.sh` | Replace or remove |
| readme.txt `Stable tag` ≠ plugin header `Version` | `check-version-parity.sh` | Match all three: header, readme, git tag |
| Missing `Tested up to:` | `check-plugin-header.sh` | Add current WP version, bump on every WP minor |
| Trademark in slug or readme | Plugin Check, `orbit-release-meta` | Rename or remove trademark mention |
| i18n: missing text domain, hardcoded strings | `orbit-i18n`, Plugin Check | `__( 'Text', 'your-textdomain' )` everywhere |
| Hidden `.git/`, `node_modules/`, source maps in zip | `orbit-zip-hygiene` | Exclude via `.distignore` |

---

## The 4-gate release sequence (what `--mode release` runs)

```
Gate 1 — Preflight              (5 sec)     bash scripts/gauntlet-dry-run.sh
Gate 2 — Release metadata       (30 sec)    Plugin header, readme.txt, version parity, license
Gate 3 — Full gauntlet          (45-60 min) PHP lint, WPCS, Plugin Check (Docker), PHPStan, security, i18n, perf, a11y, e2e
Gate 4 — Evidence pack          (10 sec)    Generates reports/index.html with proof of every check
```

Gate 3 is where Plugin Check runs. The script tries host `wp-cli` first; if that fails it auto-starts wp-env, installs the official `plugin-check` addon, and runs `wp-env run cli wp plugin check <slug>` inside the container.

---

## If Gate 3 fails on Plugin Check

1. Read the actual errors printed (`gauntlet.sh` shows the first 20 lines of plugin-check output)
2. Map each error to the skill above
3. Fix the code (not the test)
4. Re-run `bash scripts/gauntlet.sh --plugin . --mode release`
5. Only tag once Gate 3 exits 0

Do not edit `.plugin-check-config.json` to skip security or forbidden-function checks. Those exist because plugins that ship them get rejected.

---

## After the gate passes

```bash
# Match all three to the same version string
# (gauntlet has already verified parity, but double-check before tagging)
grep "^Version:" your-plugin.php
grep "^Stable tag:" readme.txt

git tag v2.3.0 && git push --tags
wp dist-archive .                 # produces your-plugin.2.3.0.zip
# Upload via SVN or the WP.org plugin upload form
```

Keep `reports/index.html` from Gate 4 as proof for the next support escalation or manager review.

---

## Hard rules

- Never submit with Plugin Check ERRORs unresolved
- Never submit when `--mode release` exits non-zero
- Never edit a test to make it pass — fix the code
- Never bundle dev dependencies, source maps, or `.git/` in the release zip

These are the four reasons 90% of plugins get rejected. Orbit catches all four mechanically.

---

## Appendix — Canonical WP.org rules (fetched 2026-05-18)

Sources crawled directly from developer.wordpress.org. This is the law the plugin review team applies. Every function below is what they expect to see; missing or wrong context = reject.

### The WP.org plugin team's top-3 reject reasons (verbatim from the [Developer FAQ](https://developer.wordpress.org/plugins/wordpress-org/plugin-developer-faq/))

1. **The plugin contains unescaped output** — fix with the escaping table below
2. **The plugin accepts unsanitized data** — fix with the sanitizing table below
3. **The plugin processes form data without a nonce** — fix with the nonce lifecycle below

> "If the code in your plugin falls into one of the above categories, **your plugin will not be approved.**"

### Hard rules (verbatim from [Security APIs](https://developer.wordpress.org/apis/security/))

- "Never trust user input."
- "Escape as late as possible."
- "Escape everything from untrusted sources (e.g., databases and users), third-parties."
- "Never assume anything."
- "Always make sure to *validate* and *sanitize* user input before using it, and to *escape* on output."

### Escaping functions ([Escaping Data](https://developer.wordpress.org/apis/security/escaping/))

| Function | Use for |
|---|---|
| `esc_html()` | HTML element content (between tags) |
| `esc_attr()` | HTML element attributes |
| `esc_url()` | URLs in `src`, `href`, etc. |
| `esc_url_raw()` | URLs going into the database or non-display use |
| `esc_js()` | Inline JavaScript values |
| `esc_textarea()` | Content inside `<textarea>` |
| `esc_xml()` | XML blocks |
| `wp_kses()` | Non-trusted HTML with a custom allowlist |
| `wp_kses_post()` | Post-content HTML (uses the post allowlist) |
| `wp_kses_data()` | Comment-style HTML |

Rules: "You always want to escape when you echo, not before." Escape the full string, not parts. `wp_localize_script()` escapes on its own — don't double-escape.

### Sanitizing functions ([Sanitizing Data](https://developer.wordpress.org/apis/security/sanitizing/))

| Function | Use for |
|---|---|
| `sanitize_text_field()` | Single-line text inputs |
| `sanitize_textarea_field()` | Multi-line textarea content |
| `sanitize_email()` | Email addresses |
| `sanitize_file_name()` | File names |
| `sanitize_hex_color()` / `sanitize_hex_color_no_hash()` | Hex color codes |
| `sanitize_html_class()` | HTML class attribute values |
| `sanitize_key()` | Lowercase alphanumeric keys (option names, etc.) |
| `sanitize_meta()` | Post/user/term meta values |
| `sanitize_mime_type()` | MIME types |
| `sanitize_option()` | WordPress options |
| `sanitize_sql_orderby()` | SQL `ORDER BY` clauses |
| `sanitize_term()` / `sanitize_term_field()` | Taxonomy terms |
| `sanitize_title()` / `sanitize_title_for_query()` / `sanitize_title_with_dashes()` | Post slugs / titles |
| `sanitize_user()` | Usernames |
| `sanitize_url()` | URLs (use `esc_url_raw()` for DB storage) |
| `wp_kses()` / `wp_kses_post()` | HTML content (sanitize against an allowlist) |

Rule: "Validation is preferred over sanitization because validation is more specific." Use `absint()`, `is_email()`, `in_array()` with a strict third arg, etc., when the input is known to be a specific shape.

### Nonces ([Nonces](https://developer.wordpress.org/apis/security/nonces/))

**Create:**
- `wp_create_nonce( $action )` — returns the hash
- `wp_nonce_field( $action )` — hidden form field + referrer
- `wp_nonce_url( $url, $action )` — appends nonce to a URL

**Verify:**
- `wp_verify_nonce( $nonce, $action )` — returns false on failure
- `check_admin_referer( $action )` — admin screens; terminates on failure
- `check_ajax_referer( $action )` — AJAX; terminates by default on failure

Lifecycle: default 24h, internally two 12h ticks. Use the most specific action string possible (`"delete-post_{$post_id}"`, not `"delete"`).

Rules verbatim:
- "Nonces should never be relied on for authentication, authorization, or access control."
- "Always assume nonces can be compromised."
- "Protect functions using `current_user_can()`."

### Capability checks ([Checking User Capabilities](https://developer.wordpress.org/plugins/security/checking-user-capabilities/))

Function: `current_user_can( $capability )` — the canonical check. Common capabilities: `manage_options` (admin settings), `edit_posts`, `edit_others_posts`, `delete_posts`, `publish_posts`, `upload_files`.

Rule verbatim: "make sure to run your code only when the current user has the necessary capabilities."

Anti-pattern (from the docs): adding admin actions on `init` without a capability check lets any visitor trigger them. Always wrap:

```php
if ( current_user_can( 'edit_others_posts' ) ) {
    add_action( 'init', 'my_admin_action' );
}
```

### The standard secure handler (combines all four)

```php
add_action( 'admin_post_my_action', 'my_handler' );
function my_handler() {
    // 1. Capability
    if ( ! current_user_can( 'manage_options' ) ) {
        wp_die( esc_html__( 'Forbidden', 'my-textdomain' ), 403 );
    }
    // 2. Nonce
    check_admin_referer( 'my_action' );
    // 3. Sanitize input
    $value = isset( $_POST['my_field'] )
        ? sanitize_text_field( wp_unslash( $_POST['my_field'] ) )
        : '';
    // 4. Validate
    if ( '' === $value ) {
        wp_die( esc_html__( 'Missing value', 'my-textdomain' ), 400 );
    }
    update_option( 'my_option', $value );
    // 5. Escape on output
    wp_safe_redirect( esc_url_raw( admin_url( 'options-general.php?page=my-plugin&saved=1' ) ) );
    exit;
}
```

Every line of this template maps to a WP.org reject reason. If your handler is missing any of the four (capability, nonce, sanitize, escape) — Plugin Check will flag it and the reviewer will reject.

### How Orbit enforces each rule

| WP.org rule | Orbit skill / check |
|---|---|
| Escape on output | `orbit-wp-security`, Plugin Check Step 2b |
| Sanitize on input | `orbit-wp-security`, Plugin Check Step 2b, WPCS Step 2 |
| Nonce on every form/AJAX | `orbit-wp-security`, Plugin Check Step 2b |
| Capability check on admin actions | `orbit-broken-access-control` |
| Specific action strings | `orbit-wp-standards` rule set |
| No `eval()` / `base64_decode()` / `create_function()` | Plugin Check + `orbit-wp-standards` |
| Validate before sanitize where possible | `orbit-wp-security` |
| GPL-compatible licenses only | `check-license.sh` |

If `gauntlet.sh --mode release` exits 0, every rule in this appendix has been mechanically verified.

