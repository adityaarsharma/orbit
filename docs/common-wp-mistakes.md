# Common WordPress Coding Mistakes
> What senior WordPress developers know to avoid — and what this QA pipeline catches automatically.

---

## Security Mistakes

### 1. Output Without Escaping (XSS)

```php
// BAD — user input directly in HTML
echo $_GET['message'];
echo get_option('my_setting');

// GOOD
echo esc_html( $_GET['message'] );
echo esc_html( get_option('my_setting') );

// For HTML content (e.g. post content from trusted editors)
echo wp_kses_post( $content );

// For attributes
echo '<input value="' . esc_attr( $value ) . '">';

// For URLs
echo '<a href="' . esc_url( $url ) . '">';
```

**Caught by**: `WordPress.Security.EscapeOutput` (phpcs)

---

### 2. Forms Without Nonce Verification (CSRF)

```php
// BAD — no verification that the request came from your form
if ( isset( $_POST['my_action'] ) ) {
    update_option( 'my_setting', $_POST['value'] );
}

// GOOD
if ( isset( $_POST['my_action'] ) && check_admin_referer( 'my_action_nonce' ) ) {
    update_option( 'my_setting', sanitize_text_field( $_POST['value'] ) );
}

// In your form:
wp_nonce_field( 'my_action_nonce' );
```

**Caught by**: `WordPress.Security.NonceVerification` (phpcs)

---

### 3. Direct SQL Without Prepare (SQL Injection)

```php
// BAD
$results = $wpdb->get_results(
    "SELECT * FROM $wpdb->posts WHERE post_author = " . $_GET['author']
);

// GOOD
$results = $wpdb->get_results(
    $wpdb->prepare(
        "SELECT * FROM $wpdb->posts WHERE post_author = %d",
        intval( $_GET['author'] )
    )
);
```

**Caught by**: `WordPress.DB.PreparedSQL` (phpcs)

---

### 4. REST Endpoints Without Permission Check

```php
// BAD — anyone can call this endpoint
register_rest_route( 'my-plugin/v1', '/settings', [
    'methods'  => 'POST',
    'callback' => 'my_save_settings',
] );

// GOOD
register_rest_route( 'my-plugin/v1', '/settings', [
    'methods'             => 'POST',
    'callback'            => 'my_save_settings',
    'permission_callback' => function() {
        return current_user_can( 'manage_options' );
    },
] );
```

**Caught by**: `/wordpress-penetration-testing` skill, `WordPress.WP.Capabilities` (phpcs)

---

### 5. Missing Input Sanitization

```php
// BAD — storing raw user input
update_option( 'my_text', $_POST['text'] );
update_post_meta( $post_id, 'my_url', $_POST['url'] );

// GOOD
update_option( 'my_text', sanitize_text_field( $_POST['text'] ) );
update_post_meta( $post_id, 'my_url', esc_url_raw( $_POST['url'] ) );

// By type:
sanitize_text_field()    // Plain text
sanitize_textarea_field()// Multi-line text
sanitize_email()         // Email addresses
esc_url_raw()            // URLs stored in DB
absint()                 // Positive integers
intval()                 // Integers
sanitize_key()           // Slugs, keys
wp_kses_post()           // HTML with allowed tags
```

---

## Performance Mistakes

### 6. N+1 Database Queries

```php
// BAD — fires one query per post in the loop
$posts = get_posts([ 'numberposts' => 50 ]);
foreach ( $posts as $post ) {
    $author = get_user_by( 'id', $post->post_author ); // 50 queries!
    $meta   = get_post_meta( $post->ID, 'my_key', true ); // 50 more!
}

// GOOD — pre-warm the cache
$posts    = get_posts([ 'numberposts' => 50 ]);
$post_ids = wp_list_pluck( $posts, 'ID' );
update_postmeta_cache( $post_ids ); // 1 query to cache all meta

$user_ids = array_unique( wp_list_pluck( $posts, 'post_author' ) );
// Pre-load users via a single query
get_users([ 'include' => $user_ids ]);

foreach ( $posts as $post ) {
    $meta = get_post_meta( $post->ID, 'my_key', true ); // hits cache, 0 queries
}
```

**Caught by**: `db-profile.sh`, `/performance-engineer`, `/database-optimizer`

