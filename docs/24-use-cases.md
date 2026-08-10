# Use Cases — Orbit in Real Scenarios

> Real-world workflows using Orbit — both the 10-agent agentic system (v3.0) and the direct skill commands (v2.x+). Pick the mode that fits how you work.

---

## Agentic Use Cases (v3.0 — 10-agent team)

These scenarios show how Orbit's agents collaborate through `brain`. Each agent reads the shared CTO brain first, does its specialized work, ingests findings, and hands off to the next agent.

**How to invoke an agent in Claude Code:**
```
You:  "Run a UAT audit on ~/plugins/example-plugin for v2.5 RC"
      → 05-UAT agent activates, runs Brain Prime, dispatches 07+06+04 in parallel
      → Returns severity-triaged bug report + CLEAR/BLOCKED verdict

You:  "Security scan TPA for the new Ajax handler in settings-ajax.php"
      → 07-Security activates, escalates any Critical immediately

You:  "CTO brief on Elementor's new AI features — should we respond?"
      → 00-CTO activates, searches all brains, returns CTO BRIEF with recommendation
```

---

### A1. Full release pipeline — example-plugin v2.5

**Situation:** v2.5 is feature-complete. Time to gate, test, and ship.

**Agent sequence:**
```
you → 01-PM    "example-plugin v2.5 is dev-complete. Run release prep."
01-PM          Checks open RICE items. Confirms v2.5 scope. Routes work:
               → 05-UAT: full audit
               → 09-Docs: freshness check (parallel)

05-UAT         Brain Prime: loads v2.4 bug history, known flaky tests from orbit/05
               Spins Docker WP 6.8 env. Playwright E2E. Dispatches in parallel:
               → 07-Security: full code scan
               → 06-Performance: benchmark vs v2.4 baseline
               → 04-DevDesigner: accessibility + RTL check
               All pass → UAT CLEAR for v2.5

08-Release     you → "Run release gate for example-plugin v2.5"
               7 checks in order. All pass:
               ✓ pre-commit  ✓ metadata  ✓ plugin-check
               ✓ changelog   ✓ version   ✓ zip  ✓ i18n
               → Release gate PASSED
               → Release notes drafted (Orbit voice)
               → you: approve → cross-channel announce (blog + email + social + Discord)

09-Docs        Freshness audit done during UAT.
               New scroll-animation block documented. Hook reference updated.
               you: approve → publishes same day as release.
```

**Total agent involvement:** 01-PM → 05-UAT (+ 07 + 06 + 04 parallel) → 08-Release → 09-Docs

---

### A2. Critical XSS found — emergency patch flow

**Situation:** Security scan found unescaped output in TPA settings page.

```
you → 07-Security  "Scan TPA v6.3 settings-ajax.php"

07-Security    Brain Prime: loads past TPA findings from orbit/07, WP XSS patterns from orbit/00-cto
               Scans.
               → CRITICAL: wp-content/plugins/tpa/includes/settings-ajax.php:142
                 echo $_GET['search'] — unescaped output in admin context.
               → ESCALATING CRITICAL to 01-PM immediately.
               Ingests: [security, tpa, Critical, xss-settings-page, settings-ajax.php:142, v6.3]

01-PM          Receives escalation. Blocks sprint. Routes to 03-SrDev: Priority 0.
               Notifies 08-Release: release gate halted.

you → 03-SrDev  "Fix the XSS in settings-ajax.php:142. Security report attached."

03-SrDev       Brain Prime: loads orbit/00-cto XSS hard rule, past TPA fix patterns from orbit/03
               Fix: echo esc_html( sanitize_text_field( $_GET['search'] ?? '' ) );
               Runs /orbit-wp-standards. Clean.
               Routes to 07-Security for re-scan.

07-Security    Re-scans settings-ajax.php. Clean.
               Ingests: [security, tpa, fixed, xss-settings-page, v6.3.1]

you → 08-Release  "Emergency patch release — TPA v6.3.1"
08-Release     7-step gate. PASS. Ships.
```

**Time from escalation to patch release:** 2–4 hours with the brain context loaded.

---

### A3. WP.org rejection → the brain learns forever

