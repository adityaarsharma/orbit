---
name: orbit-designer-empty-error
description: Audit empty-states + error-states across a WordPress plugin's admin UI — every list / table / dashboard / form should have a designed empty state with CTA, and every error path should have a recoverable error message (not a stack trace). Use when the user says "empty state audit", "error state design", "blank screen UX", or after a UX review.
---

# 🪐 orbit-designer-empty-error — Empty + error state audit

The two states designers forget. Empty = "nothing here yet" = first impression. Error = "something broke" = trust moment. Both ship as afterthoughts in 80% of plugins.

---

## Quick start

```bash
PLUGIN_SLUG=my-plugin npx playwright test --project=designer-states
```

The spec navigates to every admin page in a fresh-install state (no data) AND a forced-error state (broken DB, missing file, expired session) and screenshots both.

---

## What it checks

### 1. Empty-state coverage

For every list / table / dashboard:
- Is there content shown when no data exists?
- Does it explain *why* it's empty?
- Does it include a CTA to populate it?

**Whitepaper intent:** A blank table after fresh install = user thinks "broken." A designed empty state = user thinks "next step is clear."

```
✅ Good empty state
┌──────────────────────────────────────────┐
│  📋  No submissions yet                   │
│                                          │
│  When someone fills out your form,       │
│  their submissions will show up here.    │
│                                          │
│  [ Create your first form → ]            │
└──────────────────────────────────────────┘

❌ Bad empty state
┌──────────────────────────────────────────┐
│  No items found.                         │  ← nothing else
└──────────────────────────────────────────┘
```

### 2. Error-state coverage

For every error path:
- Replace stack traces with friendly message
- Include action ("Try again", "Contact support", "Go back")
- Log the technical detail to error_log, not the UI
- Avoid blame ("You did X wrong") in favour of partnership ("Let's try again")

```php
// ❌ Stack trace to user
catch ( Exception $e ) {
  echo $e->getMessage() . $e->getTraceAsString();
}

// ✅ Friendly + logged
catch ( Exception $e ) {
  error_log( 'My Plugin: ' . $e->getMessage() . ' ' . $e->getTraceAsString() );
  echo '<div class="notice notice-error"><p>' .
    esc_html__( "Something didn't go as expected. Please try again, or contact support if this keeps happening.", 'my-plugin' ) .
    '</p></div>';
}
```

### 3. Loading states between empty + filled
- Skeleton loaders or spinners while fetching
- Indeterminate progress for unknown durations
- Time-based fallback ("Still loading… retry in 30s")

### 4. Network error states
- Disconnected → show offline indicator
- API down → show "Service temporarily unavailable, try in 5 min"
- Timeout → distinguish from "no results"

### 5. Partial data states
- 404 entity (e.g. plugin's CPT post deleted but linked elsewhere)
- Permission denied (user lacks capability)
- Quota exceeded (free plan limit)

---

## Output

```markdown
# Empty + Error State Audit — my-plugin

## Empty states (12 admin pages scanned)
- ✓ 6 pages have designed empty states with CTAs
- ⚠ 4 pages show blank table only ("No items found.")
- ❌ 2 pages show JS error in console when empty

## Error states
- ✓ Settings save failure shows friendly message
- ❌ DB query failure dumps Exception::getTraceAsString() to UI (security + UX)
- ❌ REST endpoint timeout shows "Network Error" with no retry

## Loading states
- ⚠ 8 admin pages have no loading indicator — perceived as broken on slow connections

## Recommendations
1. Design 4 missing empty states with CTAs
2. Wrap all PHP exceptions in friendly notices
3. Add skeleton loaders to top 5 list pages
```

---

## Pair with

- `/orbit-designer-tokens` — visual consistency
- `/orbit-pm-ux-audit` — guidance score
- `/orbit-accessibility` — error-message a11y associations
- `/orbit-wp-security` — exception leak = info disclosure

---

## Sources & Evergreen References

### Canonical docs
- [Material Empty States](https://m3.material.io/components/empty-states/overview) — pattern reference
- [NN/g — Error Message Guidelines](https://www.nngroup.com/articles/error-message-guidelines/) — research
- [WP Admin Notices API](https://developer.wordpress.org/reference/hooks/admin_notices/) — official notice patterns

### Last reviewed
- 2026-04-29
