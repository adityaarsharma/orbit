---
name: orbit-compat-polylang
description: Polylang compatibility audit — pll_register_string, pll_current_language, custom-post-type translation, language switcher hooks, REST + WP-CLI integration. Polylang has free + Pro versions; covers both. Use when the user says "Polylang compat", "Polylang translate", "WPML alternative", or coexisting with Polylang.
---

# 🪐 orbit-compat-polylang — Polylang compatibility

Polylang is the open-source WPML alternative (~700K sites). Different API than WPML — both must be supported separately, since users pick one based on price/preference.

---

## What this skill checks

### 1. Register translatable strings
```php
// Register on init
add_action( 'init', function() {
  if ( function_exists( 'pll_register_string' ) ) {
    pll_register_string( 'welcome_text', 'Welcome to my plugin', 'My Plugin', false );
  }
} );

// Retrieve
$translated = function_exists( 'pll__' )
  ? pll__( 'Welcome to my plugin' )
  : 'Welcome to my plugin';
```

### 2. Current language
```php
$lang = function_exists( 'pll_current_language' ) ? pll_current_language() : 'en';
```

### 3. Translate post ID
```php
$translated_id = function_exists( 'pll_get_post' )
  ? pll_get_post( $post_id, 'fr' )
  : $post_id;
```

### 4. Custom post type registration
**Whitepaper intent:** Polylang reads CPT settings — your plugin should register CPTs with `'show_in_rest' => true` AND let Polylang's settings UI mark them translatable.

```php
register_post_type( 'my_plugin_post', [
  'public' => true,
  'show_in_rest' => true,
  // Polylang admin → Languages → Settings → Custom post types and Taxonomies
  // user enables "translate" for this CPT
] );
```

### 5. Detect active
```php
if ( function_exists( 'pll_register_string' ) || class_exists( 'Polylang' ) ) {
  // Polylang is active
}
```

### 6. URL handling (3 URL modes like WPML)
```php
// Get URL for a specific language
$url_fr = function_exists( 'pll_home_url' ) ? pll_home_url( 'fr' ) : home_url();
```

### 7. Pro features (paid)
Polylang Pro adds:
- Strings translation export/import
- Slug translation
- Duplicate post in another language

If your plugin generates URLs from slugs, it must handle Pro's slug translation.

---

## Output

```markdown
# Polylang Compat — my-plugin

✓ Detects Polylang via class_exists check
✓ pll_register_string called for admin notices
⚠ Hard-coded strings in includes/templates/welcome.php — not registered
✓ pll_current_language used for current-language detection
❌ URL builder doesn't use pll_home_url — generates EN URLs in FR context
```

---

## Pair with

- `/orbit-compat-wpml` — alt translation plugin (different API)
- `/orbit-i18n` — base i18n

---

## Sources & Evergreen References

### Canonical docs
- [Polylang Documentation](https://polylang.pro/doc/) — root
- [Polylang for Developers](https://polylang.pro/doc/developpers-how-to/) — API reference
- [Functions Reference](https://polylang.pro/doc/category/developers/) — pll_* functions

### Last reviewed
- 2026-04-29
