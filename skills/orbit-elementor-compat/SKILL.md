---
name: orbit-elementor-compat
description: Test Elementor addon compatibility across Elementor versions (3.18 / 3.20 / 3.22 / latest) — deprecated APIs, removed hooks, breaking class signature changes. Auto-spins multiple wp-env sites, each pinned to a different Elementor version, runs the plugin's spec against each. Use when the user says "Elementor compat", "across Elementor versions", "Elementor 3.20 issue", "before Elementor major release".
---

# 🪐 orbit-elementor-compat — Across-Elementor-versions matrix

Elementor ships breaking changes more often than WP core. An addon working on 3.18 can break on 3.22. This skill catches it before customers do.

---

## Quick start

```bash
PLUGIN_SLUG=my-plugin \
  bash ~/Claude/orbit/scripts/elementor-version-matrix.sh
```

Default versions: 3.18.x, 3.20.x, 3.22.x, latest. Configurable in `qa.config.json`.

---

## What it checks

### 1. Deprecated API usage
| Deprecated in | API | Replacement |
|---|---|---|
| 3.0 | `_register_controls()` (underscore prefix) | `register_controls()` |
| 3.5 | `widgets_registered` hook | `elementor/widgets/register` |
| 3.18 | `Element_Base::get_settings()` direct | `get_settings_for_display()` |
| 3.20 | `\Elementor\Plugin::$instance->frontend->get_builder_content()` | `\Elementor\Plugin::$instance->frontend->get_builder_content_for_display()` |
| 3.22 | `Stack` class direct access | use `Document` API |

### 2. Hook signature changes
**Whitepaper intent:** Elementor's `elementor/widgets/register` hook signature changed in 3.5 (from `widgets_registered` with no args). Plugins using the old shape silently fail to register.

### 3. CSS variables vs hardcoded values
Elementor 3.18+ uses CSS custom properties for theme colours / typography. Hardcoded `color: #333` doesn't respect theme styles set via the editor.

```css
/* ❌ */
.my-widget { color: #333; }

/* ✅ */
.my-widget { color: var(--e-global-color-text); }
```

### 4. Container vs Section/Column
Elementor 3.6 introduced Containers (Flexbox). Section/Column is now legacy. New addons should target Container; old addons should still support Section for back-compat.

### 5. Data Layer changes (Editor V4)
Elementor 4.x will rebuild the editor on Atomic. Addons should:
- Avoid hardcoded DOM selectors targeting Editor V3 markup
- Use the public Hooks API (`elementor/editor/init`, etc.) — those will be carried forward
- Keep widget logic decoupled from Editor V3 internals

---

## Output

```markdown
# Elementor Compat Matrix — my-plugin

## Test sites
- Elementor 3.18.x on port 8881 ✓ pass
- Elementor 3.20.x on port 8882 ✓ pass
- Elementor 3.22.x on port 8883 ❌ FAIL — widget-x renders blank
- Elementor latest  on port 8884 ⚠ console warnings (deprecated `_register_controls`)

## Deprecated API usage
- ❌ 12 widgets use `_register_controls` (underscore prefix) — deprecated since 3.1
- ⚠ 3 widgets read `Element_Base::get_settings()` direct — switch to `get_settings_for_display()`

## CSS variables
- ✓ 35 widgets use `var(--e-global-color-*)`
- ⚠ 12 widgets hardcode colors — won't match user's theme palette
```

---

## Pair with

- `/orbit-elementor-dev` — widget dev audit
- `/orbit-elementor-pro` — Pro extension specifics
- `/orbit-compat-matrix` — PHP × WP matrix
- `/orbit-conflict-matrix` — vs other plugins

---

## Sources & Evergreen References

### Canonical docs
- [Elementor Developers](https://developers.elementor.com/) — root
- [Changelog](https://wordpress.org/plugins/elementor/#developers) — every release breaking-change note
- [Editor V4 announcement](https://elementor.com/blog/editor-v4/) — what's coming, what's deprecated
- [Hooks Reference](https://developers.elementor.com/docs/hooks/) — public API

### Rule lineage
- Container layout — Elementor 3.6 (March 2022)
- CSS variables global — Elementor 3.0 (June 2020)
- `elementor/widgets/register` (modern hook) — Elementor 3.5
- Deprecation cycles — Elementor typically gives 2 minor versions notice; some breakages are silent (audit shows them)

### Last reviewed
- 2026-04-29 — re-review on every Elementor minor release (active deprecation cycle)
