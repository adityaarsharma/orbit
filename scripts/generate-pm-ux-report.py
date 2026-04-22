#!/usr/bin/env python3
"""
Orbit — PM UX Report Generator
Combines spell-check, guided UX, and label audit findings into one HTML report.

Usage:
  python3 scripts/generate-pm-ux-report.py \
    --spell  reports/pm-ux/spell-check-findings.json \
    --guided reports/pm-ux/guided-ux-score.json \
    --labels reports/pm-ux/label-audit-findings.json \
    --out    reports/pm-ux/pm-ux-report-<timestamp>.html
"""

import argparse
import json
import sys
from datetime import datetime
from pathlib import Path

# ── CLI args ──────────────────────────────────────────────────────────────────
parser = argparse.ArgumentParser()
parser.add_argument('--spell',  default='')
parser.add_argument('--guided', default='')
parser.add_argument('--labels', default='')
parser.add_argument('--out',    default='reports/pm-ux/pm-ux-report.html')
args = parser.parse_args()


def load(path):
    if not path or not Path(path).exists():
        return None
    try:
        return json.loads(Path(path).read_text())
    except Exception:
        return None


spell_data  = load(args.spell)
guided_data = load(args.guided)
label_data  = load(args.labels)

now = datetime.now().strftime('%Y-%m-%d %H:%M')


# ── Helpers ───────────────────────────────────────────────────────────────────
def severity_badge(sev):
    colors = {'high': '#e53e3e', 'medium': '#dd6b20', 'low': '#718096', 'info': '#3182ce'}
    c = colors.get(sev, '#718096')
    return f'<span style="background:{c};color:#fff;padding:2px 6px;border-radius:3px;font-size:11px;font-weight:600">{sev.upper()}</span>'


def score_bar(score, max_score=10):
    pct     = (score / max_score) * 100
    color   = '#38a169' if score >= 7 else '#dd6b20' if score >= 4 else '#e53e3e'
    return f'''
    <div style="display:flex;align-items:center;gap:10px">
      <div style="flex:1;background:#e2e8f0;border-radius:4px;height:18px">
        <div style="width:{pct}%;background:{color};height:100%;border-radius:4px;transition:width .3s"></div>
      </div>
      <strong style="font-size:20px;color:{color}">{score}<span style="font-size:14px;color:#718096">/{max_score}</span></strong>
    </div>'''


# ── Spell-Check section ───────────────────────────────────────────────────────
def spell_section():
    if not spell_data:
        return '<p style="color:#718096">Spell-check data not available.</p>'

    findings     = spell_data.get('findings', [])
    pages_scanned = spell_data.get('pagesScanned', 0)
    count        = len(findings)
    status_color = '#38a169' if count == 0 else '#e53e3e' if count >= 5 else '#dd6b20'
    status_text  = 'CLEAN' if count == 0 else f'{count} TYPO(S) FOUND'

    rows = ''
    for f in findings:
        rows += f'''
        <tr>
          <td style="color:#e53e3e;font-weight:600">❌ {f.get("typo","")}</td>
          <td style="color:#38a169">→ {f.get("suggestion","")}</td>
          <td style="color:#4a5568">{f.get("element","")}</td>
          <td style="font-size:12px;color:#718096;max-width:280px;overflow:hidden">{f.get("context","")[:70]}…</td>
          <td style="font-size:11px;color:#a0aec0;max-width:200px;word-break:break-all">{f.get("page","")}</td>
        </tr>'''

    table = f'''
    <table style="width:100%;border-collapse:collapse;font-size:13px;margin-top:12px">
      <thead style="background:#f7fafc">
        <tr>
          <th style="padding:8px;text-align:left;border-bottom:1px solid #e2e8f0">Typo</th>
          <th style="padding:8px;text-align:left;border-bottom:1px solid #e2e8f0">Suggestion</th>
          <th style="padding:8px;text-align:left;border-bottom:1px solid #e2e8f0">Element Type</th>
          <th style="padding:8px;text-align:left;border-bottom:1px solid #e2e8f0">Context</th>
          <th style="padding:8px;text-align:left;border-bottom:1px solid #e2e8f0">Page</th>
        </tr>
      </thead>
      <tbody>{rows if rows else "<tr><td colspan='5' style='padding:12px;color:#38a169;text-align:center'>✓ No typos found</td></tr>"}</tbody>
    </table>''' if findings else '<p style="color:#38a169;margin-top:8px">✓ No typos detected.</p>'

    return f'''
    <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:12px">
      <div>
        <span style="font-size:24px;font-weight:700;color:{status_color}">{status_text}</span>
        <span style="color:#718096;margin-left:8px;font-size:13px">{pages_scanned} page(s) scanned</span>
      </div>
    </div>
    {table}
    <p style="margin-top:10px;font-size:12px;color:#a0aec0">
      Run cspell for deeper check: <code>npx cspell --config config/pm-ux/cspell.json reports/pm-ux/extracted-ui-text.txt</code>
    </p>'''