---

### 7. Loading Assets on Every Page

```php
// BAD — loads plugin CSS/JS everywhere
add_action( 'wp_enqueue_scripts', 'my_plugin_assets' );
function my_plugin_assets() {
    wp_enqueue_style( 'my-plugin', MY_PLUGIN_URL . 'assets/style.css' );
    wp_enqueue_script( 'my-plugin', MY_PLUGIN_URL . 'assets/app.js' );
}

// GOOD — only where needed
function my_plugin_assets() {
    if ( ! is_singular( 'my_post_type' ) && ! has_shortcode( get_post()->post_content, 'my_shortcode' ) ) {
        return;
    }
    wp_enqueue_style( 'my-plugin', MY_PLUGIN_URL . 'assets/style.css', [], MY_PLUGIN_VERSION );
    wp_enqueue_script( 'my-plugin', MY_PLUGIN_URL . 'assets/app.js', ['jquery'], MY_PLUGIN_VERSION, true );
}
```

**Caught by**: Lighthouse TBT score, `/performance-engineer`

---

### 8. Synchronous HTTP Calls on Page Load

```php
// BAD — blocks page render if external API is slow/down
add_action( 'init', function() {
    $response = wp_remote_get( 'https://api.example.com/data' );
    $data = json_decode( wp_remote_retrieve_body( $response ) );
});

// GOOD — cache the result, refresh in background via cron
function get_api_data() {
    $cached = get_transient( 'my_api_data' );
    if ( false !== $cached ) {
        return $cached;
    }

    // This only runs when cache is empty
    $response = wp_remote_get( 'https://api.example.com/data' );
    $data     = json_decode( wp_remote_retrieve_body( $response ), true );

    set_transient( 'my_api_data', $data, HOUR_IN_SECONDS );
    return $data;
}
```

---

### 9. Wrong Autoload on Options

```php
// BAD — large data autoloaded on every request
update_option( 'my_plugin_cache', $huge_array ); // autoload=yes by default

// GOOD
update_option( 'my_plugin_cache', $huge_array, false ); // autoload=no
update_option( 'my_plugin_settings', $settings );       // settings: autoload=yes is fine
update_option( 'my_plugin_logs', $logs, false );        // logs: never autoload
```

---

## WordPress API Mistakes

### 10. Rolling Custom Solutions Instead of WP APIs

```php
// BAD — custom session handling
$_SESSION['my_data'] = $data;

// GOOD — use WP transients or user meta
set_transient( 'my_user_' . get_current_user_id(), $data, DAY_IN_SECONDS );

// BAD — custom file operations
file_put_contents( ABSPATH . 'wp-content/my-file.json', json_encode($data) );

// GOOD — WP Filesystem API
global $wp_filesystem;
WP_Filesystem();
$wp_filesystem->put_contents( WP_CONTENT_DIR . '/my-file.json', json_encode($data) );
```

---

### 11. Hardcoding Paths and URLs

```php
// BAD
$path = '/var/www/html/wp-content/plugins/my-plugin/';
$url  = 'https://mysite.com/wp-content/plugins/my-plugin/';

// GOOD
$path = plugin_dir_path( __FILE__ );
$url  = plugin_dir_url( __FILE__ );

// For themes
$path = get_template_directory() . '/';
$url  = get_template_directory_uri() . '/';
```

---

### 12. Not Prefixing Functions, Classes, and Options

```php
// BAD — will conflict with other plugins
function get_settings() { ... }
class Settings { ... }
update_option( 'settings', $data );
add_filter( 'init', 'setup' );

// GOOD — use your plugin prefix
function tpa_get_settings() { ... }
class TPA_Settings { ... }
update_option( 'tpa_settings', $data );
add_filter( 'init', 'tpa_setup' );
```

---

### 13. Not Cleaning Up on Uninstall

```php
// BAD — leaves orphaned data in the database after uninstall

// GOOD — in uninstall.php
if ( ! defined( 'WP_UNINSTALL_PLUGIN' ) ) exit;

// Remove all plugin options
delete_option( 'my_plugin_settings' );
delete_option( 'my_plugin_cache' );

// Remove post meta
delete_post_meta_by_key( 'my_plugin_data' );

// Remove custom tables
global $wpdb;
$wpdb->query( "DROP TABLE IF EXISTS {$wpdb->prefix}my_plugin_table" );

// Remove transients
delete_transient( 'my_plugin_cache' );
```

