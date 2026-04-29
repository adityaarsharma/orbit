---
name: orbit-qa-snapshot-cleanup
description: Clean stale Playwright visual snapshots — find PNGs in `__screenshots__/` that no test references anymore, find tests that have a snapshot per browser project but lost some over time, find snapshots that haven't been touched in 6+ months. Use when the user says "stale snapshots", "snapshot cleanup", "playwright screenshots accumulating", "clean screenshot dir".
---

# 🪐 orbit-qa-snapshot-cleanup — Stale snapshot cleanup

Visual regression baselines accumulate. Tests get renamed, snapshots stay. After a year you have 1000 PNGs and don't know which are live. This skill cleans them.

---

## Quick start

```bash
bash ~/Claude/orbit/scripts/cleanup-snapshots.sh --dry-run
```

`--dry-run` shows what would be deleted without doing it. Drop the flag to apply.

---

## What it finds

### 1. Orphan snapshots (no test references them)
Greps every `*.spec.js` for `toHaveScreenshot('name.png')` and lists every PNG in `__screenshots__/` that no test ever calls.

```
[Orphans — 47 PNGs, 14 MB]
- tests/playwright/__screenshots__/old-feature-chromium-darwin.png
- tests/playwright/__screenshots__/removed-test-firefox-darwin.png
...
```

### 2. Incomplete project coverage
A test exists for chromium + firefox + webkit but only one of those snapshots exists.

```
[Incomplete coverage]
- tests/visual/cards.spec.js > "Card layout" — has chromium PNG, missing firefox + webkit
   → Either re-run with `--update-snapshots` or remove unused projects
```

### 3. Stale snapshots (6+ months old)
A PNG that hasn't been re-generated in 6 months suggests the test never failed = either the test is too lax, or the design genuinely hasn't changed (unlikely over 6 months on an active product).

```
[Stale — touched > 6 months ago]
- card-default.png — last modified 2025-09-04 (8 months)
- card-hover.png — last modified 2025-09-04 (8 months)
   → Either design is genuinely stable, or threshold too lax
```

### 4. Wrong-platform snapshots committed
`-darwin.png` committed by Mac developers, no `-linux.png` for CI.

---

## Output

```markdown
# Snapshot Cleanup — my-plugin

## Total PNGs: 1,247 (52 MB)

## Findings
- Orphans (no test): 47 PNGs (14 MB)
- Incomplete coverage: 12 tests have partial PNG sets
- Stale (>6 mo): 23 PNGs
- Wrong platform: 8 -darwin.png committed without -linux.png

## Recommended action
Run with --apply to delete 47 orphans (14 MB recovered).
Run with --regenerate to re-baseline 23 stale PNGs (will re-screenshot).
Document missing -linux.png in CI workflow.
```

---

## Strategy: Linux-only baselines for CI consistency

**Whitepaper intent:** Mac and Linux render fonts slightly differently. Mac developers updating snapshots locally creates churn — every CI run fails because Linux renders differ. Solution: only commit `-linux.png`, generate via Docker.

```bash
# Generate Linux baselines via Docker
docker run --rm -v $PWD:/work mcr.microsoft.com/playwright:v1.50.0-jammy \
  bash -c "cd /work && npx playwright test --update-snapshots --project=chromium-linux"

# Commit only -linux.png
git add 'tests/**/*-linux.png'
```

Mac developers only ever update `-darwin.png` for local visual debugging — never commit them.

---

## Pair with

- `/orbit-visual-regression` — runs the snapshots that this skill cleans
- `/orbit-qa-flaky-detector` — visual flakiness often = stale baseline

---

## Sources & Evergreen References

### Canonical docs
- [Playwright — Visual Comparisons](https://playwright.dev/docs/test-snapshots) — baseline + diff
- [Storybook — visual testing](https://storybook.js.org/docs/writing-tests/visual-testing) — alternative tool
- [Chromatic](https://www.chromatic.com/) — managed visual review

### Last reviewed
- 2026-04-29