**Situation:** TPA v6.2.0 rejected. "Plugin is loading scripts on all admin pages."

```
08-Release     Receives WP.org rejection notice.
               Ingests: [release, tpa, wp-org-rejection, scripts-all-admin-pages, v6.2.0]
               Routes to 00-CTO: "This may be a pattern across all plugins."

00-CTO         Brain Prime fan-out: checks orbit/02-code-reviewer for same pattern.
               Found: example-plugin has same issue in enqueue.php.
               Decision: promote to hard rule.
               Ingests to orbit/00-cto/hard-rules/:
               [cto, hard-rule, enqueue-on-specific-pages-only, wp-org-requirement, 2026-05-20]

Next sprint:   02-CodeReviewer's Brain Prime loads this rule automatically.
               Any PR that enqueues on all admin pages → REQUEST CHANGES, before WP.org ever sees it.

Next release:  08-Release's Brain Prime loads this rule.
               Checks enqueue pattern in 7-step gate.

Outcome:       One rejection → zero repeats across all 3 plugins, indefinitely.
```

---

### A4. Performance regression caught before users notice

**Situation:** example-plugin v2.5 shows DB query spike in benchmark.

```
you → 06-Performance  "Benchmark example-plugin v2.5 vs v2.4 baseline"

06-Performance  Brain Prime: loads v2.4 baseline from orbit/06/example-plugin/budget
                Benchmarks v2.5:
                → REGRESSION HIGH: DB queries 11 (baseline: 4) — exceeds 5-query threshold
                → REGRESSION MEDIUM: Bundle +38KB (baseline: +12KB allowed)
                → REGRESSION HIGH: Lighthouse 71 (baseline: 83) — 12pt drop
                Ingests: [perf, regression, example-plugin, v2.5, db-queries-11, lighthouse-71]
                Routes to 01-PM with report.

01-PM           Creates fix ticket. Routes to 03-SrDev with orbit/06 context attached.

you → 03-SrDev  "Fix the performance regressions in example-plugin v2.5. Perf report attached."

03-SrDev        Brain Prime: loads orbit/06 regression + orbit/03 past perf fixes
                Diagnoses: N+1 in scroll-animation block → WP_Query post__in[]
                           Bundle: lodash imported wholesale → cherry-pick only needed methods
                Routes to 06-Performance for validation.

06-Performance  Re-benchmark: DB queries 3, bundle +4KB, Lighthouse 85. All pass.
                Updates orbit/06/example-plugin/budget for v2.5.
                Clears for 05-UAT.
```

---

### A5. Competitor intelligence → product decision

**Situation:** Elementor Kit ships AI Copilot. Should Orbit respond?

```
you → 00-CTO  "Elementor Kit just shipped an AI block generator. CTO brief."

00-CTO          Brain Prime: fan-out reads orbit/00-cto (decisions) + orbit/01-pm (roadmap)
                + orbit/07-security (any implications) + orbit/08-release (release health)
                Research via /deep-research + /orbit-pm-competitor-pulse
                Checks orbit/00-cto for prior competitor intel on Kit.

CTO BRIEF — Elementor Kit AI Copilot
Date: 2026-05-20
Signal:         Kit shipped in-editor AI block generation. WP.org reviews up 320 this week.
                example-plugin support board: 14 requests for "AI block help" in last 30 days.
Assessment:     Medium threat. High opportunity.
Recommendation: Differentiate — not copy. Our angle: AI block configuration assistant
                (help users configure existing blocks, not generate new ones). Lower effort,
                better fit for our user base (power users, not no-coders).
Owner:          01-PM runs RICE. 03-SrDev estimates effort. CTO revisits in 30 days.
Confidence:     Medium

00-CTO          Ingests: [cto, competitor, elementorkit, ai-copilot, differentiate-with-config, 2026-05]

you → 01-PM   "Assess the CTO brief on Elementor Kit AI. RICE it."

01-PM           RICE: Reach 9 / Impact 7 / Confidence 5 / Effort 7 = 45.
                Q3 roadmap. Monitors competitor reviews monthly via /orbit-pm-competitor-pulse.
```