# ── Guided UX section ─────────────────────────────────────────────────────────
def guided_section():
    if not guided_data:
        return '<p style="color:#718096">Guided UX data not available.</p>'

    score       = guided_data.get('score', 0)
    comp_avg    = guided_data.get('competitorAverage', 7)
    present     = guided_data.get('presentSignals', [])
    missing     = guided_data.get('missingSignals', [])
    naked       = guided_data.get('nakedInputsWithNoHelp', 0)
    comparisons = guided_data.get('competitorComparison', [])

    present_rows = ''.join(
        f'<li style="color:#38a169;margin:4px 0">✓ <strong>{p["label"]}</strong> (+{p["points"]}pt)</li>'
        for p in present
    )
    missing_rows = ''.join(
        f'''<li style="margin:8px 0;border-left:3px solid #e53e3e;padding-left:10px">
          <strong style="color:#e53e3e">{m["label"]}</strong> (+{m["points"]}pt if added)<br>
          <span style="font-size:12px;color:#4a5568">{m["description"]}</span><br>
          <span style="font-size:12px;color:#3182ce">→ {m["example"]}</span>
        </li>'''
        for m in missing
    )

    comp_rows = ''.join(
        f'''<tr>
          <td style="padding:6px 10px">{c["competitor"]}</td>
          <td style="padding:6px 10px;text-align:center">
            <strong style="color:{"#38a169" if c["score"] <= score else "#e53e3e"}">{c["score"]}/10</strong>
          </td>
          <td style="padding:6px 10px;color:{"#e53e3e" if c["ahead"] else "#38a169"}">
            {"▲ ahead by " + str(c["gap"]) if c["ahead"] else "▼ behind"}
          </td>
        </tr>'''
        for c in comparisons
    )

    return f'''
    <div style="display:grid;grid-template-columns:1fr 1fr;gap:20px;margin-bottom:20px">
      <div>
        <p style="font-size:13px;color:#4a5568;margin-bottom:8px">Your guidance score vs competitor average ({comp_avg}/10)</p>
        {score_bar(score)}
      </div>
      <div style="background:#f7fafc;padding:12px;border-radius:6px">
        <p style="font-size:12px;color:#718096;margin:0 0 6px">What top plugins include that yours {"doesn't" if missing else "does too"}:</p>
        <ul style="margin:0;padding-left:0;list-style:none">
          {present_rows}
        </ul>
      </div>
    </div>
    {"<div style='background:#fff5f5;border:1px solid #fed7d7;border-radius:6px;padding:14px;margin-bottom:16px'><p style='margin:0 0 8px;font-weight:600;color:#742a2a'>Missing guidance signals:</p><ul style='margin:0;padding-left:0;list-style:none'>" + missing_rows + "</ul></div>" if missing else ""}
    {"<div style='background:#fffbf0;border:1px solid #f6e05e;border-radius:6px;padding:10px;margin-bottom:16px;font-size:13px;color:#744210'><strong>⚠ " + str(naked) + " input field(s)</strong> have no placeholder text AND no description text beneath them. Users have zero context for what to type.</div>" if naked > 0 else ""}
    <table style="width:100%;border-collapse:collapse;font-size:13px">
      <thead style="background:#f7fafc">
        <tr>
          <th style="padding:8px;text-align:left;border-bottom:1px solid #e2e8f0">Competitor</th>
          <th style="padding:8px;text-align:center;border-bottom:1px solid #e2e8f0">Score</th>
          <th style="padding:8px;text-align:left;border-bottom:1px solid #e2e8f0">vs You</th>
        </tr>
      </thead>
      <tbody>{comp_rows}</tbody>
    </table>'''