---

## Gutenberg / Block Mistakes

### 14. Inline Styles in Block Output

```php
// BAD — inline styles can't be overridden easily
function my_block_render( $attributes ) {
    return '<div style="color:' . $attributes['color'] . ';">...</div>';
}

// GOOD — use CSS custom properties or block support classes
function my_block_render( $attributes ) {
    $style = '--my-block-color: ' . sanitize_hex_color( $attributes['color'] ) . ';';
    return '<div class="wp-block-my-block" style="' . esc_attr( $style ) . '">...</div>';
}
```

---

### 15. Not Using block.json

Every modern block must have a `block.json` file. Using `register_block_type( __FILE__ )` (PHP-only registration) misses:
- Block.json: metadata, attribute types, editor/frontend scripts separation
- Server-side rendering declaration
- Script handles auto-registration

```json
{
  "apiVersion": 3,
  "name": "my-plugin/my-block",
  "title": "My Block",
  "category": "widgets",
  "attributes": {
    "content": { "type": "string", "default": "" }
  },
  "editorScript": "file:./index.js",
  "style": "file:./style.css"
}
```

---

## Elementor-Specific Mistakes

### 16. Not Checking Elementor Version

```php
// BAD — crashes if Elementor not active or old version
use Elementor\Widget_Base;

// GOOD
if ( ! did_action( 'elementor/loaded' ) ) {
    return;
}

add_action( 'elementor/widgets/register', function( $widgets_manager ) {
    // Register widgets here
});
```

### 17. Registering Widgets on Wrong Hook

```php
// BAD — too early, Elementor not ready
add_action( 'init', 'register_my_widgets' );

// GOOD
add_action( 'elementor/widgets/register', 'register_my_widgets' );
```

---

## How This QA Pipeline Catches These

| Mistake | Automated Check | Manual Check |
|---|---|---|
| Missing escaping | phpcs `EscapeOutput` | `/wordpress-penetration-testing` |
| Missing nonce | phpcs `NonceVerification` | `/wordpress-penetration-testing` |
| SQL injection | phpcs `PreparedSQL` | `/wordpress-penetration-testing` |
| REST auth missing | phpcs `Capabilities` | `/wordpress-penetration-testing` |
| N+1 queries | `db-profile.sh` Query Monitor | `/database-optimizer` |
| Assets on every page | Lighthouse TBT | `/performance-engineer` |
| Autoload bloat | `db-profile.sh` | `/database-optimizer` |
| Hardcoded paths | phpcs WPCS sniffs | `/wordpress-plugin-development` |
| No cleanup on uninstall | `/wordpress-plugin-development` | Pre-release checklist |
| Missing block.json | `/wordpress-plugin-development` | Code review |
| Elementor wrong hook | Playwright editor test | `/wordpress-plugin-development` |

---

## WordPress Runtime Traps

> **The bugs that pass every linter, every unit test, and every code review — and only break when the WordPress runtime contract bites.** Static analysis can't catch most of these because they depend on hosting config (DISABLE_WP_CRON), plugin load order (alphabetical), the Settings API's null-coalescing behavior, or the way a third-party plugin resolves its own tokens. These are the patterns to watch for in any non-trivial WP plugin.

### 18. Settings API Cross-Nulling

```php
// BAD — option registered but no form input renders for it
register_setting( 'my_group', 'my_option', [
    'sanitize_callback' => 'sanitize_on_off', // returns 'off' on null input
] );

// Form for a DIFFERENT option in the same group:
?>
<form action="options.php" method="post">
    <?php settings_fields( 'my_group' ); ?>
    <input type="checkbox" name="my_OTHER_option" />
    <?php submit_button(); ?>
</form>
<?php
// Saving this form posts only `my_OTHER_option`. WP iterates every option
// registered to `my_group` and calls update_option( 'my_option', null )
// because $_POST['my_option'] is absent. sanitize_on_off(null) returns 'off'
// — silently disabling `my_option` on every save.

// GOOD — preserve every option registered to the group, in every form
?>
<form action="options.php" method="post">
    <?php settings_fields( 'my_group' ); ?>
    <input type="checkbox" name="my_OTHER_option" />
    <!-- Preserve all other options registered to my_group -->
    <input type="hidden" name="my_option"
           value="<?php echo esc_attr( get_option( 'my_option', 'on' ) ); ?>" />
    <?php submit_button(); ?>
</form>
```

