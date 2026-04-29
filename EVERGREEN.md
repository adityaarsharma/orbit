# Orbit — The Evergreen Pattern

> Every Orbit skill is **research-backed and ever-evolving** — not a frozen rulebook.
> Each skill links to canonical sources, instructs Claude to fetch the latest before
> auditing, and documents *why* the rules exist (whitepaper intent), not just *what*.

---

## Why this matters

The WordPress / WP plugin ecosystem moves fast:
- Core APIs are added (Interactivity API, Block Bindings, theme.json schema 3) every 2-3 releases
- Best practices shift (apiVersion 1 → 2 → 3 in 18 months)
- Security patterns evolve (April 2026 ownership-transfer attack changed everyone's threat model)
- Browser engines deprecate features (third-party cookies, sync XHR, etc.)
- New competitors ship that change the bar (RankMath's onboarding wizard reset what "good" means)

A skill that hardcodes "WP supports X feature" goes stale fast. Orbit avoids this with **the evergreen pattern**: every skill says "fetch the canonical doc on every audit, then apply the rules below as a starting point — but trust the source over the rules."

---

## The pattern

Every Orbit skill must include a **`Sources & Evergreen References`** section near the bottom:

```markdown
## Sources & Evergreen References

> **Always pull these before auditing** — patterns evolve, hardcoded rules go stale.

### Canonical docs (fetch on every run)
- [WP Plugin Handbook — Block API](https://developer.wordpress.org/block-editor/reference-guides/block-api/)
  → Re-check every 90 days OR after a WP minor release
- [block.json metadata schema](https://schemas.wp.org/trunk/block.json)
  → JSON Schema — fetch + validate against this exact URL
- [Block API: apiVersion](https://developer.wordpress.org/block-editor/reference-guides/block-api/block-api-versions/)
  → Migrate apiVersion when this doc bumps the recommended version

### Live data feeds (used by this skill)
- [WP CVE feed (NVD)](https://nvd.nist.gov/feeds/json/cve/) — JSON, pulled on every audit
- [WPScan public feed](https://wpscan.com/wordpresses) — community-reported

### Rule lineage
- Rule #4 (apiVersion 3 required for `viewScriptModule`) — **WP 6.5 release notes**, March 2024
- Rule #7 (Block Bindings replaces custom render filters) — **WP 6.5 introduced**, deprecated old approach in 6.6

### Last reviewed
- 2026-04-29 — by Aditya Sharma
- Re-review trigger: any of (WP minor release · WPCS minor release · 90-day rolling window)
- Open issue if you spot a stale rule: [github.com/adityaarsharma/orbit/issues](https://github.com/adityaarsharma/orbit/issues)
```

---

## How a skill behaves at runtime (the evergreen behaviour)

When `/orbit-X` is invoked, the skill should — in this order:

1. **Fetch canonical docs** via WebFetch (or the user's prior-fetched cache, if recent).
2. **Diff** the doc's "current best practice" against the skill's hardcoded rules.
3. **If the doc has new guidance** the skill doesn't know about → flag it in output as `🆕 NEW PATTERN — added since rule was written. Verify and update the skill if confirmed.`
4. **Apply the rules**, prioritising the canonical doc when conflict exists.
5. **Cite the source** in every finding — e.g. `Per WP Plugin Handbook (fetched 2026-04-29): use sanitize_text_field for general string input.`

This means findings are always **dated** and **traceable**. A reader sees "rule from doc fetched today" — not "rule someone hardcoded 18 months ago and forgot."

---

## What every skill links to (universal sources)

These are baseline sources every WP-focused Orbit skill should reference:

| Source | Purpose |
|---|---|
| [WP Plugin Handbook](https://developer.wordpress.org/plugins/) | Canonical "how to write a WP plugin" |
| [WP Block Editor Handbook](https://developer.wordpress.org/block-editor/) | Gutenberg / block-editor docs |
| [WP Theme Handbook](https://developer.wordpress.org/themes/) | Theme + FSE docs |
| [WP REST API Handbook](https://developer.wordpress.org/rest-api/) | REST endpoint authoring |
| [WP Coding Standards (WPCS)](https://github.com/WordPress/WordPress-Coding-Standards) | PHPCS sniff source-of-truth |
| [WP VIP Coding Standards](https://github.com/Automattic/VIP-Coding-Standards) | Enterprise sniffs |
| [Make WP Core](https://make.wordpress.org/core/) | New API announcements, deprecations |
| [WP CLI Handbook](https://developer.wordpress.org/cli/) | CLI command reference |
| [WP-Env](https://github.com/WordPress/gutenberg/tree/trunk/packages/env) | Test environment |
| [Plugin Check tool](https://github.com/WordPress/plugin-check) | Official submission checks |

For non-WP sources (browser, language, security):

| Source | Purpose |
|---|---|
| [MDN Web Docs](https://developer.mozilla.org/) | HTML / CSS / JS canonical |
| [WCAG 2.2 Quick Reference](https://www.w3.org/WAI/WCAG22/quickref/) | A11y standard |
| [PHP.net manual](https://www.php.net/manual/) | PHP language reference |
| [PHPStan docs](https://phpstan.org/) | Static analysis rules |
| [Playwright docs](https://playwright.dev/) | E2E testing |
| [Lighthouse docs](https://developer.chrome.com/docs/lighthouse/) | Perf scoring |
| [OWASP Top 10](https://owasp.org/www-project-top-ten/) | Security baseline |
| [Patchstack threat feed](https://patchstack.com/database/) | WP-specific CVEs |
| [NVD (NIST)](https://nvd.nist.gov/) | Government CVE feed |

For framework-specific (Elementor, Woo, ACF, etc.):

| Source | Purpose |
|---|---|
| [Elementor Developers](https://developers.elementor.com/) | Widget / control / skin dev |
| [WooCommerce Developer Resources](https://developer.woocommerce.com/) | WC hooks, HPOS, templates |
| [ACF Documentation](https://www.advancedcustomfields.com/resources/) | ACF integration |
| [Yoast Developer Docs](https://developer.yoast.com/) | Yoast filters / hooks |
| [WPML Documentation](https://wpml.org/documentation/) | WPML compat |
| [Polylang Documentation](https://polylang.pro/doc/) | Polylang compat |
| [Stripe API Reference](https://docs.stripe.com/api) | Stripe SDK |
| [PayPal Developer](https://developer.paypal.com/) | PayPal SDK |

---

## Whitepaper-intent: every skill explains *why*

A rule without a reason is dead weight. Every Orbit skill rule should have a **whitepaper intent** — one sentence explaining the underlying principle, and a citation back to the source.

Example (from `/orbit-wp-security`):

```markdown
### Rule: All AJAX handlers must verify a nonce

**Whitepaper intent:** Without nonce verification, a logged-in user can be tricked
into making state-changing requests via a malicious site they happen to visit
(CSRF). This is OWASP Top 10 #1 historically and remains the most common WP
plugin vulnerability class on Patchstack's 2025 quarterly reports.

**Source:** [WP Plugin Handbook — Nonces](https://developer.wordpress.org/plugins/security/nonces/) · [OWASP CSRF](https://owasp.org/www-community/attacks/csrf)
**Last reviewed:** 2026-04-29
```

This pattern means a junior developer reading the audit understands not just "fix this" but "why this exists in the first place."

---

## How to keep a skill evergreen

1. **Re-fetch the linked sources every 90 days** (or after a WP minor release).
2. **Diff** what changed in the doc.
3. **Update the rules** in the SKILL.md if the doc shifted.
4. **Bump `Last reviewed`** date.
5. **Open a PR** — never silent edits. Audit trail matters.

Or use:
```
/orbit-evergreen-update
```

The meta-skill that walks every orbit-* skill, fetches its linked sources, flags anything that's drifted, and (with confirmation) updates the rules.

---

## What makes this different from "just docs"

Static documentation rots. A skill that says "Use `apiVersion: 2`" is a time bomb — true in 2023, wrong in 2024.

Orbit's evergreen pattern means:
- **Every audit cites the source on the day it ran** — output is traceable
- **Sources are URLs, not hardcoded text** — editing the source updates the skill
- **`Last reviewed` is visible** — readers know if a skill is stale
- **`/orbit-evergreen-update`** can scan all skills and flag drift

The rules in any SKILL.md are a *starting point*. The canonical doc is always source-of-truth.

---

## Adding evergreen sections to existing skills

When auditing the existing 45 skills, each gets:

1. A `Sources & Evergreen References` section near the bottom
2. Whitepaper-intent paragraphs on the most opinionated rules
3. A `Last reviewed` timestamp

Use `/orbit-evergreen-update` (the meta-skill) to do this automatically. It:
- Reads each SKILL.md
- Adds the missing sections from a template
- Pulls the right canonical sources based on the skill's domain
- Sets `Last reviewed` to today
- Opens a PR with the additions

---

## Built by

[Aditya Sharma](https://adityaarsharma.com) · POSIMYTH Innovation · github.com/adityaarsharma/orbit

**Core philosophy:** Software-quality tooling should evolve with the software. Orbit's job isn't to ship rules from 2024 to 2030 — it's to know what 2030 looks like by re-reading the canonical sources every time it runs.
