# Orbit Knowledge Base

The general, open-source brain of Orbit — shipped as plain files so the tool runs **standalone** (no hosted service required).

| File | What it is |
|---|---|
| [`bug-signatures.md`](bug-signatures.md) | 53 WordPress bug signatures (security · core-compat · WooCommerce · i18n · perf/DB · PHP 8 · cache/drop-in) — pattern → detection hint → edge cases. Sourced from Patchstack/WPScan/WP-core/PHP-manual 2025–26. |
| [`eval-fixtures.md`](eval-fixtures.md) | 20 known-buggy fixtures with ground-truth findings — the regression gate. |
| [`agent-standard.md`](agent-standard.md) | How agents reason: load-signatures-first, bounded reflection, Docker-live, self-eval. |

## Ever-evolving
Bug signatures are meant to grow. Any bug that escapes a real audit should be added **immediately** as a new signature (`bug-signatures.md`) + a fixture (`eval-fixtures.md`), so the next scan pattern-matches it (faster) and the miss can never repeat. Contributions of new, general WordPress bug signatures are welcome via PR.

## Note on the two versions of Orbit
This repository is the **general, open-source** Orbit — a WordPress QA agent framework anyone can run, with no vendor lock-in. A separately-maintained specialized build layers product-specific intelligence on top; only **general** WordPress patterns live here.
