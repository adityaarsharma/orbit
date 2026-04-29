# Orbit Skill Roadmap

> 45 skills shipped in v2.5. **60+ more** identified as high-value candidates.
> Pick any unclaimed item, draft via `/orbit-skill-add`, send a PR.

**Repo:** https://github.com/adityaarsharma/orbit
**Master skill index:** [SKILLS.md](SKILLS.md)
**How to add a new skill:** [skills/orbit-skill-add/SKILL.md](skills/orbit-skill-add/SKILL.md)

---

## Tier 1 — High demand (community asked, no-one has built)

### Plugin compatibility matrix
- [ ] **`/orbit-elementor-compat`** — Elementor versions 3.18 / 3.20 / 3.22+ matrix
- [ ] **`/orbit-gutenberg-compat`** — Block editor versions WP 6.3 / 6.5 / latest
- [ ] **`/orbit-woo-compat`** — WooCommerce 7.x / 8.x / 9.x feature deprecations
- [ ] **`/orbit-acf-compat`** — Advanced Custom Fields integration patterns
- [ ] **`/orbit-yoast-compat`** — Coexistence with Yoast SEO (custom post types, schema)
- [ ] **`/orbit-rankmath-compat`** — Coexistence with RankMath
- [ ] **`/orbit-wpml-compat`** — Translation strings + custom post types via WPML
- [ ] **`/orbit-polylang-compat`** — Translation strings + custom post types via Polylang
- [ ] **`/orbit-buddypress-compat`** — BuddyPress hooks + activity stream integration
- [ ] **`/orbit-bbpress-compat`** — bbPress forum integration

### Hosting tier compatibility
- [ ] **`/orbit-wpengine-compat`** — WPEngine restrictions (disallowed plugins, file locks)
- [ ] **`/orbit-kinsta-compat`** — Kinsta object cache + edge caching specifics
- [ ] **`/orbit-cloudways-compat`** — Cloudways Breeze / Object Cache Pro
- [ ] **`/orbit-shared-hosting-compat`** — low-tier shared hosting (memory limits, time outs)
- [ ] **`/orbit-pantheon-compat`** — Pantheon's per-environment file system, Redis

### Payment / monetisation
- [ ] **`/orbit-stripe-test`** — Stripe API integration (idempotency, webhook signature, refunds)
- [ ] **`/orbit-paypal-test`** — PayPal Smart Buttons + IPN verification
- [ ] **`/orbit-edd-license`** — Easy Digital Downloads license check
- [ ] **`/orbit-freemius-compat`** — Freemius SDK integration
- [ ] **`/orbit-woo-payments-compat`** — WooCommerce Payments hooks + 3DS

---

## Tier 2 — WordPress core areas

### Lifecycle
- [ ] **`/orbit-activation-test`** — `register_activation_hook` safety + idempotence
- [ ] **`/orbit-deactivation-test`** — Clean shutdown, scheduled task cleanup
- [ ] **`/orbit-upgrade-test`** — Migration paths between plugin versions (e.g., v1 → v2)
- [ ] **`/orbit-rollback-test`** — Plugin downgrade safety
- [ ] **`/orbit-bulk-activate`** — Behaviour when activated alongside 50+ other plugins

### REST / WP-CLI / Admin
- [ ] **`/orbit-wp-cli-coverage`** — WP-CLI command coverage for plugin features
- [ ] **`/orbit-rest-spec`** — REST endpoint OpenAPI / Swagger generation
- [ ] **`/orbit-shortcode-fuzzer`** — Shortcode attribute fuzzing
- [ ] **`/orbit-wp-admin-bar`** — Admin bar registration sanity
- [ ] **`/orbit-customizer-compat`** — Customizer panel registration + live preview

### Block editor (Gutenberg)
- [ ] **`/orbit-block-render-test`** — Server-side render PHP coverage
- [ ] **`/orbit-block-edit-test`** — JS edit-time tests via Playwright
- [ ] **`/orbit-block-pattern-test`** — Block pattern registration + preview
- [ ] **`/orbit-fse-test`** — FSE compatibility (full-site-editing themes)
- [ ] **`/orbit-theme-json-validate`** — theme.json schema 3 validation

---

## Tier 3 — Performance / UX

### Performance
- [ ] **`/orbit-cdn-test`** — CDN compatibility (Cloudflare, BunnyCDN, KeyCDN)
- [ ] **`/orbit-image-opt`** — Image optimisation (WebP, AVIF, lazy-load, srcset)
- [ ] **`/orbit-font-loading`** — FOIT/FOUT, preload, font-display strategies
- [ ] **`/orbit-mutation-test`** — Infection PHP for test quality (catches weak tests)
- [ ] **`/orbit-stress-test`** — k6 / JMeter against the plugin's hot endpoints
- [ ] **`/orbit-memory-leak`** — Long-running process memory growth detection

### UX / design
- [ ] **`/orbit-rtl-visual`** — RTL layout visual regression
- [ ] **`/orbit-dark-mode`** — Admin dark mode + WP 6.5+ admin colour schemes
- [ ] **`/orbit-color-contrast`** — Computed colour contrast on dynamic content
- [ ] **`/orbit-empty-state-audit`** — Every settings page's empty state has guidance
- [ ] **`/orbit-error-state-audit`** — Form validation messages + error pages

