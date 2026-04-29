---
name: orbit-block-json-validate
description: Validate every `block.json` in a WordPress plugin against the current Block Metadata schema (apiVersion, name format, attributes types, supports, render, viewScript, etc.). WP 6.5+ expects apiVersion 3. Catches schema errors before they become runtime issues. Use when the user says "block.json validate", "validate Gutenberg blocks", "WP 6.5 block schema", or after adding/editing any block.
---

# 🪐 orbit-block-json-validate — block.json schema validator

WP 6.5 made `apiVersion: 3` the standard. WP 6.4 and earlier supported apiVersion 2. Older plugins ship apiVersion 1 — which now warns. This skill catches every schema issue.

---

## Quick start

```bash
bash ~/Claude/orbit/scripts/check-block-json.sh ~/plugins/my-plugin
```

Output: `reports/block-json-<timestamp>.md`.

---

## What it checks

### 1. Required fields
```json
{
  "$schema": "https://schemas.wp.org/trunk/block.json",
  "apiVersion": 3,                    // 3 (WP 6.5+) or 2 (back-compat)
  "name": "my-plugin/example",        // namespace/name format
  "version": "1.0.0",
  "title": "Example Block",
  "description": "What it does.",
  "category": "widgets",
  "icon": "smiley",
  "keywords": ["example"],
  "textdomain": "my-plugin",
  "attributes": { ... },
  "supports": { ... },
  "render": "file:./render.php",      // server-side render (WP 6.1+)
  "editorScript": "file:./build/index.js",
  "editorStyle": "file:./build/index.css",
  "style": "file:./build/style-index.css",
  "viewScriptModule": "file:./build/view.js",   // ES module (WP 6.5+)
  "viewScript": "file:./build/view.js"          // legacy (use module above)
}
```

### 2. Name format
Must be `namespace/blockname` — lowercase, dashes only, no underscores or camelCase.
- ✅ `my-plugin/example-block`
- ❌ `my_plugin/example` (underscore)
- ❌ `MyPlugin/Example` (camelCase)

### 3. apiVersion
- 1: Deprecated. WP shows a warning. Migrate to 3.
- 2: Still supported but legacy. Use 3 for new blocks.
- 3: Current standard (WP 6.5+). Required for `viewScriptModule`.

### 4. Attribute types
```json
"attributes": {
  "title": {
    "type": "string",
    "default": ""
  },
  "count": {
    "type": "integer",
    "default": 0
  },
  "items": {
    "type": "array",
    "default": []
  },
  "config": {
    "type": "object",
    "default": {}
  }
}
```

Each attribute MUST have `type`. Default value (if set) MUST match the type. Common bug: `"default": null` on a `string` field — WP throws a console error.

### 5. Supports flags
```json
"supports": {
  "html": false,                // disable raw HTML editing — usually right
  "align": ["wide", "full"],    // alignment options
  "anchor": true,               // adds id="..." support
  "color": {
    "background": true,
    "text": true,
    "gradients": true
  },
  "spacing": {
    "padding": true,
    "margin": true,
    "blockGap": true
  },
  "typography": {
    "fontSize": true,
    "lineHeight": true
  },
  "layout": true,
  "shadow": true,                // WP 6.5+
  "interactivity": true          // WP 6.5+ (Interactivity API)
}
```

The validator checks that `supports.X` is the right shape (some are bool, some objects).

### 6. File references
```json
"render":        "file:./render.php",
"editorScript":  "file:./build/index.js",
"editorStyle":   "file:./build/index.css"
```

Each `file:` reference is resolved against the block.json directory. Validator confirms each file exists.

### 7. textdomain
Must match the plugin's text domain (same value as plugin header `Text Domain:`).

### 8. Category
Must be one of: `text`, `media`, `design`, `widgets`, `theme`, `embed`, or a custom registered category.

---

## Common findings

```
[block.json] my-plugin

✓ blocks/example/block.json — schema valid
❌ blocks/legacy/block.json — apiVersion: 1 (deprecated)
   Migrate to apiVersion 3:
   - Move `attributes.X.source: "html"` config to render.php
   - Replace `save` function with server-side render
   - Update edit.js to use BlockEdit hook

❌ blocks/badname/block.json — name "MyPlugin/Bad" invalid
   Must be lowercase namespace/name. Rename to "my-plugin/bad".

⚠ blocks/example/block.json — supports.color is `true` but should be object {background, text}

⚠ blocks/example/block.json — `render: "file:./render.php"` doesn't exist on disk

⚠ blocks/example/block.json — attribute `count` has default `null` but type is `integer`

✓ All 4 blocks declared text domain "my-plugin" matching plugin header
```

---

## When this matters

- **Adding a new block** — validate first, register second
- **Bumping apiVersion** — full audit + test in editor
- **WP core release** — schema may add new fields (interactivity, viewScriptModule)
- **WP.org submission** — plugin-check tool runs the same validation

---

## Migrate apiVersion 1 → 3

The big change: server-side render via `render` field replaces JS `save` callbacks.

```json
// Before (apiVersion 1)
{
  "apiVersion": 1,
  "name": "my/block"
}
```

```js
// edit.js (used to also have save())
registerBlockType( 'my/block', {
  edit: () => <div>...</div>,
  save: () => <div>final</div>,
} );
```

```json
// After (apiVersion 3)
{
  "apiVersion": 3,
  "render": "file:./render.php"
}
```

```js
// edit.js — only edit, no save
registerBlockType( 'my/block', {
  edit: () => <div>edit-time UI</div>,
  // no save — handled by render.php
} );
```

```php
// render.php — server-side
<div <?php echo get_block_wrapper_attributes(); ?>>
  <?php echo esc_html( $attributes['title'] ?? '' ); ?>
</div>
```

Benefits: faster editor, smaller JS bundle, dynamic data fresh on every render.

---

## Pair with `/orbit-i18n`

block.json titles + descriptions are auto-translated if `textdomain` is set. After updating block.json strings, re-generate JSON translations:

```bash
wp i18n make-json languages/
```

---

## CI

```yaml
- run: bash ~/Claude/orbit/scripts/check-block-json.sh .
```

Exits 1 on any schema error. Wire into release workflow.
