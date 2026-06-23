#!/usr/bin/env bash
# seed-runbooks.sh — seed the per-agent RUNBOOK drawers into the orbit brain.
#
# Makes BRAIN the live source of truth for which skills each agent runs (Golden Circle Rule -2):
# each agent reads its orbit/NN-role RUNBOOK drawer on spawn and runs that skill set end-to-end.
# New skills route automatically by re-seeding here — NO git pull, NO agent-file edit needed.
#
# Public-safe: the skill lists below are already published in the repo agent .md files.
# (Org-internal escalation/policy is seeded separately by brain/seed-ip-cleanroom.private.sh.)
#
#   bash brain/seed-runbooks.sh --key <orbit-admin-key>
#   bash brain/seed-runbooks.sh --key <key> --dry-run
set -euo pipefail

BRAIN_URL="https://brain.posimyth.com/connectors"
DRY_RUN=false
ADMIN_KEY=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --key)     ADMIN_KEY="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true;   shift   ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done
[[ -z "$ADMIN_KEY" ]] && { echo "ERROR: --key <orbit-admin-key> required (orbit tenant)."; exit 1; }
for dep in curl jq; do command -v "$dep" >/dev/null || { echo "ERROR: $dep required"; exit 1; }; done

ingest() { # namespace label body
  local namespace="$1" label="$2" body="$3"
  if $DRY_RUN; then echo "  [dry-run] $namespace ← $label"; return; fi
  local payload; payload=$(jq -n --arg body "$body" --arg ns "$namespace" \
    '{note: $body, namespace: $ns, tags: ["RUNBOOK","skill-routing","orbit", $ns]}')
  local status; status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BRAIN_URL/add_note" \
    -H "Authorization: Bearer $ADMIN_KEY" -H "Content-Type: application/json" -d "$payload")
  [[ "$status" == "200" || "$status" == "201" ]] && echo "  ✓ $namespace ← $label" || echo "  ✗ $label (HTTP $status)"
}

# Shared preamble injected into every RUNBOOK so the skip-rule travels with the routing.
RULE0='RUN RULE (Rule 0 — Smart-Agentic Mandate): run EVERY skill in this list end-to-end on every
invocation, in order. Conditional branches in the Process are escalation cues, not skip-gates. The
ONLY way to skip a skill is a brain note in this collection with a grep-verified reason. Build the
work-list via TaskCreate on spawn; end with a Coverage Report (skills-in-list == skills-run, else the
run is INVALID). Brain wins over the repo .md (Rule -2): this drawer is the source of truth for which
skills run — re-seed here to add/remove skills, no git pull needed.'

echo "🪐 Seeding per-agent RUNBOOK drawers into the orbit brain…"
$DRY_RUN && echo "   (dry run — no writes)"

ingest "orbit/00-cto" "CTO RUNBOOK" \
"RUNBOOK — 00-CTO (advise, never execute; reads ALL collections).
SKILL SET (run order): /orbit-pm-competitor-pulse → /orbit-competitor-compare → /orbit-mcp-discover →
/orbit-evergreen-update → /orbit-skill-add → /orbit-skill-improver → /deep-research →
/competitive-landscape → /context7-auto-research.
$RULE0"

ingest "orbit/01-pm" "PM RUNBOOK" \
"RUNBOOK — 01-PM (routes work to 02–10; continuous coverage even with no PR open).
SKILL SET (run order): /orbit-pm-rice → /orbit-pm-roadmap → /orbit-pm-feedback-mining →
/orbit-pm-competitor-pulse → /orbit-pm-ux-audit → /orbit-competitor-compare → /orbit-version-compare.
ROUTING: every cycle also dispatches 07-security + 05-uat + 02-code-reviewer + 06-performance to run
their full skill sweep on current plugin state.
$RULE0"

ingest "orbit/02-code-reviewer" "Code Reviewer RUNBOOK" \
"RUNBOOK — 02-Code-Reviewer (baseline runs on every PR regardless of size).
SKILL SET (run order): /orbit-wp-standards → /orbit-code-quality → /orbit-block-json-validate →
/orbit-gutenberg-dev → /orbit-elementor-dev → /orbit-elementor-compat → /orbit-elementor-controls →
/orbit-elementor-skins → /orbit-elementor-dynamic-tags → /orbit-compat-matrix → /orbit-compat-polylang →
/orbit-compat-wpml → /orbit-i18n-runtime → /orbit-i18n-js-parity → /orbit-ip-cleanroom (flag leaks) →
/orbit-cron-audit → /orbit-life-activation → /orbit-life-upgrade → /orbit-uninstall-test →
/orbit-multisite → /orbit-cache-compat. Plus §10 runtime-trap manual checks.
$RULE0"

ingest "orbit/03-senior-dev" "Senior Dev RUNBOOK" \
"RUNBOOK — 03-SrDev (builds; 02 approves before merge).
SKILL SET (run order): /orbit-wp-standards → /orbit-wp-database → /orbit-gutenberg-dev →
/orbit-elementor-dev → /orbit-block-json-validate → /orbit-interactivity-api → /orbit-i18n →
/orbit-docker-site. Baseline implementation checklist (escaping, nonces, prepare(), wp_unslash,
i18n incl. JSON_UNESCAPED_UNICODE, §10 traps) runs regardless of how the change looks.
$RULE0"

