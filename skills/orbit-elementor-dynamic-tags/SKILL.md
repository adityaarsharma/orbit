---
name: orbit-elementor-dynamic-tags
description: Audit Elementor Dynamic Tags — server-side data sources that fill widget controls (post meta, ACF fields, user data, custom). The Elementor equivalent of WP's Block Bindings API. Use when the user says "dynamic tag", "Tag class", "ACF dynamic tag", "Elementor dynamic data", or a plugin needs to pipe live data into Elementor controls.
---

# 🪐 orbit-elementor-dynamic-tags — Dynamic Tags audit

Dynamic Tags let users pick "this control's value comes from post meta" instead of typing a literal value. Crucial for theme-builder content; underused by most plugin teams.

---

## Quick start

```bash
claude "/orbit-elementor-dynamic-tags Audit ~/plugins/my-plugin for Dynamic Tag opportunities + existing patterns."
```

---

## What it checks

### 1. Tag class structure
```php
class Tag_Post_Price extends \Elementor\Core\DynamicTags\Tag {

  public function get_name()       { return 'post-price'; }
  public function get_title()      { return __( 'Post Price', 'my-plugin' ); }
  public function get_group()      { return 'post'; }
  public function get_categories() { return [ \Elementor\Modules\DynamicTags\Module::TEXT_CATEGORY ]; }

  protected function register_controls() {
    $this->add_control( 'fallback', [
      'label' => __( 'Fallback', 'my-plugin' ),
      'type' => Controls_Manager::TEXT,
    ] );
  }

  public function render() {
    $price = get_post_meta( get_the_ID(), '_price', true );
    echo $price ? esc_html( '$' . $price ) : esc_html( $this->get_settings( 'fallback' ) );
  }
}
```

### 2. Tag registration
```php
add_action( 'elementor/dynamic_tags/register', function( $dynamic_tags_manager ) {
  $dynamic_tags_manager->register( new Tag_Post_Price() );
} );
```

### 3. Tag categories — match the control type
```php
public function get_categories() {
  return [
    \Elementor\Modules\DynamicTags\Module::TEXT_CATEGORY,        // for text controls
    \Elementor\Modules\DynamicTags\Module::URL_CATEGORY,         // for URL controls
    \Elementor\Modules\DynamicTags\Module::IMAGE_CATEGORY,       // for image controls
    \Elementor\Modules\DynamicTags\Module::COLOR_CATEGORY,       // for color
    \Elementor\Modules\DynamicTags\Module::NUMBER_CATEGORY,      // numeric
    \Elementor\Modules\DynamicTags\Module::POST_META_CATEGORY,
    \Elementor\Modules\DynamicTags\Module::GALLERY_CATEGORY,
  ];
}
```

A tag with `TEXT_CATEGORY` shows up in the dynamic picker for any control that accepts text.

### 4. Tag groups (UX organisation)
```php
add_action( 'elementor/dynamic_tags/register', function( $manager ) {
  $manager->register_group( 'my-plugin', [
    'title' => __( 'My Plugin', 'my-plugin' ),
  ] );
} );
```

### 5. Sanitization in render()
**Whitepaper intent:** Dynamic tags pull user-controlled data (post meta) into Elementor controls. If you don't escape, you've created an authenticated XSS vector.

```php
public function render() {
  echo esc_html( get_post_meta( get_the_ID(), 'my_field', true ) );
}
```

### 6. Pro requirement
Dynamic Tags is a Pro feature. Add the guard:
```php
if ( ! defined( 'ELEMENTOR_PRO_VERSION' ) ) return;
```

---

## Output

```markdown
# Elementor Dynamic Tags — my-plugin

## Tags registered: 3
- post-price (text) ✓
- featured-image (image) ✓
- author-twitter (URL) ⚠ missing fallback control

## Recommendations
- Consider adding a `meta-text` tag for any custom-field display the plugin enables
- 5 widgets currently hardcode meta access via filters — could be Dynamic Tags
```

---

## Pair with

- `/orbit-elementor-dev` — widget dev
- `/orbit-elementor-pro` — Pro extensions
- `/orbit-block-bindings` — Gutenberg's equivalent

---

## Sources & Evergreen References

### Canonical docs
- [Dynamic Tags](https://developers.elementor.com/docs/dynamic-tags/) — Tag_Base reference
- [Categories Module](https://developers.elementor.com/docs/dynamic-tags/categories/) — control-type matching

### Rule lineage
- Dynamic Tags — Elementor Pro 2.0
- Group registration — Pro 2.5

### Last reviewed
- 2026-04-29 — re-review on Pro minor releases