# ── Label Audit section ───────────────────────────────────────────────────────
def label_section():
    if not label_data:
        return '<p style="color:#718096">Label audit data not available.</p>'

    summary   = label_data.get('summary', {})
    anti      = label_data.get('antiPatterns', [])
    comp_terms = label_data.get('competitorTerms', [])
    opt_order = label_data.get('optionOrdering', [])
    total     = summary.get('total', 0)

    def render_findings(items, max_show=10):
        if not items:
            return '<p style="color:#38a169">✓ None found.</p>'
        rows = ''
        for f in items[:max_show]:
            sev = f.get('severity', 'medium')
            rows += f'''
            <tr style="border-bottom:1px solid #f0f0f0">
              <td style="padding:8px">{severity_badge(sev)}</td>
              <td style="padding:8px;color:#4a5568;font-size:12px">{f.get("element","")}</td>
              <td style="padding:8px;font-family:monospace;background:#f7fafc;border-radius:3px;font-size:12px">"{f.get("text","")}"</td>
              <td style="padding:8px;font-size:12px;color:#2d3748">{f.get("message","")}</td>
              <td style="padding:8px;font-size:11px;color:#3182ce">{f.get("competitors","")}</td>
            </tr>'''
        if len(items) > max_show:
            rows += f'<tr><td colspan="5" style="padding:8px;color:#718096;text-align:center">… and {len(items)-max_show} more — see label-audit-findings.json</td></tr>'
        return f'''
        <table style="width:100%;border-collapse:collapse;font-size:13px">
          <thead style="background:#f7fafc">
            <tr>
              <th style="padding:8px;text-align:left;border-bottom:1px solid #e2e8f0">Severity</th>
              <th style="padding:8px;text-align:left;border-bottom:1px solid #e2e8f0">Type</th>
              <th style="padding:8px;text-align:left;border-bottom:1px solid #e2e8f0">Found</th>
              <th style="padding:8px;text-align:left;border-bottom:1px solid #e2e8f0">Issue</th>
              <th style="padding:8px;text-align:left;border-bottom:1px solid #e2e8f0">Competitor note</th>
            </tr>
          </thead>
          <tbody>{rows}</tbody>
        </table>'''

    opt_rows = ''.join(
        f'''<div style="background:#fffbf0;border:1px solid #f6e05e;border-radius:5px;padding:10px;margin-bottom:8px;font-size:13px">
          <strong>{o.get("label","")}</strong><br>
          Current: [{", ".join(o.get("found",[]))}]<br>
          Suggested: <span style="color:#38a169">[{", ".join(o.get("suggested",[]))}]</span><br>
          <span style="color:#3182ce;font-size:12px">→ {o.get("competitor","")}</span>
        </div>'''
        for o in opt_order
    ) if opt_order else '<p style="color:#38a169">✓ All option orderings look logical.</p>'

    comp_rows_html = ''
    for f in comp_terms[:8]:
        comp_rows_html += f'''
        <tr style="border-bottom:1px solid #f0f0f0">
          <td style="padding:8px;font-size:12px;color:#4a5568">{f.get("element","")}</td>
          <td style="padding:8px;font-family:monospace;font-size:12px;background:#f7fafc">"{f.get("found","")}"</td>
          <td style="padding:8px;font-size:12px;color:#38a169">→ "{f.get("standard","")}"</td>
          <td style="padding:8px;font-size:12px;color:#718096">{f.get("usedBy","")}</td>
        </tr>'''

    comp_table = f'''
    <table style="width:100%;border-collapse:collapse;font-size:13px">
      <thead style="background:#f7fafc">
        <tr>
          <th style="padding:8px;text-align:left;border-bottom:1px solid #e2e8f0">Element</th>
          <th style="padding:8px;text-align:left;border-bottom:1px solid #e2e8f0">Your label</th>
          <th style="padding:8px;text-align:left;border-bottom:1px solid #e2e8f0">Industry standard</th>
          <th style="padding:8px;text-align:left;border-bottom:1px solid #e2e8f0">Used by</th>
        </tr>
      </thead>
      <tbody>{comp_rows_html if comp_rows_html else "<tr><td colspan='4' style='padding:10px;color:#38a169;text-align:center'>✓ Terminology matches industry standards</td></tr>"}</tbody>
    </table>''' if comp_terms else '<p style="color:#38a169">✓ All labels match competitor terminology.</p>'

    return f'''
    <div style="display:flex;gap:12px;margin-bottom:16px">
      <div style="background:#f7fafc;border-radius:6px;padding:12px;flex:1;text-align:center">
        <div style="font-size:28px;font-weight:700;color:{"#e53e3e" if summary.get("antiPatternCount",0)>0 else "#38a169"}">{summary.get("antiPatternCount",0)}</div>
        <div style="font-size:12px;color:#718096">Anti-patterns</div>
      </div>
      <div style="background:#f7fafc;border-radius:6px;padding:12px;flex:1;text-align:center">
        <div style="font-size:28px;font-weight:700;color:{"#dd6b20" if summary.get("competitorTermCount",0)>0 else "#38a169"}">{summary.get("competitorTermCount",0)}</div>
        <div style="font-size:12px;color:#718096">Non-standard terms</div>
      </div>
      <div style="background:#f7fafc;border-radius:6px;padding:12px;flex:1;text-align:center">
        <div style="font-size:28px;font-weight:700;color:{"#dd6b20" if summary.get("optionOrderCount",0)>0 else "#38a169"}">{summary.get("optionOrderCount",0)}</div>
        <div style="font-size:12px;color:#718096">Option order issues</div>
      </div>
    </div>

    <h4 style="margin:16px 0 8px;color:#2d3748">Anti-pattern findings</h4>
    {render_findings(anti)}

    <h4 style="margin:16px 0 8px;color:#2d3748">Terminology vs competitors</h4>
    {comp_table}

    <h4 style="margin:16px 0 8px;color:#2d3748">Option ordering</h4>
    {opt_rows}'''


