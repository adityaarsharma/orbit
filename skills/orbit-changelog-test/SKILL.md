---
name: orbit-changelog-test
description: Map every CHANGELOG.md entry to a targeted Playwright test or skill audit. Reads the changelog, classifies each entry (NEW FEATURE / PERFORMANCE / SECURITY / BUG FIX / etc.), and generates a per-change test plan you can execute before tagging the release. Use when the user says "test the changelog", "changelog → tests", "test the new features", "before release", or has just updated CHANGELOG.md for a new version.
---

# 🪐 orbit-changelog-test — Changelog-driven test plan

The release is only as good as the tests for what changed. This skill ensures every changelog entry has a corresponding test or audit.

---

## Quick start

```bash
bash ~/Claude/orbit/scripts/changelog-test.sh \
  --changelog ~/plugins/my-plugin/CHANGELOG.md
```

Output: `reports/changelog-tests-<timestamp>.md`.

---

## How it works

1. Read `CHANGELOG.md` (the one for the release you're about to tag)
2. For each `=== <version> ===` block, parse each line into:
   - **Category** (NEW FEATURE / FIX / PERFORMANCE / SECURITY / I18N / DEPRECATION / etc.)
   - **Subject** (what changed — usually the feature/file name)
3. Suggest a specific test or skill audit for that line
4. Output a checklist you can run as part of the release gate

---

## Example

CHANGELOG.md:
```
== 2.4.0 ==
- [NEW FEATURE] Added Mega Menu widget for Elementor
- [PERFORMANCE] Reduced DB queries on homepage by 30%
- [SECURITY] Added nonce verification to AJAX handler in admin/save.php
- [FIX] Fixed crash when saving empty settings
- [I18N] Updated French + German translations
- [DEPRECATION] Removed legacy `my_plugin_old_render()` filter
```

Output (excerpt):

```markdown
# Changelog Test Plan — my-plugin v2.4.0

## [NEW FEATURE] Mega Menu widget for Elementor
**Test:**
1. Open Elementor editor on a test page
2. Search for "Mega Menu" in the widgets panel — verify it appears
3. Drag onto canvas — verify it renders without errors
4. Configure 3 menu items with submenus — verify they display
5. Save + view frontend — verify hover/keyboard interaction

**Spec:** `tests/playwright/elementor-addon/mega-menu.spec.js`
(use `/orbit-playwright` to scaffold if missing)

**Skill audit:**
- `/orbit-wp-standards` on includes/widgets/mega-menu.php
- `/orbit-accessibility` on the rendered menu

---

## [PERFORMANCE] Reduced DB queries on homepage by 30%
**Test:**
1. Run `/orbit-db-profile` on the homepage
2. Compare query count to v2.3 baseline (saved in reports/db-profile-v2.3.txt)
3. Verify the reduction landed (≥30%)

**Skill audit:**
- `/orbit-wp-performance` on changed files
- `/orbit-wp-database` to confirm no N+1 introduced

---

## [SECURITY] Added nonce verification to AJAX handler
**Test:**
1. Run `/orbit-wp-security` on admin/save.php
2. Verify the nonce check pattern is correct (isset + wp_verify_nonce)
3. Manual: try POST without nonce — must return 403

**Skill audit:**
- `/orbit-wp-security` deep-dive on admin/save.php
- `/orbit-rest-fuzzer` if this exposes a REST endpoint

---

## [FIX] Crash when saving empty settings
**Test:**
1. Navigate to settings page
2. Clear all fields → click Save
3. Verify graceful validation message, NO crash

**Spec:** `tests/playwright/my-plugin/settings.spec.js` — add empty-save test case

---

## [I18N] French + German translations
**Test:**
1. `/orbit-i18n` audit — verify POT freshness
2. Switch wp-env to fr_FR — verify UI strings render translated
3. Switch to de_DE — same

**Manual:** Eyeball at least one screen in each locale.

---

## [DEPRECATION] Removed `my_plugin_old_render()`
**Test:**
1. Grep main.php / dependent files — any external code calling the old function?
2. If yes — keep a deprecation shim until next major
3. If no — confirm removal is safe + update upgrade notice in readme.txt
```

---

## Categories detected

| Tag in changelog | What it triggers |
|---|---|
| `[NEW FEATURE]`, `[ADDED]` | New Playwright spec needed + standards/security audit |
| `[PERFORMANCE]`, `[OPTIMISED]` | Re-run perf benchmarks + DB profile + bundle analysis |
| `[SECURITY]`, `[HARDENED]` | Mandatory `/orbit-wp-security` + manual exploit attempt |
| `[FIX]`, `[BUG]`, `[FIXED]` | Add a regression test for the specific bug |
| `[I18N]`, `[TRANSLATION]` | `/orbit-i18n` audit + locale verification |
| `[DEPRECATION]`, `[REMOVED]` | External-call check + upgrade notice review |
| `[BREAKING]` | Migration guide review + back-compat shim plan |
| `[ACCESSIBILITY]`, `[A11Y]` | `/orbit-accessibility` re-run on changed pages |

---

## Why this matters

Without changelog-driven testing, you ship features that "work on my machine" and miss:
- The regression in feature X because adding feature Y silently broke a hook
- The security fix that the patch *intended* to apply but didn't (because the `wp_verify_nonce` returns true for `null`)
- The translation that appeared but wasn't in the POT file
- The deprecated function that nobody noticed your theme partner relied on

This skill turns "we tested it" into "here's the evidence per changelog line."

---

## Pair with `/orbit-version-compare`

`/orbit-version-compare` shows what *actually* changed in code (PHPCS / asset / function diff).
`/orbit-changelog-test` shows what *the team said* changed.

Run both. If they disagree, the changelog is wrong (or someone shipped undocumented changes).

---

## Output

`reports/changelog-tests-<timestamp>.md` — one section per changelog entry, with the suggested test plan, spec file path, and skill audit list.

For PMs / release managers, this becomes the **release-evidence checklist**:

```
[ ] [NEW FEATURE] Mega Menu — spec passes ✓
[ ] [PERFORMANCE] DB queries — measured 32% reduction ✓
[ ] [SECURITY] Nonce check — verified + audit clean ✓
[ ] [FIX] Empty settings crash — regression test added ✓
[ ] [I18N] Translations — locale verified ✓
[ ] [DEPRECATION] Old render — no external callers found ✓

→ Approved for release
```

---

## CLI flags

```bash
bash scripts/changelog-test.sh \
  --changelog CHANGELOG.md \
  --version v2.4.0 \                # auto-detected if omitted
  --output reports/changelog-tests-$VERSION.md \
  --strict                          # fail with exit 1 if any entry has no clear test
```