ingest "orbit/04-dev-designer" "Dev Designer RUNBOOK" \
"RUNBOOK — 04-DevDesigner (WCAG 2.2 AA on everything visible; specs design, 03 implements).
SKILL SET (run order): /orbit-accessibility → /orbit-designer-rtl → /orbit-designer-dark-mode →
/orbit-designer-empty-error → /orbit-designer-icons → /orbit-designer-tokens → /orbit-i18n →
/orbit-i18n-runtime → /orbit-i18n-js-parity → /orbit-i18n-translator-currency.
$RULE0"

ingest "orbit/05-uat" "UAT RUNBOOK" \
"RUNBOOK — 05-UAT (Docker clean install, real flows; also orchestrates 02/06/07/04 in parallel).
SKILL SET (run order): /orbit-docker-site → /orbit-wp-playground → /orbit-scaffold-tests →
/orbit-playwright → /orbit-uat-agent → /orbit-uat-gutenberg → /orbit-uat-elementor → /orbit-uat-woo →
/orbit-uat-forms → /orbit-uat-membership → /orbit-user-flow → /orbit-visual-regression →
/orbit-qa-flaky-detector → /orbit-qa-coverage → /orbit-qa-regression-pack → /orbit-qa-snapshot-cleanup →
/orbit-uat-compare → /orbit-reports. Targeted mode narrows the REPORT, not the skill set.
$RULE0"

ingest "orbit/06-performance" "Performance RUNBOOK" \
"RUNBOOK — 06-Performance (always vs a baseline).
SKILL SET (run order): /orbit-wp-performance → /orbit-db-profile → /orbit-bundle-analysis →
/orbit-editor-perf → /orbit-lighthouse → /orbit-seo-page-speed → /orbit-perf-cdn →
/orbit-perf-stress-test → /orbit-perf-memory-leak. All run regardless of what changed in the PR.
$RULE0"

ingest "orbit/07-security" "Security RUNBOOK" \
"RUNBOOK — 07-Security (owns IP clean-room; baseline always runs; active fuzzing staging-only).
SKILL SET (run order): /orbit-sec-secrets-leak → /orbit-wp-security → /orbit-broken-access-control →
/orbit-sec-supply-chain → /orbit-cve-check → /orbit-vdp → /orbit-ip-cleanroom → /orbit-gdpr →
/orbit-premium-audit → /orbit-pay-stripe → /orbit-pay-freemius → /orbit-pay-paypal →
/orbit-cron-audit → (staging only, operator-confirmed) /orbit-sec-xss-active → /orbit-ajax-fuzzer →
/orbit-rest-fuzzer. Payment/GDPR/premium run additionally when their surface exists.
See the orbit/07-security ip-cleanroom RUNBOOK drawer for IP escalation policy.
$RULE0"

ingest "orbit/08-release" "Release RUNBOOK" \
"RUNBOOK — 08-Release (8-step hard gate, in order, no exceptions).
GATE ORDER: 1 /orbit-pre-commit → 2 /orbit-release-meta → 3 /orbit-plugin-check →
4 /orbit-changelog-test → 5 /orbit-version-compare → 6 /orbit-zip-hygiene →
7 /orbit-i18n (+ /orbit-i18n-runtime + /orbit-i18n-js-parity + /orbit-i18n-translator-currency) →
8 /orbit-ip-cleanroom. Any fail blocks release. Then /orbit-pm-release-notes.
See orbit/08-release/gates for the IP clean-room gate definition.
$RULE0"

ingest "orbit/09-docs" "Docs RUNBOOK" \
"RUNBOOK — 09-Docs (docs ship WITH the release, never after).
SKILL SET (run order): /orbit-release-meta → /orbit-i18n → /orbit-i18n-translator-currency →
/orbit-abilities-api → /orbit-pm-release-notes. README + changelog + screenshots + i18n string
coverage + RTL screenshots + translator-context comments all run every release.
$RULE0"

ingest "orbit/10-runner" "Runner RUNBOOK" \
"RUNBOOK — 10-Runner (executes the work-list other agents queue; never skips a queued skill silently).
SKILL SET (run order): /orbit-docker-site → /orbit-install → /orbit-setup → /orbit-update →
/orbit-playwright → wp-env matrix → PHPUnit/PHPCS/WPCS → WP-CLI ops → conflict scan → test gate.
On a skill start-failure: log to this collection and CONTINUE with the rest. End with a Coverage
Report listing every queued skill + exit code.
$RULE0"

echo ""
echo "🪐 Done. 11 per-agent RUNBOOK drawers live in the orbit brain."
echo "   Agents now read their skill set + run order from brain on every spawn (Rule -2)."
echo "   To add/remove a skill for an agent: edit the list here and re-run — no git pull needed."
