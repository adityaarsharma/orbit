---
name: orbit-designer-rtl
description: RTL (right-to-left) layout audit for a WordPress plugin's admin UI and frontend output — verifies hardcoded `margin-left` / `padding-right` / `text-align: left` are replaced with logical properties (`margin-inline-start`, `text-align: start`), `rtl.css` shipped if needed, JS layout doesn't assume LTR. Use when the user says "RTL", "Arabic / Hebrew layout", "is_rtl", "logical properties".
---

# 🪐 orbit-designer-rtl — RTL layout audit

20% of the world reads right-to-left (Arabic, Hebrew, Persian, Urdu). WP supports RTL out of the box, but plugin CSS that hardcodes left/right values breaks the layout for those users.

---

## Quick start

```bash
claude "/orbit-designer-rtl Audit ~/plugins/my-plugin for RTL layout issues."
```

Plus a live test:
```bash
# Switch wp-env site to RTL locale
wp-env run cli wp site switch-language he_IL
PLUGIN_SLUG=my-plugin npx playwright test --project=rtl
```

---

## What it checks

### 1. Logical properties vs hardcoded directional values

**Whitepaper intent:** `margin-left: 8px` is wrong for RTL — the same property in RTL means visually-left, but the design intent was "inline-start" which is the opposite side. Logical properties auto-flip.

```css
/* ❌ Hardcoded — won't flip in RTL */
.my-button { margin-left: 8px; padding-right: 12px; text-align: left; }

/* ✅ Logical — auto-flips in RTL */
.my-button { margin-inline-start: 8px; padding-inline-end: 12px; text-align: start; }
```

### 2. Float / clear / absolute positioning
```css
/* ❌ */
.icon { float: left; }
.tooltip { position: absolute; left: 0; }

/* ✅ */
.icon { float: inline-start; }
.tooltip { position: absolute; inset-inline-start: 0; }
```

### 3. RTL-specific stylesheet (rtl.css) if logical properties not used
```php
wp_enqueue_style( 'my-plugin', plugins_url( 'assets/css/admin.css', __FILE__ ) );
wp_style_add_data( 'my-plugin', 'rtl', 'replace' );
// Now WP loads admin-rtl.css instead of admin.css when is_rtl()
```

Generate `admin-rtl.css` automatically:
```bash
npx rtlcss admin.css admin-rtl.css
```

### 4. is_rtl() awareness in PHP
```php
$class = is_rtl() ? 'right-side' : 'left-side';
echo '<div class="my-' . esc_attr( $class ) . '">';
```

### 5. JS directional assumptions
```js
// ❌ Assumes LTR
element.style.left = '0';

// ✅ Use ltr/rtl-aware
element.style.insetInlineStart = '0';
// or
element.style[document.dir === 'rtl' ? 'right' : 'left'] = '0';
```

### 6. Iconography that has direction (arrows, chevrons)
```css
/* ❌ Arrow points always-left */
.next-icon { transform: rotate(0); }

/* ✅ Arrow flips for RTL */
[dir=rtl] .next-icon { transform: scaleX(-1); }
```

### 7. text-align — use logical
```css
/* ❌ */
.title { text-align: left; }
.title-right { text-align: right; }

/* ✅ */
.title { text-align: start; }
.title-right { text-align: end; }
```

---

## Output

```markdown
# RTL Audit — my-plugin

## Static CSS analysis
- ❌ 47 uses of `margin-left` / `margin-right` (use `margin-inline-*`)
- ❌ 23 uses of `padding-left` / `padding-right`
- ❌ 18 uses of `text-align: left/right` (use `start/end`)
- ❌ 12 uses of `float: left/right`

## Live RTL test (Hebrew locale)
- ⚠ Settings page: form labels misaligned (text-align stuck at left)
- ❌ Modal: close button on wrong side (CSS `right: 0` should be `inset-inline-end: 0`)
- ⚠ Tooltips: arrow points wrong way

## RTL stylesheet
- ⚠ No `admin-rtl.css` shipped + no `wp_style_add_data` call
- Recommendation: either migrate to logical properties OR generate rtl.css with rtlcss

## Estimate
- Migration to logical properties: ~4 hours
- Or: ship rtl.css via `npx rtlcss` build step: ~30 min
```

---

## Pair with

- `/orbit-designer-tokens` — overall visual system
- `/orbit-i18n` — RTL is the visual half of i18n (translation = textual half)
- `/orbit-visual-regression` — RTL screenshots

---

## Sources & Evergreen References

### Canonical docs
- [MDN — Logical Properties](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_Logical_Properties_and_Values) — full reference
- [W3C — CSS Logical Properties Spec](https://www.w3.org/TR/css-logical-1/) — official
- [WP RTL Guide](https://make.wordpress.org/themes/handbook/review/required/#rtl) — theme handbook
- [`wp_style_add_data` — rtl](https://developer.wordpress.org/reference/functions/wp_style_add_data/) — replace stylesheet
- [rtlcss tool](https://rtlcss.com/) — auto-generate rtl.css

### Rule lineage
- Logical properties — broad browser support since 2020 (Safari 14.1, Chrome 87)
- Mainstream RTL adoption — long-standing in WP core since 2.x

### Last reviewed
- 2026-04-29