**Caught by:** `/orbit-code-quality` §6, `/orbit-code-reviewer` §10.1

---

### 19. Scheduling Work That Never Runs (DISABLE_WP_CRON)

```php
// BAD — assumes wp-cron will fire
wp_schedule_single_event( time() + 60, 'my_generate_summary', [ $post_id ] );

// Managed hosts (Kinsta, WP Engine, Cloudways, Pantheon) and any site with
// system cron set DISABLE_WP_CRON=true. Job queues forever, never runs.

// GOOD — expose a direct synchronous trigger
function my_generate_summary( $post_id ) { /* ... */ }
add_action( 'my_generate_summary', 'my_generate_summary' );

// Admin UI / REST / WP-CLI can run it directly:
public static function run_now( $post_id ) {
    my_generate_summary( $post_id );
}

// And show a notice if DISABLE_WP_CRON is set:
add_action( 'admin_notices', function () {
    if ( defined( 'DISABLE_WP_CRON' ) && DISABLE_WP_CRON ) {
        echo '<div class="notice notice-warning"><p>WP-Cron is disabled. Configure system cron OR use the Run Now button.</p></div>';
    }
} );
```

**Caught by:** `/orbit-code-quality` §6, `/orbit-code-reviewer` §10.2

---

### 20. Conditional `add_rewrite_rule()` Toggle Trap

```php
// BAD — rule only registers if option is on, but toggling the option
// after init has fired doesn't add the rule for THIS request
add_action( 'init', function () {
    if ( get_option( 'my_feature' ) === 'on' ) {
        add_rewrite_rule( '^my-feature/?$', 'index.php?my_feature=1', 'top' );
    }
} );

// User toggles option on, clicks Save, hits /my-feature → 404. The rule
// won't exist until the NEXT init runs. flush_rewrite_rules() in the toggle
// handler flushes nothing — the rule isn't there to flush.

// GOOD — when the toggle flips on, register the rule AND flush
add_action( 'update_option_my_feature', function ( $old, $new ) {
    if ( $new === 'on' ) {
        add_rewrite_rule( '^my-feature/?$', 'index.php?my_feature=1', 'top' );
        flush_rewrite_rules( false );
    }
}, 10, 2 );
```

**Caught by:** `/orbit-code-quality` §6, `/orbit-code-reviewer` §10.3

---

### 21. Bulk Option Restore Wipes User Data

```php
// BAD — "reset to defaults" loop overwrites existing user values
$defaults = [
    'enable_feature_a' => 'on',
    'enable_feature_b' => 'off',
    'api_key'          => '',
];
foreach ( $defaults as $opt => $default ) {
    update_option( "myplugin_$opt", $default );
}
// User's API key is now wiped.

// GOOD — guard with existence check
foreach ( $defaults as $opt => $default ) {
    $key      = "myplugin_$opt";
    $sentinel = '__myplugin_unset__';
    if ( get_option( $key, $sentinel ) === $sentinel ) {
        update_option( $key, $default );
    }
}
```

**Caught by:** `/orbit-code-quality` §6, `/orbit-code-reviewer` §10.4

---

### 22. Auto-Generation Hook Only on `publish_post`

```php
// BAD — only generates on initial publish. Pre-existing posts and re-edits
// never trigger generation.
add_action( 'publish_post', 'myplugin_generate_summary' );

// GOOD — handle re-edits + idempotent re-run
add_action( 'save_post', function ( $post_id, $post ) {
    if ( wp_is_post_revision( $post_id ) ) return;
    if ( $post->post_status !== 'publish' ) return;

    // Idempotent guard: only regenerate if content changed
    $hash    = md5( $post->post_content );
    $old     = get_post_meta( $post_id, '_myplugin_content_hash', true );
    if ( $hash === $old ) return;

    myplugin_generate_summary( $post_id );
    update_post_meta( $post_id, '_myplugin_content_hash', $hash );
}, 10, 2 );
```

