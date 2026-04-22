#!/usr/bin/env bash
# Orbit — PM UX Audit
# Runs three PM-perspective checks and generates a consolidated report.
#
# Checks:
#   1. Spell-Check Scan      — typos in labels, buttons, tooltips, notices
#   2. Guided Experience     — wizard, tooltips, inline help, empty-state score (0–10)
#   3. Label & Terminology   — anti-patterns + competitor benchmarking
#
# Usage:
#   bash scripts/pm-ux-audit.sh [--url http://localhost:8881] [--slug your-plugin-slug]
#
# Output:
#   reports/pm-ux/spell-check-findings.json
#   reports/pm-ux/guided-ux-score.json
#   reports/pm-ux/label-audit-findings.json
#   reports/pm-ux/pm-ux-report-<timestamp>.html

set -euo pipefail

WP_URL="${WP_TEST_URL:-http://localhost:8881}"
ADMIN_SLUG=""
REPORT_DIR="reports/pm-ux"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
PW_CONFIG="tests/playwright/playwright.config.js"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

ok()     { echo -e "${GREEN}  ✓ $1${NC}"; }
warn()   { echo -e "${YELLOW}  ⚠ $1${NC}"; }
fail()   { echo -e "${RED}  ✗ $1${NC}"; }
info()   { echo -e "${CYAN}    $1${NC}"; }

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --url)  WP_URL="$2"; shift ;;
    --slug) ADMIN_SLUG="$2"; shift ;;
  esac
  shift
done

# Read slug from qa.config.json if not provided
if [ -z "$ADMIN_SLUG" ] && [ -f "qa.config.json" ]; then
  ADMIN_SLUG=$(python3 -c "import json; print(json.load(open('qa.config.json'))['plugin'].get('admin_slug',''))" 2>/dev/null || echo "")
fi

mkdir -p "$REPORT_DIR"

echo ""
echo -e "${BOLD}[ PM UX Audit ]${NC}"
echo -e "  URL: ${YELLOW}$WP_URL${NC} | Slug: ${YELLOW}${ADMIN_SLUG:-auto-discover}${NC}"
echo ""

if ! command -v npx &>/dev/null; then
  echo "npx not found — install Node.js first"
  exit 1
fi

OVERALL_EXIT=0

# ── 1. Spell-Check Scan ───────────────────────────────────────────────────────
echo -e "${BOLD}  1/3 Spell-Check Scan${NC}"
SPELL_OUT=$(WP_TEST_URL="$WP_URL" PLUGIN_ADMIN_SLUG="$ADMIN_SLUG" \
  npx playwright test tests/playwright/pm/spell-check.spec.js \
  --config="$PW_CONFIG" --project=chromium --reporter=line 2>&1 || true)

SPELL_FILE="$REPORT_DIR/spell-check-findings.json"
if [ -f "$SPELL_FILE" ]; then
  TYPO_COUNT=$(python3 -c "import json; d=json.load(open('$SPELL_FILE')); print(len(d.get('findings',[])))" 2>/dev/null || echo "?")
  PAGES_SCANNED=$(python3 -c "import json; d=json.load(open('$SPELL_FILE')); print(d.get('pagesScanned',0))" 2>/dev/null || echo "?")
  if [ "$TYPO_COUNT" = "0" ]; then
    ok "No typos found ($PAGES_SCANNED page(s) scanned)"
  elif [ "$TYPO_COUNT" = "?" ]; then
    warn "Spell-check ran but couldn't read results"
  else
    warn "$TYPO_COUNT typo(s) found — see $SPELL_FILE"
    OVERALL_EXIT=1
  fi
else
  warn "Spell-check skipped — no plugin pages found (set PLUGIN_ADMIN_SLUG)"
fi

