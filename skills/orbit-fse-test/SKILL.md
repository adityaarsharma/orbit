---
name: orbit-fse-test
description: Full-Site-Editing (FSE) compatibility audit for a WordPress plugin or theme — theme.json schema 3 validation, block-template-parts hooks, Site Editor compatibility, template hierarchy, style variations, and block-locking patterns. Use when the user says "FSE", "block theme", "theme.json", "site editor", or builds anything that adds templates / parts / patterns to a block theme.
---

# 🪐 orbit-fse-test — Full-Site-Editing compat

WordPress 6.0+ ships block themes with the Site Editor. Plugins (and especially themes) must be FSE-aware or they break the editing experience.

---

## Quick start

```bash
claude "/orbit-fse-test Audit ~/plugins/my-plugin for FSE compatibility."
```

---

## What it checks

### 1. theme.json present + schema 3
```json
{
  "$schema": "https://schemas.wp.org/trunk/theme.json",
  "version": 3,
  "settings": { ... },
  "styles": { ... },
  "templateParts": [ ... ],
  "customTemplates": [ ... ]
}
```

**Whitepaper intent:** `version: 3` (WP 6.6+) supports per-block typography fluid clamps + improved style engine. Older versions (1, 2) still parse but lock you out of new APIs.

### 2. Templates directory structure
```
my-theme/
├── theme.json
├── style.css
├── templates/
│   ├── index.html
│   ├── single.html
│   ├── archive.html
│   └── 404.html
└── parts/
    ├── header.html
    ├── footer.html
    └── sidebar.html
```

Plugins extending FSE → use `register_block_pattern()` (not raw template files).

### 3. Style variations
```
styles/
├── pink.json       ← variation
├── monochrome.json
└── ...
```

Each style variation overrides theme.json values. Auditor checks variations stay valid against schema.

### 4. Block locking
**Whitepaper intent:** Site Editor lets users break things. `templateLock: "all"` and `lock: { remove: true, move: true }` keep critical layout intact.

```html
<!-- wp:group {"templateLock":"all"} -->
<!-- wp:site-title /-->
<!-- /wp:group -->
```

### 5. Hook compatibility (plugins extending FSE)
```php
// Add a custom template part location
add_filter( 'default_template_types', function( $types ) {
  $types['my-custom'] = [
    'title' => __( 'My Template', 'my-plugin' ),
    'description' => __( '', 'my-plugin' ),
  ];
  return $types;
} );
```

### 6. Customizer fallback (back-compat)
If your plugin claims `Tested up to: 6.5` AND supports classic themes, it must register Customizer settings as fallback. FSE-only is fine if `Requires at least: 6.0` and you don't promise classic-theme support.

---

## Output

```markdown
# FSE Audit — my-plugin

## theme.json
- ✓ Schema version 3
- ✓ Validates against $schema URL
- ⚠ Custom colour palette uses absolute pixel values (use rem/em)

## Templates
- ✓ index.html, single.html, archive.html, 404.html present
- ⚠ Missing: search.html, page.html

## Style variations
- ✓ 3 variations (pink, monochrome, classic)
- ⚠ pink.json: invalid colour reference `--wp--preset--colour--mauve` (typo)

## Block locking
- ⚠ Header part has no template lock — Site Editor users can drag site title out
```

---

## Pair with

- `/orbit-gutenberg-dev` — block dev
- `/orbit-block-patterns` — pattern audit
- `/orbit-block-bindings` — Block Bindings API
- `/orbit-i18n` — translatable theme.json values

---

## Sources & Evergreen References

### Canonical docs
- [Theme Handbook — Block Themes](https://developer.wordpress.org/themes/block-themes/) — root of FSE docs
- [theme.json Reference](https://developer.wordpress.org/themes/global-settings-and-styles/) — settings + styles schema
- [theme.json Schema](https://schemas.wp.org/trunk/theme.json) — JSON Schema, validate against URL
- [Style Variations](https://developer.wordpress.org/themes/global-settings-and-styles/style-variations/) — `/styles/*.json`
- [Block Locking](https://developer.wordpress.org/news/2022/12/locking-blocks/) — make.wordpress.org

### Rule lineage
- theme.json v1 — WP 5.8
- theme.json v2 — WP 5.9
- theme.json v3 — WP 6.6 (fluid typography, style.css.variables)
- Site Editor — WP 5.9 (initial), 6.0 (general availability)
- Block Locking — WP 6.0
- Style Variations — WP 6.0

### Last reviewed
- 2026-04-29 — re-review on every WP minor (FSE API still evolves rapidly)
