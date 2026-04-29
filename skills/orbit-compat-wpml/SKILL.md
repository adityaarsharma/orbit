---
name: orbit-compat-wpml
description: WPML compatibility audit — translatable strings via icl_t / wpml_register_string, custom-post-type translation, taxonomy translation, language switcher hooks, current-language detection, sitemap-per-language, and the wpml-config.xml registration file. Use when the user says "WPML compat", "WPML translate strings", "translation plugin", or before customer asks "does this work with WPML?".
---

# 🪐 orbit-compat-wpml — WPML compatibility

WPML is the dominant paid translation plugin (~1M sites). Plugins that store/output translatable text need WPML hooks or strings stay in default-language only.

---

## What this skill checks

### 1. wpml-config.xml registration
**Whitepaper intent:** WPML reads `wpml-config.xml` from your plugin directory to know which custom fields, options, and CPTs to translate. Without it, WPML can't translate your plugin's content.

```xml
<!-- wpml-config.xml -->
<wpml-config>
  <custom-fields>
    <custom-field action="translate">my_plugin_subtitle</custom-field>
    <custom-field action="copy">my_plugin_color</custom-field>
  </custom-fields>
  <admin-texts>
    <key name="my_plugin_settings">
      <key name="welcome_text" />
    </key>
  </admin-texts>
  <custom-types>
    <custom-type translate="1">my_plugin_post</custom-type>
  </custom-types>
  <taxonomies>
    <taxonomy translate="1">my_plugin_taxonomy</taxonomy>
  </taxonomies>
</wpml-config>
```

### 2. Translatable strings via WPML String API
```php
// Register strings WPML should pick up
do_action( 'wpml_register_single_string', 'my-plugin', 'Settings Title', 'Settings' );

// Retrieve
$translated = apply_filters( 'wpml_translate_single_string', 'Settings', 'my-plugin', 'Settings Title' );
```

### 3. Get current language
```php
$lang = apply_filters( 'wpml_current_language', null );  // 'en', 'fr', etc.
```

### 4. Switch language programmatically
```php
do_action( 'wpml_switch_language', 'fr' );
// ... do stuff in French context ...
do_action( 'wpml_switch_language', null );  // restore
```

### 5. Get translated post
```php
$translated_id = apply_filters( 'wpml_object_id', $post_id, 'post', true, 'fr' );
```

### 6. URL handling
WPML supports 3 URL modes: directory (`/fr/`), subdomain (`fr.site.com`), parameter (`?lang=fr`). Your plugin's URL builders must respect:
```php
$url = apply_filters( 'wpml_permalink', $url, 'fr' );
```

### 7. Detect WPML active
```php
if ( function_exists( 'icl_object_id' ) || class_exists( 'SitePress' ) ) {
  // WPML is active
}
```

### 8. Sitemap per language
If you generate sitemaps, generate one per language. WPML provides hooks.

---

## Output

```markdown
# WPML Compat — my-plugin

❌ Missing wpml-config.xml — WPML can't find your custom fields / CPTs
   → Generate from wpml-config.xml template
✓ Strings registered via wpml_register_single_string
✓ Current-language detection via wpml_current_language filter
⚠ URL builder in includes/class-link.php:42 doesn't filter through wpml_permalink
✓ Detects SitePress before applying logic
```

---

## Pair with

- `/orbit-compat-polylang` — alt translation plugin (different API)
- `/orbit-i18n` — base i18n
- `/orbit-designer-rtl` — RTL languages need direction handling

---

## Sources & Evergreen References

### Canonical docs
- [WPML Documentation](https://wpml.org/documentation/) — root
- [Plugin Compatibility Guide](https://wpml.org/documentation/support/wpml-coding-api/) — coding API
- [wpml-config.xml Format](https://wpml.org/documentation/support/language-configuration-files/) — config schema
- [String Translation API](https://wpml.org/documentation/support/wpml-coding-api/wpml-hooks-reference/) — hooks reference

### Last reviewed
- 2026-04-29 — re-fetch hook reference quarterly (WPML adds APIs each major release)