# ── 2. Guided Experience Score ────────────────────────────────────────────────
echo ""
echo -e "${BOLD}  2/3 Guided Experience Score${NC}"
WP_TEST_URL="$WP_URL" PLUGIN_ADMIN_SLUG="$ADMIN_SLUG" \
  npx playwright test tests/playwright/pm/guided-ux.spec.js \
  --config="$PW_CONFIG" --project=chromium --reporter=line 2>&1 | tail -15 || true

GUIDED_FILE="$REPORT_DIR/guided-ux-score.json"
if [ -f "$GUIDED_FILE" ]; then
  SCORE=$(python3 -c "import json; print(json.load(open('$GUIDED_FILE'))['score'])" 2>/dev/null || echo "?")
  COMP_AVG=$(python3 -c "import json; print(json.load(open('$GUIDED_FILE'))['competitorAverage'])" 2>/dev/null || echo "?")
  MISSING=$(python3 -c "import json; print(len(json.load(open('$GUIDED_FILE'))['missingSignals']))" 2>/dev/null || echo "?")
  if [ "$SCORE" != "?" ] && [ "$SCORE" -ge "$COMP_AVG" ] 2>/dev/null; then
    ok "Guidance score: $SCORE/10 (competitor avg: $COMP_AVG/10)"
  elif [ "$SCORE" != "?" ]; then
    warn "Guidance score: $SCORE/10 — below competitor avg of $COMP_AVG/10 ($MISSING signals missing)"
    OVERALL_EXIT=1
  fi
else
  warn "Guided UX check skipped"
fi

# ── 3. Label & Terminology Audit ──────────────────────────────────────────────
echo ""
echo -e "${BOLD}  3/3 Label & Terminology Audit${NC}"
WP_TEST_URL="$WP_URL" PLUGIN_ADMIN_SLUG="$ADMIN_SLUG" \
  npx playwright test tests/playwright/pm/label-audit.spec.js \
  --config="$PW_CONFIG" --project=chromium --reporter=line 2>&1 | tail -20 || true

LABEL_FILE="$REPORT_DIR/label-audit-findings.json"
if [ -f "$LABEL_FILE" ]; then
  TOTAL=$(python3 -c "import json; print(json.load(open('$LABEL_FILE'))['summary']['total'])" 2>/dev/null || echo "?")
  HIGH=$(python3 -c "import json; d=json.load(open('$LABEL_FILE')); print(sum(1 for f in d.get('antiPatterns',[]) if f.get('severity')=='high'))" 2>/dev/null || echo "0")
  if [ "$TOTAL" = "0" ]; then
    ok "Labels match industry standards — no issues"
  elif [ "$HIGH" != "0" ] && [ "$HIGH" != "?" ]; then
    fail "$TOTAL label issue(s) ($HIGH high severity) — see $LABEL_FILE"
    OVERALL_EXIT=1
  else
    warn "$TOTAL label issue(s) (no high severity) — see $LABEL_FILE"
    OVERALL_EXIT=1
  fi
else
  warn "Label audit skipped"
fi

# ── HTML Report ───────────────────────────────────────────────────────────────
echo ""
HTML_REPORT="$REPORT_DIR/pm-ux-report-$TIMESTAMP.html"
python3 scripts/generate-pm-ux-report.py \
  --spell   "$REPORT_DIR/spell-check-findings.json" \
  --guided  "$REPORT_DIR/guided-ux-score.json" \
  --labels  "$REPORT_DIR/label-audit-findings.json" \
  --out     "$HTML_REPORT" 2>/dev/null && {
  ok "PM UX report: $HTML_REPORT"
  info "Open with: open $(pwd)/$HTML_REPORT"
} || {
  warn "HTML report generation failed — raw JSON in $REPORT_DIR/"
}

echo ""
if [ "$OVERALL_EXIT" -eq 0 ]; then
  echo -e "${GREEN}${BOLD}  PM UX Audit — PASSED${NC}"
else
  echo -e "${YELLOW}${BOLD}  PM UX Audit — ISSUES FOUND (PM review required)${NC}"
fi
echo ""

exit $OVERALL_EXIT
