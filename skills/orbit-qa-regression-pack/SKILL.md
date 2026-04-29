---
name: orbit-qa-regression-pack
description: Manage a regression test pack — group every test that exists to prevent a previously-fixed bug from re-occurring. Tag tests with the issue/PR they came from, run only regression-pack tests for fast pre-merge verification, ensure every fixed bug has a regression test. Use when the user says "regression pack", "regression suite", "every bug needs a test", "fast pre-merge tests".
---

# 🪐 orbit-qa-regression-pack — Regression test pack management

The regression pack is the most valuable test category — every test there exists because a real bug actually happened. Lose them and bugs come back.

---

## Quick start

```bash
# Run only regression-tagged tests
npx playwright test --grep '@regression'
```

Output: per-issue pass/fail.

---

## How to tag

### In test file:
```js
test('@regression #142 — Settings page does not 500 on missing API key', async ({ page }) => {
  await page.goto('/wp-admin/admin.php?page=my-plugin');
  // Verify settings page renders gracefully when api_key option is empty
  await expect(page.locator('h1')).toBeVisible();
});
```

The `@regression #142` tag means:
- This is a regression test
- It guards against the bug fixed in issue / PR #142

### In file header (alternative):
```js
/**
 * @regression
 * @issues 142, 198, 251
 */
test.describe('Settings — regression suite', () => { ... });
```

---

## What the skill does

### 1. Coverage check — every fixed bug has a test
```bash
# Run on every PR
bash ~/Claude/orbit/scripts/regression-coverage.sh --since v2.4.0
```

Scans CHANGELOG.md for `[FIX]` entries since the last release. For each fix, look for a test tagged with that issue / PR number. Flag fixes without tests.

### 2. Run regression-only suite
```bash
npx playwright test --grep '@regression'
```

Fast — runs ONLY regression tests, skips smoke / new-feature tests. ~30 sec for typical plugin. Good pre-merge gate.

### 3. Track regression-test count over time
```
Week 1:  12 regression tests
Week 4:  18 (+6)
Week 8:  24 (+6)
Week 12: 25 (+1)  ← lull = either fewer bugs OR not writing tests
```

If the count plateaus while bugs are still being fixed = process gap.

### 4. Reverse lookup: when a test fails, link to the original issue
A regression test failure should immediately surface "this guards #142, which was fixed because <reason>." Saves debug time.

---

## CI usage

```yaml
- name: Regression pack
  run: npx playwright test --grep '@regression'
- name: Regression coverage check
  run: bash scripts/regression-coverage.sh --since ${{ github.event.before }}
  # Fail if any FIX in this PR's commits has no @regression test
```

---

## Common patterns

### Every PR with a [FIX] commit must add a `@regression` test
Codify this as a CI check. Refuses to merge a fix without its guard.

### Don't delete regression tests
A regression test guards against a known historic bug. Even if the bug looks "impossible to recur", deleting the test removes the guard. Keep them forever.

### Regression tests can be slow
They can be the slowest of your suite — they're integration-heavy by nature. Run them less often than smoke (e.g., on PR not on every commit).

### Tag with both issue ID and one-line description
```js
test('@regression #142 — empty API key on settings page', ...);
```

This makes failures readable without opening the issue.

---

## Output

```markdown
# Regression Pack — my-plugin

## Stats
- Total regression tests: 47
- Tests added since v2.4 (last 90 days): 12
- Coverage rate: 12/14 [FIX] entries (86%) ← good but not 100%

## Untested fixes
- #198 — "Save fails on Mailchimp action" — no @regression test found
- #207 — "Block bindings break on PHP 8.3" — no @regression test found

## Run pack
```bash
npx playwright test --grep '@regression'
```
~32 seconds, 47 tests.
```

---

## Pair with

- `/orbit-changelog-test` — every changelog [FIX] should have a regression test
- `/orbit-qa-flaky-detector` — flaky regression tests are toxic, fix immediately

---

## Sources & Evergreen References

### Canonical docs
- [Playwright Test Tags](https://playwright.dev/docs/test-annotations#tag-tests) — `@tag` mechanism
- [Google Engineering — Test Sizes](https://abseil.io/resources/swe-book/html/ch11.html#test_sizes) — small/medium/large
- [Martin Fowler — Test Pyramid](https://martinfowler.com/articles/practical-test-pyramid.html) — where regression fits

### Last reviewed
- 2026-04-29