**Caught by:** `/orbit-code-quality` §6, `/orbit-code-reviewer` §10.5

---

### 23. Superglobal Reads Without `wp_unslash()`

```php
// BAD — WP slash-escapes superglobals on load; raw reads leave stray backslashes
$title = sanitize_text_field( $_POST['post_title'] );

// GOOD
$title = sanitize_text_field( wp_unslash( $_POST['post_title'] ?? '' ) );

// Safe — bare isset/empty don't read the value
if ( isset( $_GET['key'] ) ) { /* ok */ }
```

**Caught by:** `phpcs WordPress.Security.ValidatedSanitizedInput`, `/orbit-code-quality` §6, `/orbit-code-reviewer` §10.6

---

### 24. Meta Value Type Drift (JSON String vs PHP Array)

```php
// BAD — writer stores JSON string, reader expects array
update_post_meta( $id, '_myplugin_faq', wp_json_encode( $faq_array ) );
// ...later...
$faq = get_post_meta( $id, '_myplugin_faq', true );
if ( is_array( $faq ) && count( $faq ) > 0 ) { // ← always false: $faq is string
    /* render FAQ */
}

// GOOD — pick one shape and enforce
// Option A: let WP serialize the array (recommended)
update_post_meta( $id, '_myplugin_faq', $faq_array );
$faq = get_post_meta( $id, '_myplugin_faq', true ); // returns array

// Option B: JSON everywhere — every reader must decode
$faq = json_decode( get_post_meta( $id, '_myplugin_faq', true ) ?: '[]', true );
```

**Caught by:** `/orbit-code-quality` §6, `/orbit-code-reviewer` §10.7

---

### 25. `%currentyear%` Stored as Literal in Third-Party SEO Meta

```php
// BAD — Rank Math / Yoast resolve %token% only when the user typed it.
// Programmatic writes bypass the resolver; the SERP shows the literal.
update_post_meta( $id, 'rank_math_title', 'Best Tools for %currentyear%' );

// GOOD — resolve before writing
$title = str_replace( '%currentyear%', wp_date( 'Y' ), $title );
update_post_meta( $id, 'rank_math_title', $title );

// OR — call the SEO plugin's own replacement filter
$title = apply_filters( 'rank_math/replacements', $title, get_post( $id ) );
// Yoast:  $title = wpseo_replace_vars( $title, get_post( $id ) );
update_post_meta( $id, 'rank_math_title', $title );
```

**Caught by:** `/orbit-code-quality` §6, `/orbit-code-reviewer` §10.8

---

### 26. Text-Statistics That Miscount Gutenberg Block Delimiters

```php
// BAD — counts em-dashes inside <!-- wp:foo --> comments as content
$em_dash_count = substr_count( $post->post_content, '—' );

// GOOD — strip block delimiters first
$clean = preg_replace( '/<!--\s*\/?wp:[^>]+-->/', '', $post->post_content );
$em_dash_count = substr_count( $clean, '—' );

// BETTER — render through the_content filter, then strip HTML
$rendered = apply_filters( 'the_content', $post->post_content );
$em_dash_count = substr_count( wp_strip_all_tags( $rendered ), '—' );
```

**Caught by:** `/orbit-code-quality` §6, `/orbit-code-reviewer` §10.9

---

### 27. Tab / REST Route Slug Mismatch

```php
// BAD — link goes to a tab the router doesn't recognize
?>
<a href="<?php echo esc_url( admin_url( 'admin.php?page=myplugin&tab=content-ai' ) ); ?>">Open</a>
<?php
// ...router...
$tab = sanitize_key( $_GET['tab'] ?? 'dashboard' );
switch ( $tab ) {
    case 'content':   /* never matches 'content-ai' */ break;
    default:          render_dashboard(); break; // silently falls through
}

// GOOD — single source of truth for slugs
const TAB_SLUGS = [ 'dashboard', 'content', 'crawlers', 'settings' ];
// Link only to slugs in the constant; router only switches on slugs in the constant.
```

**Caught by:** `/orbit-code-quality` §6, `/orbit-code-reviewer` §10.10

---

### 28. Pro / Free Filter Timing — Reader Fires Before Producer Registers

