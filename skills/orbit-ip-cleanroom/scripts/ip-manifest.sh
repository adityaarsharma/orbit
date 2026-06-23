#!/usr/bin/env bash
# ip-manifest.sh — emit an IP clean-room provenance manifest (JSON) to stdout.
# Usage: ip-manifest.sh <target> <run-dir> [reference-id] [pinned-version] [model]
# Fill the placeholder fields by hand/agent afterwards (separation, scans, chronology).
#
# Engineering risk-reduction record. NOT legal advice; no safe harbor.
set -uo pipefail

TARGET="${1:-.}"
RUNDIR="${2:-.clean-room/run}"
REF_ID="${3:-<reference name or url>}"
PINNED="${4:-<sha|version|date>}"
MODEL="${5:-<model name & version>}"

NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo '<ISO-8601>')"

LIC="<detected license>"
if command -v rg >/dev/null 2>&1; then
  LIC="$(rg -o -i -m1 -e 'SPDX-License-Identifier: *[A-Za-z0-9.\-]+' "$TARGET" 2>/dev/null | head -1 || true)"
  [[ -z "$LIC" ]] && LIC="<detected license>"
fi

cat <<JSON
{
  "schema": "orbit-ip-cleanroom-manifest/v1",
  "generated_at": "$NOW",
  "target": "$TARGET",
  "reference": {
    "identity": "$REF_ID",
    "pinned_version": "$PINNED",
    "license": "$LIC"
  },
  "modes_run": ["<intake|audit|reimplement>"],
  "separation": {
    "saw_reference": ["discovery-agent"],
    "source_denied": ["implementation-agent (separate session recommended)"]
  },
  "ai": {
    "tool": "Claude Code (Orbit)",
    "model": "$MODEL",
    "instruction": "Do not base output on copyleft (GPL/AGPL/LGPL/MPL) code or the reference's expression"
  },
  "scans": {
    "leak_report": "$RUNDIR/leak-report.txt",
    "reserved_identifiers": "$RUNDIR/reserved-identifiers.txt",
    "similarity": { "tool": "<JPlag|Moss>", "score": "<X%>" }
  },
  "chronology": [
    {"step": "intake",        "at": "<ts>"},
    {"step": "specification", "at": "<ts>"},
    {"step": "spec_review",   "at": "<ts>", "reviewer": "<name>"},
    {"step": "implementation","at": "<ts>"},
    {"step": "verification",  "at": "<ts>"}
  ],
  "files": [
    {"path": "<path>", "ai_involved": true, "license_scan": "clean", "origin": "<reimplemented|original|scrubbed>"}
  ],
  "trademark_cleared": "<yes|no|pending>",
  "third_party_notices_shipped": "<yes|no>",
  "disclaimer": "Engineering risk-reduction record. Not legal advice; no safe harbor. Clean room defeats copyright, not patents."
}
JSON
