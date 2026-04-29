---
name: orbit-elementor-controls
description: Audit custom Elementor controls — Control_Base subclasses, custom UI controls beyond the 30+ built-in (slider, text, choose, dimensions, gallery, repeater, etc.), control registration hook, and choosing the right built-in control before rolling a custom one. Use when the user says "Elementor control", "custom control", "Control_Base", or "build a custom Elementor field type".
---

# 🪐 orbit-elementor-controls — Custom Elementor controls

Elementor ships ~30 built-in controls. Most plugins reach for "build a custom one" too quickly. This skill flags places where a built-in works AND audits actual custom controls.

---

## Quick start

```bash
claude "/orbit-elementor-controls Audit ~/plugins/my-plugin for Elementor control usage — built-in vs custom, registration patterns."
```

---

## What it checks

### 1. Built-in controls covered (use these first)

| Need | Built-in control |
|---|---|
| Single-line text | `Controls_Manager::TEXT` |
| Multi-line text | `Controls_Manager::TEXTAREA` |
| WYSIWYG | `Controls_Manager::WYSIWYG` |
| Number | `Controls_Manager::NUMBER` |
| Slider | `Controls_Manager::SLIDER` |
| Switcher (toggle) | `Controls_Manager::SWITCHER` |
| Color picker | `Controls_Manager::COLOR` |
| Background (image/gradient/video) | `Controls_Manager::BACKGROUND` (group) |
| Dimensions (4 sides) | `Controls_Manager::DIMENSIONS` |
| Choose (icon picker grid) | `Controls_Manager::CHOOSE` |
| Select (dropdown) | `Controls_Manager::SELECT` |
| Multi-select | `Controls_Manager::SELECT2` |
| Image upload | `Controls_Manager::MEDIA` |
| Image gallery | `Controls_Manager::GALLERY` |
| Repeater | `Controls_Manager::REPEATER` |
| Date/time picker | `Controls_Manager::DATE_TIME` |
| URL with options | `Controls_Manager::URL` |
| Icon (FA / SVG) | `Controls_Manager::ICONS` |
| Typography (group) | `Group_Control_Typography` |

### 2. Custom control registration
```php
add_action( 'elementor/controls/register', function( $controls_manager ) {
  $controls_manager->register( new \My_Plugin\Control_Color_Pair() );
} );
```

### 3. Control_Base subclass shape
```php
class Control_Color_Pair extends \Elementor\Base_Data_Control {
  public function get_type() { return 'color-pair'; }
  protected function get_default_settings() { return [...]; }
  public function content_template() { ?>...<?php }
  public function get_default_value() { return ['primary' => '', 'secondary' => '']; }
  public function enqueue() { /* register CSS+JS for the control UI */ }
}
```

### 4. Selectors pattern (live preview)
**Whitepaper intent:** Without `selectors`, control changes only show on save. With them, the editor preview updates live, drastically improving UX.

```php
$this->add_control( 'colour', [
  'type' => Controls_Manager::COLOR,
  'selectors' => [
    '{{WRAPPER}} .my-element' => 'color: {{VALUE}};',
  ],
] );
```

### 5. Conditional controls
```php
$this->add_control( 'show_subtitle', [ 'type' => Controls_Manager::SWITCHER ] );
$this->add_control( 'subtitle', [
  'type' => Controls_Manager::TEXT,
  'condition' => [ 'show_subtitle' => 'yes' ],
] );
```

---

## Output

```markdown
# Elementor Controls Audit — my-plugin

## Custom controls registered: 3
- color-pair (Control_Color_Pair) — ✓ valid Base_Data_Control subclass
- icon-svg-upload — ⚠ duplicates built-in MEDIA + ICONS combo
- spacing-grid — ✓ unique, no built-in equivalent

## Built-in controls usage
- ✓ 47 widgets use COLOR, BACKGROUND, DIMENSIONS, TYPOGRAPHY appropriately
- ⚠ widget-x uses TEXT for a date — should use DATE_TIME
- ⚠ widget-y uses 3 separate controls for "primary, secondary, tertiary colour" — group via group control

## Selectors coverage
- 38/47 widgets have `selectors` for live preview ✓
- ⚠ 9 widgets save-only (no live preview) — hurts UX
```

---

## Pair with

- `/orbit-elementor-dev` — widget dev
- `/orbit-elementor-skins` — skin variations
- `/orbit-pm-ux-audit` — guidance score (live preview helps)

---

## Sources & Evergreen References

### Canonical docs
- [Controls Reference](https://developers.elementor.com/docs/widgets/widget-controls/) — every built-in control
- [Custom Controls](https://developers.elementor.com/docs/controls/custom-controls/) — Control_Base subclassing
- [Group Controls](https://developers.elementor.com/docs/controls/group-controls/) — Typography, Background, etc.
- [Conditions Reference](https://developers.elementor.com/docs/widgets/widget-controls/#conditions) — show/hide

### Rule lineage
- `elementor/controls/register` hook — Elementor 3.5+ (replaces older patterns)
- Built-in control list — stable since Elementor 2.x; new ones added rarely
- `selectors` live preview — long-standing

### Last reviewed
- 2026-04-29 — re-review on Elementor minor releases