---

## Tier 4 — Security specialised

### Active probes
- [ ] **`/orbit-xss-test`** — DOM / reflected / stored XSS automated probes
- [ ] **`/orbit-csrf-test`** — CSRF protection coverage
- [ ] **`/orbit-sqli-test`** — SQL injection automated probes (read-only)
- [ ] **`/orbit-auth-bypass`** — Privilege escalation paths
- [ ] **`/orbit-file-upload-test`** — Upload vulns (mime sniffing, path traversal)
- [ ] **`/orbit-deserialize-test`** — `unserialize()` on user input
- [ ] **`/orbit-secrets-leak`** — Hardcoded keys, tokens, .env in source
- [ ] **`/orbit-supply-chain`** — Composer + npm dependency audit (`composer audit` + Socket.dev)

### Compliance
- [ ] **`/orbit-pci-compat`** — PCI-DSS for payment plugins
- [ ] **`/orbit-hipaa-compat`** — HIPAA basics for health-related plugins
- [ ] **`/orbit-cookie-audit`** — Cookie compliance + ePrivacy declarations

---

## Tier 5 — SEO / marketing

- [ ] **`/orbit-schema-test`** — Schema.org structured data validation (JSON-LD)
- [ ] **`/orbit-sitemap-test`** — XML sitemap validity + ping behaviour
- [ ] **`/orbit-meta-tags`** — OG, Twitter cards, canonical URL coverage
- [ ] **`/orbit-page-speed-insights`** — Google PageSpeed Insights API integration
- [ ] **`/orbit-search-console`** — Search Console verification flow

---

## Tier 6 — Plugin-store integration

- [ ] **`/orbit-readme-generator`** — Auto-generate readme.txt from inline docs
- [ ] **`/orbit-changelog-format`** — Keep a Changelog format validator
- [ ] **`/orbit-update-server`** — License-server / update-server stub for testing
- [ ] **`/orbit-licence-checker`** — In-plugin licence check pattern audit
- [ ] **`/orbit-app-store-screenshot`** — WP.org screenshot generator + naming

---

## Tier 7 — DX / developer experience

- [ ] **`/orbit-debug-tools`** — Query Monitor + Debug Bar integration
- [ ] **`/orbit-error-log`** — debug.log analysis after a gauntlet run
- [ ] **`/orbit-php-error`** — Uncaught exception handler audit
- [ ] **`/orbit-js-error`** — Console error tracker (per page)
- [ ] **`/orbit-hot-reload`** — HMR / live-reload setup for dev
- [ ] **`/orbit-typedef-gen`** — Generate `.d.ts` from PHP class signatures (for JS callers)

---

## Tier 8 — CI/CD

- [ ] **`/orbit-github-actions`** — Generate the full GHA workflow file from `qa.config.json`
- [ ] **`/orbit-gitlab-ci`** — Same for GitLab CI
- [ ] **`/orbit-bitbucket-pipelines`** — Same for Bitbucket
- [ ] **`/orbit-pr-comment`** — Auto-comment GitHub PR with gauntlet summary
- [ ] **`/orbit-release-notes-gen`** — Auto-draft release notes from changelog + visual diffs

---

## Tier 9 — Migration / backup

- [ ] **`/orbit-migration-test`** — Compat with Duplicator, All-in-One Migration, etc.
- [ ] **`/orbit-backup-restore-test`** — UpdraftPlus / BackWPup restore loops
- [ ] **`/orbit-export-test`** — WXR export coverage
- [ ] **`/orbit-import-test`** — WXR import (does plugin's CPT data survive?)

---

## Tier 10 — Documentation / contributor experience

- [ ] **`/orbit-onboarding`** — Generate a CONTRIBUTING.md from current repo
- [ ] **`/orbit-issue-template`** — Generate GitHub issue templates per plugin type
- [ ] **`/orbit-doc-coverage`** — Audit which public functions lack PHPDoc
- [ ] **`/orbit-jsdoc-coverage`** — Same for JS exports

---

## How to claim a roadmap item

1. Open an issue at https://github.com/adityaarsharma/orbit/issues with the format:
   `[skill] /orbit-<name> — <one-line purpose>`
2. Get a thumbs-up from a maintainer (avoids duplicate work).
3. Use `/orbit-skill-add` to scaffold.
4. Open a PR with the new skill folder + SKILLS.md entry + master menu update.

---

## How to suggest a new skill not on this list

Open an issue with the `[roadmap]` tag. Include:
- The use case (real customer scenario, ideally)
- Why existing skills don't cover it
- A reference link (incident, standard, or competitor doing it)

The shorter the description, the higher the chance of acceptance.

---

## Vision

Orbit is local-first, free, open-source, and designed to grow with the WordPress ecosystem. Every skill on this list represents a real edge case a real plugin team will hit at some point. The goal is to build the catalogue once so the next team doesn't have to re-discover the gotcha.

**Built by [Aditya Sharma](https://adityaarsharma.com) · POSIMYTH Innovation**
