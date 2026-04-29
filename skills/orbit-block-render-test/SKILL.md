---
name: orbit-block-render-test
description: Coverage check + Playwright test scaffolder for server-side block render (render.php) — ensures every block.json with `render: "file:./render.php"` has a paired test that verifies frontend output, edge-case attributes (empty/null/special chars), and `get_block_wrapper_attributes()` correctness. Use when the user says "block render test", "test render.php", "verify dynamic blocks", or after any new server-rendered block.
---

# 🪐 orbit-block-render-test — Server-side render coverage

Every dynamic block should have a render test. This skill lists the gaps and scaffolds the missing specs.

---

## Quick start

```bash
PLUGIN_SLUG=my-plugin npx playwright test --project=block-render
```

Or scaffold tests for any uncovered block:
```bash
claude "/orbit-block-render-test Scaffold render tests for every block in ~/plugins/my-plugin that doesn't have one."
```

---

## What it checks

### 1. Coverage map
For every `block.json` with `"render": "file:./render.php"`, look for a paired test in `tests/playwright/blocks/<block-name>.spec.js`. If missing → flag.

### 2. Frontend output
```js
test('my-plugin/example renders title', async ({ page, admin, editor }) => {
  await admin.createNewPost();
  await editor.insertBlock({
    name: 'my-plugin/example',
    attributes: { title: 'Hello World' },
  });
  await editor.publishPost();
  await page.goto(editor.getCurrentPostUrl());
  await expect(page.locator('.my-block-example')).toContainText('Hello World');
});
```

### 3. Edge-case attributes
Every test should cover:
- Empty string (`""`)
- Null
- HTML chars (`<script>`, `&amp;`)
- Unicode (emoji, RTL chars)
- Maximum length (255+ chars)
- Numeric-when-string-expected

### 4. `get_block_wrapper_attributes()` usage

**Whitepaper intent:** Without `get_block_wrapper_attributes()`, supports flags (color, spacing, align) get ignored — users can't customise the block visually even though block.json declares the support.

```php
// ❌ Wrong — drops user styles
<div class="my-block">...</div>

// ✅ Right — respects block.json supports
<div <?php echo get_block_wrapper_attributes(); ?>>...</div>
```

### 5. Sanitization at render
```php
// ❌ Echoes attribute directly — XSS if attribute came from API/REST
echo $attributes['title'];

// ✅ Always escape on output
echo esc_html( $attributes['title'] ?? '' );
echo wp_kses_post( $attributes['richText'] ?? '' );
```

---

## Output

```markdown
# Block Render Test Coverage — my-plugin

## Coverage: 6/8 blocks (75%)

### Missing tests
- ❌ my-plugin/widget-3 — render.php exists, no test spec
- ❌ my-plugin/dynamic-list — render.php exists, no test spec

### Issues in existing renders
- ⚠ blocks/example/render.php:12 — uses `echo $attributes['html']` without `wp_kses_post`
- ⚠ blocks/widget/render.php:8 — missing `get_block_wrapper_attributes()`
```

---

## Pair with

- `/orbit-gutenberg-dev` — overall block dev audit
- `/orbit-block-edit-test` — JS edit-time tests
- `/orbit-block-json-validate` — block.json schema
- `/orbit-wp-security` — XSS in render functions

---

## Sources & Evergreen References

### Canonical docs
- [Server-Side Rendering](https://developer.wordpress.org/block-editor/reference-guides/block-api/block-metadata/#render) — render field reference
- [`get_block_wrapper_attributes()`](https://developer.wordpress.org/reference/functions/get_block_wrapper_attributes/) — official function reference
- [Block Editor Handbook — Dynamic Blocks](https://developer.wordpress.org/block-editor/how-to-guides/block-tutorial/creating-dynamic-blocks/) — tutorial
- [Playwright + WordPress](https://github.com/WordPress/gutenberg/tree/trunk/test/e2e) — Gutenberg's own E2E setup

### Rule lineage
- `get_block_wrapper_attributes()` — added WP 5.8
- `render` field in block.json — preferred since WP 5.9
- Inner block rendering — `<InnerBlocks.Content />` deprecated WP 6.0+ (use `do_blocks()`)

### Last reviewed
- 2026-04-29 — re-review on WP minor release or @wordpress/scripts major bump
