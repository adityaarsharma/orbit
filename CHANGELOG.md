# Changelog

All notable changes to Orbit follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.

---

## [4.1.2] — Fresh-Install Fixes

### Fixed
- **Agents now register on a fresh install.** Every `agents/orbit-*.md` was missing YAML frontmatter after the `orbit-*-agent.md` → `orbit-*.md` rename, so Claude Code silently did not recognise them as agents. Added `name:` + `description:` to all 11. (Upgraders kept their old labelled files, so the break was invisible to them.)
- **Updater no longer sabotages itself.** `.orbit_version` was git-tracked but rewritten by the installer every run, leaving the tree permanently dirty so the next `git pull --rebase` failed forever. It is now untracked (`.gitignore`) and removed from version control.
- **Stale agents are cleaned up on upgrade.** `OLD_ORBIT_AGENTS` in `install.sh` covered only the v2.x and v3.x-numeric names; the `orbit-*-agent.md` names were never removed, leaving every agent duplicated. Added them.
- **Dead addresses removed.** Stripped the non-existent `/orbit-example-plugin-block` command (routes, code-reviewer, SKILLS) and the mangled `brain.Orbit.com` sub-endpoints block + dead `BRAIN_URL` (routes, install.sh) left behind by the open-source find-and-replace.

---

## [4.1.1] — Bulk Admin Action Signature

### Added
- **`knowledge/bug-signatures.md` — E7 (bulk admin action at scale):** WordPress admin bulk actions (Comments/Posts/Users → select many → Trash/Delete/Edit) fire per-item hooks N times in one request. Plugin callbacks must survive a null parent object, batch/defer expensive work (cache purge, remote API, DB writes), and not exhaust memory/time. The classic fatal is calling a method on a null `WP_Post`/`WP_Comment` during a bulk trash — invisible on single-item CI, only reproduces at 50–200 items. Cross-refs G4/G6 (cache plugins purge on comment/post events, so they trip this most).
- **`knowledge/eval-fixtures.md` — E-04:** bulk-comment-trash fatal fixture (select-all → Move to Trash), reproduced at scale, not single-item.
- Sourced from a real support ticket: a cache plugin fataling on bulk comment deletion in wp-admin. Signature count now **53**.

### Why
- Bulk admin actions are a blind spot for single-item test suites: the per-item hook path passes on one item and fatals on a hundred. Any plugin hooked on comment/post lifecycle events needs testing at batch scale.

## [4.1.0] — Cache & Drop-in Plugin Signatures

### Added
- **`knowledge/bug-signatures.md` — Category G (Full-Page Cache & Drop-in Plugins):** 12 new general signatures (G1–G12) for the class of plugins that run code before WordPress loads (`advanced-cache.php`/`object-cache.php`), edit `wp-config.php`, and write request-influenced paths to disk. Covers: programmatic wp-config edits (backup/restore/anchored-regex), pre-WP drop-in path traversal, 200-gate + bypass-constant handling, logged-in/private-content cache bleed, cached-nonce breakage, orphaned-drop-in WSOD, object-cache `unserialize` object-injection, cache-dir web-exposure, write atomicity, cache-file/inode explosion, WP_Filesystem in runtime, and gzip double-compression.
- **`knowledge/eval-fixtures.md` — Set G:** 8 new regression fixtures (G-01…G-08) with ground-truth findings for the above.
- Signature count is now **52 across 7 categories** (added cache/drop-in).

### Why
- Full-page cache plugins are among the highest-blast-radius WordPress plugins — a single drop-in or wp-config mistake white-screens every page or serves one visitor's private page to another. These are the exact patterns that get cache plugins rejected from the directory or hit with CVEs, so the tool now pattern-matches them on the first pass.

## [4.0.1] — General / Brand-Clean

### Changed
- Removed all vendor/product/personal branding and hosted-service lock-in. Orbit is now a **pure, general open-source WordPress QA agent framework** — no external branding, brain/memory is optional.
- Removed vendor-specific infra (hosted-brain seeders, connector installer, internal team/MCP docs) and a product-specific skill. Product-name examples replaced with generic placeholders (`example-plugin`).

## [4.0.0] — Open-Source Knowledge Base

### Added
- **`knowledge/bug-signatures.md`** — 40+ general WordPress bug signatures (Category A security, B core-compat 6.5→7.0, C WooCommerce HPOS/blocks, D i18n, E perf/DB, F PHP 8.0–8.3), each with a detection hint + edge/backward cases. Sourced from Patchstack/WPScan/WordPress-core/PHP-manual (2025–26).
- **`knowledge/eval-fixtures.md`** — 20 known-buggy fixtures with ground-truth findings + a regression-gate protocol.
- **`knowledge/agent-standard.md`** — reasoning standard: load-signatures-first, bounded reflection (check = external verifier), parallel-vs-coupled fan-out, Docker-live-by-default, self-eval, ever-evolving.

### How it works
- Agents run against a WordPress site in a clean Docker (`wp-env`) environment, run the 11-step gauntlet + skill audits, and produce reports with `file:line` findings.
- Bug signatures are meant to grow: any bug that escapes a real audit should be added as a new signature + fixture (PRs welcome).

---

_Earlier internal history is kept in git; this changelog starts fresh for the open-source release._
