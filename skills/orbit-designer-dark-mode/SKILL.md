---
name: orbit-designer-dark-mode
description: Audit dark-mode support — CSS uses `prefers-color-scheme` correctly, color tokens work in both modes, contrast ratios meet WCAG AA in both, no hardcoded `color: black` / `background: white`, images / logos have dark variants. Use when the user says "dark mode", "prefers-color-scheme", "admin dark", "dark theme support".
---

# 🪐 orbit-designer-dark-mode — Dark mode audit

Modern users expect dark mode. WP admin doesn't ship dark mode out of the box, but admin colour schemes (Profile → Color Scheme) include "Midnight" / "Coffee" — your plugin must respect them.

---

## Quick start

```bash
PLUGIN_SLUG=my-plugin npx playwright test --project=admin-colors
```

Cycles through all 9 WP admin colour schemes (default, light, modern, blue, coffee, ectoplasm, midnight, ocean, sunrise) and screenshots every plugin page.

---

## What it checks

### 1. WP admin colour scheme awareness

**Whitepaper intent:** Hardcoded colours look fine on default scheme but invisible / illegible on Midnight or Coffee. Use `var(--wp-admin-theme-color)` — auto-adapts.

```css
/* ❌ Invisible on Midnight scheme (white-on-black) */
.my-plugin-button { background: white; color: black; }

/* ✅ Adapts to user's admin colour scheme */
.my-plugin-button {
  background: var(--wp-admin-theme-color);
  color: #fff;
}
```

### 2. `prefers-color-scheme` media query for OS-level dark mode (frontend)
```css
.my-frontend-widget {
  background: #fff;
  color: #1d2327;
}

@media (prefers-color-scheme: dark) {
  .my-frontend-widget {
    background: #1d2327;
    color: #fff;
  }
}
```

### 3. Color tokens swap, not hardcoded variants
```css
/* ❌ Repeats every selector */
.btn { background: #fff; }
@media (prefers-color-scheme: dark) {
  .btn { background: #1d2327; }
}

/* ✅ Token swap once at the root */
:root {
  --bg: #fff;
  --fg: #1d2327;
}
@media (prefers-color-scheme: dark) {
  :root { --bg: #1d2327; --fg: #fff; }
}
.btn { background: var(--bg); color: var(--fg); }
```

### 4. Contrast in both modes
WCAG 2.2 AA = 4.5:1 normal text, 3:1 large text. Check both light + dark themes hit those — not just one.

### 5. Image assets have dark variants
```html
<picture>
  <source srcset="/logo-dark.svg" media="(prefers-color-scheme: dark)">
  <img src="/logo.svg" alt="My Plugin">
</picture>
```

Or for inline SVG, use `currentColor`:
```html
<svg fill="currentColor">...</svg>
<!-- Then set color via CSS, which adapts to the theme -->
```

### 6. Borders + shadows in dark mode
Shadows that look subtle on light bg often vanish on dark bg. Use lighter shadow values for dark mode:
```css
:root { --shadow: 0 1px 3px rgba(0,0,0,0.1); }
@media (prefers-color-scheme: dark) {
  :root { --shadow: 0 1px 3px rgba(0,0,0,0.6); }
}
```

### 7. Media queries respect user override
WP admin schemes override OS preference. Don't fight them — `var(--wp-admin-*)` already does the right thing in admin. Use `prefers-color-scheme` only for frontend output.

---

## Output

```markdown
# Dark Mode Audit — my-plugin

## Admin colour-scheme matrix (all 9 WP schemes)
- ✓ default, light, modern — readable
- ❌ Midnight: primary button invisible (white-on-dark, no border)
- ❌ Coffee: text contrast 2.1:1 (fails WCAG AA)
- ⚠ Ocean: chart colours don't pop

## Frontend dark mode (prefers-color-scheme)
- ⚠ Plugin frontend output has no dark mode support
- 24 colour values hardcoded — recommend token swap pattern

## Contrast (WCAG 2.2 AA)
- 47 colour pairs checked
- ✓ 38 pass in both modes
- ❌ 9 fail in dark mode
```

---

## Pair with

- `/orbit-designer-tokens` — set up the token system first
- `/orbit-accessibility` — contrast = WCAG
- `/orbit-visual-regression` — pixel-diff per scheme

---

## Sources & Evergreen References

### Canonical docs
- [WP Admin CSS Variables](https://make.wordpress.org/core/2022/01/06/dashicons-released-in-version-5-9/) — `--wp-admin-theme-color`
- [MDN — prefers-color-scheme](https://developer.mozilla.org/en-US/docs/Web/CSS/@media/prefers-color-scheme) — query reference
- [WCAG 2.2 — Contrast](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html) — official spec
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/) — test tool

### Rule lineage
- WP admin CSS variables — WP 5.7
- prefers-color-scheme — broad browser support since 2019

### Last reviewed
- 2026-04-29