---

### A6. New developer onboarded — no cold start

**Situation:** New WordPress developer joins the team. First day.

```
# Their Claude Code already has the Team key configured.
# Brain is seeded (40 drawers in orbit/00-cto/hard-rules/).

Developer types:  "What are the WP coding standards for this team?"
00-CTO brain:     Immediately surfaces: escaping rules, nonce patterns, capability checks,
                  approved patterns from past reviews, WP.org hard rules.

Developer types:  "What bugs does example-plugin v2.4 have that I should know about?"
05-UAT brain:     Surfaces v2.4 bug history, known flaky tests, severity-triaged open issues.

Developer types:  "Show me how code review works here."
02-CodeReviewer:  Runs a Brain Prime → shows approved patterns + redlines from past reviews.
                  "These are the patterns that got blocked in the last 3 audits."
```

**No onboarding doc needed.** The brain IS the onboarding.

---

## Table of contents (direct skill use cases — v2.x+)

- [For Developers (10 scenarios)](#for-developers)
- [For QA Engineers (5 scenarios)](#for-qa-engineers)
- [For Product Managers (5 scenarios)](#for-product-managers)
- [For Product Analysts (2 scenarios)](#for-product-analysts)
- [For Designers (2 scenarios)](#for-designers)
- [For Release Ops (3 scenarios)](#for-release-ops)

---

## For Developers

### D1. First run — validating a plugin you inherited

You just got access to a plugin codebase. Before touching anything, know what you're dealing with.

```bash
bash scripts/gauntlet-dry-run.sh
bash scripts/scaffold-tests.sh ~/plugins/inherited-plugin
cat scaffold-out/inherited-plugin/qa-scenarios.md
```

**Output:** 40-80 scenario doc + detected entry points + plugin type classification.

**Decision:** If the scenario count is in your expected range, proceed. If 3x what you expected, investigate — code may have dynamic registrations or undocumented features.

---

### D2. Pre-commit — catch obvious bugs before pushing

One-time install:
```bash
cd ~/plugins/my-plugin
bash ~/Claude/wordpress-qa-master/scripts/install-pre-commit-hook.sh
```

After install, every commit automatically runs: PHP lint on staged files, JSON validity, scratch-pattern detection (`var_dump`, `console.log DEBUG`, `debugger`), block.json apiVersion warning.

**Output:** Commit blocked if anything fails. <10 seconds.

**Decision:** Fix locally. `git commit --no-verify` is acceptable only for work-in-progress branches.

---

### D3. Daily development loop — after writing a feature

```bash
# Quick mode — skips the heavy AI audits + competitor + Lighthouse
bash scripts/gauntlet.sh --plugin . --mode quick
```

**Output:** PHP lint + PHPCS + PHPStan + Playwright + DB profile. ~3-5 min.

**Decision:** All pass → merge-ready. Any Critical/High → fix first.

---

### D4. Before a WP.org submission — full release gate

```bash
bash scripts/gauntlet.sh --plugin . --mode release
```

Runs all of Mode Quick plus: `plugin-check` (official WP.org tool), version parity, readme.txt validator, license compliance, ownership transfer detection, live CVE correlation, HPOS (if WC), block.json schema, WP function + PHP 8.x + modern WP compatibility.

**Output:** One report per release. WP.org submission-ready pass/fail.

**Decision:** Any FAIL → do not submit. WARN → review, decide per item.

---

### D5. Investigating a real-world bug — using /orbit-wp-security

A user reports "my plugin is showing a strange message". Rather than guess, run:

```bash
claude "/orbit-wp-security Audit /path/to/plugin for XSS and output escaping issues. Focus on files that echo user-provided data."
```

**Output:** Markdown report with file:line refs + severity rating for every unescaped output.

**Decision:** Critical/High findings → patch + release. Medium → ticket for next release.

---

### D6. Upgrading minimum PHP version

You want to drop PHP 7.4 support. First, check what you can now use:

```bash
bash scripts/check-php-compat.sh . # shows which newer PHP features already ship
```

Update header to `Requires PHP: 8.1` then re-run:
```bash
bash scripts/check-php-compat.sh . # shows what's now safe to use
```

**Output:** Opportunities and incompatibilities both listed.

**Decision:** Bump version, update readme, write upgrade notice. Notify existing users on older PHP before release.

---

### D7. After a WP core update released — compatibility check

WordPress 6.9 just shipped. Is your plugin ready?

```bash
bash scripts/check-wp-compat.sh .          # uses "Requires at least"
bash scripts/check-modern-wp.sh .          # WP 6.5-7.0 feature adoption
bash scripts/gauntlet.sh --plugin . --mode full  # full E2E against wp-env running 6.9
```

**Output:** Incompatible functions, modernization opportunities, real browser failures.

**Decision:** If Critical → patch + expedited release. If only "modernization opportunity" → add to next quarter's roadmap.

---

### D8. Reviewing an AI-assisted code contribution

A junior dev submitted a PR that was "Cursor-assisted". Before merging:

```bash
claude "/vibe-code-auditor Review the diff in this PR branch against main. Flag AI-specific risks: hallucinated WP functions, missing nonce checks, wrong sanitize function choice, incorrect WP_Error handling."
```

**Output:** Risk-ranked review specific to AI-generated patterns.

**Decision:** Review each flagged item by hand. AI-generated code has a 45% chance of OWASP top-10 vuln per Veracode — don't merge on auto-pass.

---

### D9. Debugging a flaky Playwright test

```bash
# Run just that test with full trace
npx playwright test flows/my-test.spec.js --project=chromium --trace on
npx playwright show-trace test-results/.../trace.zip
```

**Output:** Full interactive replay of the test.

**Decision:** If flaky due to parallelism → mark `test.describe.configure({ mode: 'serial' })`. If timing → use Playwright's auto-waiting, not hard `waitForTimeout`. If network → `page.route()` to mock.

---

### D10. Writing tests for a brand new feature

```bash
# 1. Scaffolder re-run picks up new entry points
bash scripts/scaffold-tests.sh ~/plugins/my-plugin

# 2. Diff against last scaffold
diff scaffold-out/my-plugin/qa-scenarios.md.last scaffold-out/my-plugin/qa-scenarios.md

# 3. For each new scenario, decide: smoke / business-logic / skip
```

Copy the business-logic scenario template from `docs/19-business-logic-guide.md` and write the spec.

---

## For QA Engineers

### Q1. Establishing coverage for a plugin you've never tested

```bash
bash scripts/scaffold-tests.sh ~/plugins/target-plugin --deep
```

The `--deep` flag invokes `/orbit-scaffold-tests` which reads the PHP and writes business-logic scenarios with file:line refs. You get:
- `qa-scenarios.md` — ~50 mechanical scenarios
- `ai-scenarios.md` — ~20 plugin-specific business-logic scenarios

**Output:** Starting test plan of 70 scenarios + draft Playwright smoke spec.

**Decision:** Review, cut what's not applicable, add 10-30 plugin-specific scenarios the scaffolder missed, turn into specs.

---

### Q2. Release candidate QA — the structured 4-hour pass

```bash
bash scripts/gauntlet.sh --plugin ~/plugins/my-plugin --mode full
python3 scripts/generate-reports-index.py --title "RC-$(date +%Y%m%d)"
open reports/index.html
```

Review every report tab. Attack every form with:
- Empty values
- Maximum-length values (255+ chars)
- Unicode (emoji, RTL chars, zero-width joiners)
- XSS payloads (`<script>`, `<img onerror>`)
- SQL payloads (`' OR 1=1--`)

**Output:** Full UAT HTML + skill audit HTML + screenshots + videos.

**Decision:** All Critical/High resolved → approve RC. Any remaining → send back with repro.

---

### Q3. Regression testing after a merge

```bash
# Compare current state against last release
PLUGIN_PREV_TAG=v1.5.0 npx playwright test --project=visual-release
```

**Output:** Screenshot diffs for every URL in `PLUGIN_VISUAL_URLS`.

**Decision:** >2% pixel difference = visual regression → bug. 0-2% = OK.

---

### Q4. Multi-version compatibility pass

```bash
# Run against PHP 7.4, 8.1, 8.3 in sequence
for php in 7.4 8.1 8.3; do
  WP_PHP_VERSION=$php bash scripts/gauntlet.sh --plugin . --mode full
  mv reports reports-$php
done
```

**Output:** Three report sets — compare.

**Decision:** Any PHP version fails → either fix forward or bump minimum in header.

---

### Q5. Plugin conflict matrix — before major release

```bash
PLUGIN_SLUG=my-plugin npx playwright test --project=conflict
```

Tests against top 20 most-installed plugins one at a time (Yoast, Rank Math, WooCommerce, Elementor, Jetpack, UpdraftPlus, W3 Total Cache, etc.).

**Output:** Pass/fail per competitor.

**Decision:** Fail with any top-5 plugin → critical, block release. Fail with top-20 (but not top-5) → warn users in upgrade notice.

---

## For Product Managers

### P1. Non-technical "is this release shippable?" decision in 5 minutes

```bash
# Have your dev run this and send the HTML link
bash scripts/gauntlet.sh --plugin ~/plugins/my-plugin --mode full
python3 scripts/generate-reports-index.py
```

Then you open `reports/index.html` in your browser. No terminal needed.

**What to check:**
1. **Top header severity bar** — any red "Critical" badge? Block release.
2. **Open `reports/skill-audits/index.html`** — scan each tab (Security, Performance, etc.) for Critical findings. Ask dev to address each.
3. **Open `reports/uat-report-*.html`** — watch 1-2 videos. If UI looks broken, ask QA to verify.

**Decision rule:** Zero Critical + zero High (or all reviewed with conscious dev sign-off) = ship. Any unaddressed = no.

---

### P2. Pre-launch sanity check for a beta user group

Before giving a plugin to 50 beta testers:

```bash
bash scripts/gauntlet.sh --plugin . --mode full
# Open:
open reports/playwright-html/index.html   # did functional tests pass?
open reports/uat-report-*.html             # what does the UI look like?
open reports/skill-audits/index.html       # any showstoppers?
```

**Decision:** All green → send to beta. Any yellow → send to beta with "known issues" list. Any red → fix first.

---

### P3. Measuring "time to first value" for new users

```bash
PLUGIN_SLUG=my-plugin \
PLUGIN_ADMIN_SLUG=my-plugin-settings \
PLUGIN_ONBOARDING_URL=/wp-admin/admin.php?page=my-plugin-onboarding \
PLUGIN_CORE_FEATURE_URL=/wp-admin/admin.php?page=my-plugin-main \
  npx playwright test --project=pm
```

**Output:** Console shows "Core feature reachable in N clicks".

**Decision:** N≤3 = good. N=4-5 = onboarding can be improved. N>5 = redesign the navigation.

---

### P4. "How does our v2.0 compare visually to v1.5?"

```bash
PLUGIN_PREV_TAG=v1.5.0 \
PLUGIN_VISUAL_URLS='["/wp-admin/admin.php?page=my-plugin","/wp-admin/admin.php?page=my-plugin-reports"]' \
  npx playwright test --project=visual-release
```

**Output:** Side-by-side diff images in `reports/screenshots/`.

**Decision:** Intentional redesigns → approve + commit new baseline. Accidental drift → back to dev.

---

### P5. Getting evidence for a release blocker

When a dev says "it's fine" and your gut says no:

```bash
claude "/orbit-wp-security Audit ~/plugins/my-plugin for all severity findings. Output a summary the non-technical reader can understand — no jargon."
```

**Output:** Plain-English security report.

**Decision:** If plain-English version includes words like "remote code execution" or "data exposure" — block release. If it says "minor improvement opportunity" — ship.

---

## For Product Analysts

### PA1. Verifying analytics events fire correctly

```bash
PLUGIN_ANALYTICS_EVENTS='[
  {"action":"click","selector":"#save-btn","expect_event":"plugin_save_clicked","endpoint_match":"google-analytics.com"},
  {"action":"click","selector":".upgrade-link","expect_event":"upgrade_cta_clicked","endpoint_match":"mixpanel"}
]' \
  npx playwright test --project=analytics
```

**Output:** Test passes only if the declared event actually hit the declared endpoint when the user took the action.

**Decision:** Any event missing → data pipeline bug. Tracking script not firing, selector changed, or consent mode blocking.

---

### PA2. Consent mode compliance

```bash
# Spec template in docs/19-business-logic-guide.md — you write a custom one
# that verifies tracking fires WITH consent + does NOT fire WITHOUT consent
```

**Output:** Assertions on `navigator.doNotTrack`, cookie banner state, GTM consent signals.

**Decision:** Must fire with consent AND must not fire without. Failure either way = GDPR risk.

---

## For Designers

### DS1. Visual baseline after a design refresh

After shipping a major UI redesign, set the new baseline:

```bash
# First run generates baselines
npx playwright test --project=visual --update-snapshots

# Commit the baselines
git add tests/playwright/visual/**/*.png
git commit -m "baseline: v2.0 design refresh"
```

**Output:** PNG baselines committed.

**Decision:** Every future visual regression compares against this.

---

### DS2. Auditing all 9 admin color schemes

```bash
PLUGIN_ADMIN_SLUG=my-plugin-settings npx playwright test --project=admin-colors
```

Runs through: default (fresh), light, modern, blue, coffee, ectoplasm, midnight, ocean, sunrise.

**Output:** Screenshots per scheme in `reports/screenshots/admin-colors/`.

**Decision:** Any scheme where plugin's primary button is invisible, text unreadable, or UI broken → fix the hardcoded color.

---

## For Release Ops

### R1. Day-of-release gate

```bash
# 1. Preflight
bash scripts/gauntlet-dry-run.sh

# 2. Release metadata gate (30 seconds)
bash scripts/check-plugin-header.sh .
bash scripts/check-readme-txt.sh .
bash scripts/check-version-parity.sh . v2.3.0

# 3. Full gauntlet
bash scripts/gauntlet.sh --plugin . --mode release

# 4. Evidence pack
python3 scripts/generate-reports-index.py --title "Release v2.3.0 — $(date)"
```

**Output:** One HTML report bundle = release evidence.

**Decision:** All pass → tag + push + update readme. Any fail → rollback branch, fix, re-run.

---

### R2. Verifying what's in the release zip

```bash
bash scripts/check-zip-hygiene.sh .
```

Flags dev artifacts (.git, .cursor, .github, .DS_Store, source maps, composer.json, package.json).

**Decision:** FAIL = regenerate zip excluding dev files. WARN = acceptable for commercial distribution, not for WP.org.

---

### R3. After release — monitor live CVE feed weekly

Add to your CI:
```bash
# Run weekly
bash scripts/check-live-cve.sh .
```

**Output:** Alert if your plugin matches any pattern from WP CVEs disclosed this week.

**Decision:** Any match → run `/orbit-wp-security` deep audit on the specific pattern. If exploitable → emergency patch release.

---

## Common patterns across use cases

### Always start with the dry-run
Every workflow benefits from `scripts/gauntlet-dry-run.sh` first — it catches
"command not found" and env config issues in 5 seconds instead of 5 minutes
into a real run.

### The 3 modes cheat sheet

| Mode | When | Time |
|---|---|---|
| `--mode quick` | After any code change during the day | 3-5 min |
| `--mode full` | Before creating a PR or beta release | 30-45 min |
| `--mode release` | Before tagging a release | 45-60 min |

### Always open `reports/index.html` first
Don't dig into individual report files. The master index links everything
with severity badges. Start there, drill down.

### When in doubt, run the deep-research skill
```bash
claude "/deep-research is there a new CVE pattern this week that affects my plugin type?"
```
Uses WebSearch/WebFetch to pull the current threat landscape — no API key
needed.

---

## Related docs

- [VISION.md](../VISION.md) — 6-perspective framework
- [docs/13-roles.md](13-roles.md) — deeper role workflows
- [docs/18-release-checklist.md](18-release-checklist.md) — the complete gate
- [docs/19-business-logic-guide.md](19-business-logic-guide.md) — custom test writing
- [docs/23-extending-orbit.md](23-extending-orbit.md) — adding new checks