# ── Final HTML ────────────────────────────────────────────────────────────────
def section_card(title, icon, content, count=None, status='ok'):
    badge_color = {'ok': '#38a169', 'warn': '#dd6b20', 'error': '#e53e3e'}.get(status, '#718096')
    badge = f'<span style="margin-left:8px;background:{badge_color};color:#fff;border-radius:10px;padding:2px 9px;font-size:12px">{count}</span>' if count is not None else ''
    return f'''
    <div style="background:#fff;border:1px solid #e2e8f0;border-radius:8px;padding:20px;margin-bottom:24px">
      <h3 style="margin:0 0 16px;color:#1a202c;font-size:17px">{icon} {title}{badge}</h3>
      {content}
    </div>'''


spell_count  = len(spell_data.get('findings', [])) if spell_data else 0
guided_score = guided_data.get('score', 0) if guided_data else 0
label_count  = label_data.get('summary', {}).get('total', 0) if label_data else 0

html = f'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Orbit PM UX Report — {now}</title>
  <style>
    *, *::before, *::after {{ box-sizing: border-box; }}
    body {{ font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; margin: 0; background: #f8fafc; color: #2d3748; line-height: 1.5; }}
    .header {{ background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: #fff; padding: 32px 40px; }}
    .header h1 {{ margin: 0 0 6px; font-size: 26px; }}
    .header p {{ margin: 0; opacity: .8; font-size: 14px; }}
    .container {{ max-width: 1100px; margin: 0 auto; padding: 30px 24px; }}
    .summary {{ display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; margin-bottom: 28px; }}
    .summary-card {{ background: #fff; border-radius: 8px; padding: 18px; text-align: center; border: 1px solid #e2e8f0; }}
    .summary-card .num {{ font-size: 36px; font-weight: 700; }}
    .summary-card .label {{ font-size: 12px; color: #718096; margin-top: 4px; }}
    code {{ background: #edf2f7; padding: 1px 5px; border-radius: 3px; font-size: 12px; }}
  </style>
</head>
<body>
<div class="header">
  <h1>🪐 Orbit — PM UX Audit Report</h1>
  <p>Generated: {now} &nbsp;·&nbsp; Checks: Spell-Check · Guided Experience · Label Audit</p>
</div>
<div class="container">

  <div class="summary">
    <div class="summary-card">
      <div class="num" style="color:{"#38a169" if spell_count==0 else "#e53e3e"}">{spell_count}</div>
      <div class="label">Typos found</div>
    </div>
    <div class="summary-card">
      <div class="num" style="color:{"#38a169" if guided_score>=7 else "#dd6b20" if guided_score>=4 else "#e53e3e"}">{guided_score}<small style="font-size:18px;color:#a0aec0">/10</small></div>
      <div class="label">Guidance score</div>
    </div>
    <div class="summary-card">
      <div class="num" style="color:{"#38a169" if label_count==0 else "#dd6b20" if label_count<5 else "#e53e3e"}">{label_count}</div>
      <div class="label">Label issues</div>
    </div>
  </div>

  {section_card("Spell-Check Scan", "🔤",
    spell_section(),
    count=spell_count,
    status='ok' if spell_count==0 else 'warn' if spell_count<5 else 'error')}

  {section_card("Guided Experience Score", "🧭",
    guided_section(),
    status='ok' if guided_score>=7 else 'warn' if guided_score>=4 else 'error')}

  {section_card("Label & Terminology Audit", "🏷️",
    label_section(),
    count=label_count,
    status='ok' if label_count==0 else 'warn' if label_count<5 else 'error')}

  <p style="text-align:center;color:#a0aec0;font-size:12px;margin-top:24px">
    Orbit PM UX Audit &nbsp;·&nbsp; <a href="https://github.com/adityaarsharma/orbit" style="color:#a0aec0">github.com/adityaarsharma/orbit</a>
  </p>
</div>
</body>
</html>'''

Path(args.out).parent.mkdir(parents=True, exist_ok=True)
Path(args.out).write_text(html)
print(f'PM UX report written to: {args.out}')
