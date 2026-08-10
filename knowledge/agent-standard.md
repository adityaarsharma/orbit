# Orbit — Agent Operating Standard (open-source)

> How every Orbit agent runs. Industry-grounded (Anthropic engineering, Cognition, LangChain, ReasoningBank 2025–26). This is the general/standalone standard — it reads knowledge from this repo's `knowledge/` directory, not from any hosted service.

1. **Load the bug-signature DB first.** Before any scan, read `knowledge/bug-signatures.md` for the relevant categories (A security · B core-compat · C WooCommerce · D i18n · E perf/DB · F PHP-8) so you check the ~85% threat surface (XSS/CSRF/access-control/SQLi) even when the operator didn't name it. Never scratch the surface.

2. **Bounded reflection.** After the first output, critique against explicit criteria and revise. The **check itself is the external verifier** (PHPStan level-5 / PHPCS exit code / Playwright pass) → reflection + external verifier ≈ +30pt accuracy. Cap at 2 passes then escalate. The author doesn't grade the author.

3. **Fan-out rule (parallel vs coupled).** Parallelize independent read-only checks (security/i18n/perf/DB/a11y). Single-thread coupled bug-*fixing* (agents touching the same files) — parallel writers make conflicting decisions and break patches. Right-size: a small plugin ≠ the full gauntlet.

4. **Docker-live by default.** Don't assert a bug from static reading alone when it can be reproduced — spin a clean `wp-env` and verify live across the matrix: WP 6.5/6.6/6.7/6.8/7.0.x × PHP 8.0–8.3, WooCommerce HPOS on(sync off)/compat-mode/CPT, block + shortcode checkout. Many bugs are data- and version-dependent and invisible on single-version CI.

5. **Just-in-time context.** Hold file paths + `knowledge/` references, not whole files/logs. Route high-volume output (PHPCS/crawl/Lighthouse) to a summarizer subagent; return a summary + a reference.

6. **Self-eval + ever-evolving.** Every bug that escapes becomes (a) a permanent fixture in `knowledge/eval-fixtures.md` AND (b) a new signature in `knowledge/bug-signatures.md` — learn from failure as much as success. Run the fixture set before shipping any change; a miss = regression = block.

7. **Report quality.** Senior-developer balance — real, reproducible findings with `file:line` + edge cases; **not** hallucinated/assumed code, and **not** over-hard noise that messes up the product. Every finding: pattern → evidence → fix → edge/backward cases.
