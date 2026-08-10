# Orbit — Agent Instructions

> **Agentic system is live.** See `CLAUDE.md` for the full routing layer and 12-agent team.
> This file retains the core skill rules and deduplication reference (still applies).
> For intent → agent routing, approval gates, and brain integration, use CLAUDE.md.

---

---

## Hard Rule: Always Use These Skills

When asked to run any audit, review, test, or analysis on a WordPress plugin
via Orbit — **always invoke the skills below**. Do not skip them, do not
summarize without running them, do not give surface-level output without them.

### The Six Core Orbit Skills

These six are mandatory for every full audit. Run them in parallel.

| # | Skill | What it checks |
|---|-------|----------------|
| 1 | `/orbit-wp-standards` | WP coding standards — hooks, escaping, nonces, capability checks, i18n, naming |
| 2 | `/security-auditor` + `/security-scanning-security-sast` | PHP source code security — XSS, CSRF, SQLi, auth bypass, WP-specific vuln patterns |
| 3 | `/orbit-wp-performance` | WP hook weight, N+1 DB calls, blocking assets, expensive loops, transient misuse |
| 4 | `/orbit-wp-database` | Prepared statements, autoload bloat, missing indexes, transient patterns, uninstall cleanup |
| 5 | `/accessibility-compliance-accessibility-audit` | WCAG 2.2 AA — admin UI, block editor, frontend output |
| 6 | `/vibe-code-auditor` + `/codebase-audit-pre-push` | Code quality + AI-generated code risks — dead code, complexity, error handling |

> **IMPORTANT — Skills that have been REMOVED from the core 6 and why:**
> - `/wordpress-penetration-testing` — This is an **attacker tool** (WPScan, Metasploit, brute force). It does NOT read PHP source code. Use it only for live staging audits. For code review, use `/security-auditor` + `/security-scanning-security-sast`.
> - `/performance-engineer` — This is a **cloud infrastructure skill** (Kubernetes, Prometheus, APM). It has no knowledge of WordPress hooks, transients, or WP_Query. Use `/orbit-wp-performance` instead.
> - `/database-optimizer` (community) — This is an **enterprise DBA skill** (PostgreSQL sharding, DynamoDB). Not guaranteed to know `$wpdb`, autoload, or WP patterns. Use `/orbit-wp-database` instead.
> - `/wordpress-plugin-development` — This is a **scaffolding skill** that generates new plugin boilerplate. It is not a code reviewer. Use `/orbit-wp-standards` instead.

### How to Invoke

```bash
# Full audit — all 6 in parallel
claude "/orbit-wp-standards Audit /path/to/plugin — WP coding standards, nonces, escaping, caps, i18n"
claude "/security-auditor + /security-scanning-security-sast Security audit /path/to/plugin — PHP source code review, WP vuln patterns"
claude "/orbit-wp-performance Analyze /path/to/plugin — WP hooks, N+1, transient misuse, asset loading"
claude "/orbit-wp-database Review /path/to/plugin — $wpdb, autoload, indexes, uninstall cleanup"
claude "/accessibility-compliance-accessibility-audit Check /path/to/plugin admin UI + frontend"
claude "/vibe-code-auditor + /codebase-audit-pre-push Review /path/to/plugin — quality, AI-gen code risks, complexity"
```

Or use the gauntlet (runs all 6 automatically in parallel):

```bash
bash scripts/gauntlet.sh --plugin /path/to/plugin --mode full
```

---

## Skill Selection by Plugin Type

Add these on top of the core 6 based on what the plugin is:

| Plugin type | Extra skills to add |
|-------------|-------------------|
| Elementor addon / UI-heavy | `/antigravity-design-expert` — 44px hit areas, spacing, motion |
| Theme or FSE | `/wordpress-theme-development` — template hierarchy, FSE, theme.json |
| WooCommerce plugin | `/wordpress-woocommerce-development` — WC hooks, gateway security, templates |
| REST API / headless | `/api-security-testing` — endpoint security, auth, rate limiting |
| PHP-heavy / complex logic | `/php-pro` — PHP 8.x patterns, type safety, modern idioms |

---

## Skill Deduplication Reference

When multiple skills overlap, use these and only these:

| Task | Use this | NOT these |
|------|----------|-----------|
| WP coding standards review | `/orbit-wp-standards` | ~~`/wordpress-plugin-development`~~ (scaffolder, not reviewer), ~~`/wordpress`~~ (too generic) |
| Security — PHP source code review | `/security-auditor` + `/security-scanning-security-sast` + `/orbit-wp-security` | ~~`/wordpress-penetration-testing`~~ (**attacker tool — wrong for code review**), ~~`/security-audit`~~ |
| Security — live staging audit | `/wordpress-penetration-testing` | ~~`/security-auditor`~~ (not for live URL scanning) |
| Performance | `/orbit-wp-performance` + `/web-performance-optimization` | ~~`/performance-engineer`~~ (**cloud infra skill, wrong domain**), ~~`/performance-optimizer`~~ |
| DB review | `/orbit-wp-database` | ~~`/database-optimizer`~~ (enterprise DBA, wrong dialect), ~~`/database-admin`~~, ~~`/database-architect`~~ |
| Code quality | `/vibe-code-auditor` + `/codebase-audit-pre-push` | ~~`/code-review-excellence`~~ (generic, no WP context), ~~`/code-reviewer`~~ |
| Accessibility | `/accessibility-compliance-accessibility-audit` + `/fixing-accessibility` + `/wcag-audit-patterns` | ~~`/accessibility`~~ (too generic) |
| E2E tests | `/playwright-skill` + `/e2e-testing-patterns` | ~~`/e2e-testing`~~, ~~`/playwright-java`~~ |
| AI-generated code risks | `/vibe-code-auditor` | ~~`/code-review-excellence`~~ (doesn't flag AI hallucinations) |

---

## What Never Goes in This Repo

- Plugin brand names (example-plugin, example-plugin, tpa, Orbit, example-plugin)
- Plugin-specific test configs, setup JSONs, .wp-env.json per plugin
- reports/, .auth/, test-results/ directories
- Any file referencing a live staging URL or internal credential

Plugin workspaces live locally (`~/Claude/wordpress-qa-master/<plugin-name>/`)
and are excluded from git via `.gitignore`.

---

## Severity Triage (apply to all skill output)

| Level | Action |
|-------|--------|
| Critical | Block release. Fix now. |
| High | Block release. Fix now. |
| Medium | Fix in this release if < 30 min. Otherwise log in tech debt. |
| Low / Info | Log. Defer. |