```php
// BAD — Free reads the filter at same priority Pro registers it.
// Plugin load order is alphabetical: if Free folder sorts first,
// the reader runs before Pro can hook in. Pro features stay locked.

// In Free (folder: a-myplugin):
add_action( 'plugins_loaded', function () {
    $is_pro = apply_filters( 'myplugin_is_pro', false );
    if ( $is_pro ) { /* unlock Pro features */ }
}, 10 );

// In Pro (folder: b-myplugin-pro):
add_action( 'plugins_loaded', function () {
    add_filter( 'myplugin_is_pro', '__return_true' );
}, 10 );
// Free's reader fires first → always sees false → Pro stays locked

// GOOD — reader runs at priority ≥20 OR on a later hook
add_action( 'plugins_loaded', function () {
    $is_pro = apply_filters( 'myplugin_is_pro', false );
    /* ... */
}, 20 );
// OR
add_action( 'init', function () {
    $is_pro = apply_filters( 'myplugin_is_pro', false );
    /* ... */
} );
```

**Caught by:** `/orbit-code-quality` §6, `/orbit-code-reviewer` §10.13

---

### 29. Activation Hook References Unloaded Constants/Classes

```php
// BAD — register_activation_hook can fire before bootstrap fully loads
// in network-activate / WP-CLI bulk-activate / upload-and-activate scenarios
register_activation_hook( __FILE__, function () {
    MyPlugin_Welcome::flag_activation();        // ← fatal: class not loaded
    update_option( 'version', MYPLUGIN_VERSION ); // ← fatal: constant not defined
} );

// GOOD — guard every plugin-namespaced reference
register_activation_hook( __FILE__, function () {
    if ( defined( 'MYPLUGIN_VERSION' ) ) {
        update_option( 'version', MYPLUGIN_VERSION );
    }
    if ( class_exists( 'MyPlugin_Welcome' ) ) {
        MyPlugin_Welcome::flag_activation();
    }
} );
```

**Caught by:** `/orbit-code-quality` §6, `/orbit-code-reviewer` §10.14

---

### How runtime-trap checks fit the QA pipeline

| Trap | Static analysis | Runtime check | Owner |
|---|---|---|---|
| Settings API cross-nulling | grep + form-input cross-ref | `/orbit-code-quality` §6.1 | Code Reviewer §10.1 |
| DISABLE_WP_CRON | grep `wp_schedule_*` + manual trigger check | `/orbit-code-quality` §6.2 | Code Reviewer §10.2 |
| Conditional `add_rewrite_rule` | grep + flow analysis | `/orbit-code-quality` §6.3 | Code Reviewer §10.3 |
| Bulk option restore wipe | grep `foreach` over defaults map | `/orbit-code-quality` §6.4 | Code Reviewer §10.4 |
| Hook only on `publish_post` | grep `add_action('publish_post')` | `/orbit-code-quality` §6.5 | Code Reviewer §10.5 |
| `$_GET/$_POST` w/o `wp_unslash` | phpcs `ValidatedSanitizedInput` | `/orbit-code-quality` §6.6 | Code Reviewer §10.6 |
| Meta type drift | cross-ref every write/read site | `/orbit-code-quality` §6.7 | Code Reviewer §10.7 |
| `%token%` literals in SEO meta | grep `update_post_meta` to SEO keys | `/orbit-code-quality` §6.8 | Code Reviewer §10.8 |
| Block-delimiter miscount | grep text-stats over raw `post_content` | `/orbit-code-quality` §6.9 | Code Reviewer §10.9 |
| Tab / REST slug mismatch | diff links vs router switch | `/orbit-code-quality` §6.10 | Code Reviewer §10.10 |
| Cache invalidation gap | diff set sites vs delete sites | `/orbit-code-quality` §6.11 | Code Reviewer §10.11 |
| Free/Pro shadow class | intersect class names across codebases | `/orbit-code-quality` §6.12 | Code Reviewer §10.12 |
| Cross-plugin filter timing | priority cross-check | `/orbit-code-quality` §6.13 | Code Reviewer §10.13 |
| Activation hook unloaded refs | grep callback for plugin namespace | `/orbit-code-quality` §6.14 | Code Reviewer §10.14 |
