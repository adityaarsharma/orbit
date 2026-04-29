---
name: orbit-block-edit-test
description: Playwright tests for the editor-time experience of every Gutenberg block — insert, configure attributes via inspector controls, set alignment / colour / spacing, transform to/from other blocks, validate inner-block patterns, undo/redo. Use when the user says "block edit test", "test InspectorControls", "block toolbar test", "edit-time spec", or after adding any custom InspectorControls to a block.
---

# 🪐 orbit-block-edit-test — Editor-time UX coverage

Render tests cover frontend output. This skill covers the editor experience — the part users feel before publishing.

---

## Quick start

```bash
PLUGIN_SLUG=my-plugin npx playwright test --project=block-edit
```

---

## What it checks

### 1. Block insertion + ready state
```js
test('Insert via inserter', async ({ admin, editor, page }) => {
  await admin.createNewPost();
  await editor.insertBlock({ name: 'my-plugin/example' });
  await expect(page.locator('[data-type="my-plugin/example"]')).toBeVisible();
  await expect(page.locator('.my-block-edit')).toContainText(/.+/);
});
```

### 2. InspectorControls present + functional

**Whitepaper intent:** Every attribute declared in block.json should be editable somewhere — inspector panel, block toolbar, or block content. Attributes with no editor surface are dead code.

```js
test('Title is editable via inspector', async ({ editor, page }) => {
  await editor.insertBlock({ name: 'my-plugin/example' });
  await page.getByRole('textbox', { name: 'Title' }).fill('Hello');
  await expect(page.locator('[data-block]')).toContainText('Hello');
});
```

### 3. Block toolbar (alignment, formatting, transform)
```js
await page.getByRole('button', { name: 'Align' }).click();
await page.getByRole('menuitem', { name: 'Wide width' }).click();
await expect(page.locator('[data-align="wide"]')).toBeVisible();
```

### 4. Transforms work both directions
```js
// my-plugin/example → core/paragraph
await editor.transformBlockTo('core/paragraph');
await expect(page.locator('p[data-block]')).toBeVisible();
```

### 5. Undo/redo preserves state
Always test undo after a state change — many block bugs only surface on undo.

### 6. Inner blocks render the right `allowedBlocks`
```js
await editor.insertBlock({
  name: 'my-plugin/container',
  innerBlocks: [{ name: 'core/paragraph' }],
});
// Try inserting a disallowed block — must reject
```

---

## Output

```markdown
# Block Edit Test Coverage — my-plugin

✓ 6/8 blocks have edit-time specs
❌ 2 blocks missing — see scaffold-out/block-edit-tests.md

✓ All InspectorControls render
⚠ my-plugin/widget-2 — `subtitle` attribute declared in block.json but no inspector control
```

---

## Pair with

- `/orbit-block-render-test` — frontend output
- `/orbit-gutenberg-dev` — overall block audit
- `/orbit-visual-regression` — pixel-diff editor screenshots

---

## Sources & Evergreen References

### Canonical docs
- [Block Editor — Test Utilities](https://developer.wordpress.org/block-editor/reference-guides/data/data-core-block-editor/) — REST + JS
- [@wordpress/e2e-test-utils-playwright](https://github.com/WordPress/gutenberg/tree/trunk/packages/e2e-test-utils-playwright) — official test utils
- [InspectorControls](https://developer.wordpress.org/block-editor/reference-guides/components/inspector-controls/) — inspector panel API
- [BlockToolbar](https://developer.wordpress.org/block-editor/reference-guides/components/block-toolbar/) — toolbar API
- [Block Transforms](https://developer.wordpress.org/block-editor/reference-guides/block-api/block-transforms/) — transform spec

### Rule lineage
- @wordpress/e2e-test-utils-playwright — replaces older puppeteer-based utils, official since WP 6.4
- Block transforms — pattern stable since WP 5.8

### Last reviewed
- 2026-04-29 — re-review on @wordpress/scripts major release
