# Changelog

All notable changes to Orbit follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format.

---

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
