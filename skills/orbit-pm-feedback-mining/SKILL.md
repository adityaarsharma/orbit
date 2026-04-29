---
name: orbit-pm-feedback-mining
description: Mine WP.org plugin reviews + support forum threads for action items. Pulls latest 50 reviews + open support topics, classifies by issue type (bug / feature request / UX complaint / performance / docs), summarises themes, and produces a prioritised list of "what users say is broken." Use when the user says "review mining", "what are users complaining about", "support themes", "feedback analysis".
---

# 🪐 orbit-pm-feedback-mining — Mine reviews + forum into actions

The complaint hidden in a 2-star review IS the next backlog item. This skill pulls them out in bulk.

---

## Quick start

```bash
PLUGIN_SLUG=my-plugin \
  bash ~/Claude/orbit/scripts/mine-feedback.sh
```

Output: `reports/feedback-mining-<timestamp>.md`.

---

## Sources mined

### 1. WP.org plugin reviews
```
https://wordpress.org/support/plugin/<slug>/reviews/
```
- Latest 50 reviews (configurable)
- Star rating + date + reviewer + body
- Filter to ≤3-star (where complaints live)

### 2. WP.org support forum
```
https://wordpress.org/support/plugin/<slug>/
```
- Open topics (unresolved)
- Recent activity
- Topic title + body + reply count

### 3. GitHub issues (if public repo exists)
```
gh issue list --repo <owner>/<repo> --state open --limit 50
```

### 4. Optional: Trustpilot, G2, Reddit, Twitter mentions
If the team has these channels, the script can pull them too with API tokens.

---

## What it produces

### 1. Theme classification
Buckets each piece of feedback:

```
[Themes from 50 reviews + 30 forum threads]

🐛 Bug (38%): "Settings won't save", "White screen on activation", "Broken with Yoast"
🎯 Feature request (24%): "Add x integration", "Need bulk action", "Want dark mode"
💔 UX complaint (18%): "Confusing setup", "Too many tabs", "Where is X?"
⚡ Performance (12%): "Slow on backend", "Editor lags", "DB queries growing"
📖 Docs (8%): "How do I...", "No documentation for Y"
```

### 2. Theme-to-action mapping
For each theme, propose specific actions:

```
Theme: "Settings won't save" (mentioned in 7 reviews)
Likely cause: AJAX nonce expiry on long sessions
Action: Run /orbit-ajax-fuzzer on settings handler. Add nonce-refresh on form blur.
RICE estimate: Reach=high, Impact=MASSIVE (these users are actively churning), Effort=S
```

### 3. Sentiment shift over time
Plot 4-week rolling average rating. Spot inflection points:
```
Rating trend (last 12 weeks):
  Week 1-4:   4.6 ⭐
  Week 5-8:   4.4 ⭐  ← drop after v2.3 release (regression?)
  Week 9-12:  4.3 ⭐  ← still recovering
```

### 4. Verbatim quotes (for marketing + roadmap docs)
- Top 5 worst reviews (for fixes)
- Top 5 best reviews (for testimonials, with permission)

---

## Example output

```markdown
# Feedback Mining — my-plugin · 2026-04-29

## Sources
- WP.org reviews: 50 (latest 6 months)
- WP.org forum: 30 open topics
- GitHub issues: 12 open

## Top themes
1. 🐛 Settings save fails on long sessions (7 mentions, RICE 50,000)
2. 🎯 Bulk action for repeating widgets (5 mentions, RICE 18,000)
3. 💔 First-time setup confusing (4 mentions, RICE 32,000)
4. ⚡ Editor performance with 50+ widgets (4 mentions, RICE 20,000)

## Quick wins
- Settings AJAX nonce-refresh — XS effort, fixes #1 above
- Add "Get Started" overlay on first activation — S effort, fixes #3

## Verbatim (worst — for triage)
- ★★ "Saved my settings 3 times, none stuck. Switched to <competitor>." — apr 2026
- ★ "Editor freezes after 30 widgets. Unusable." — mar 2026

## Verbatim (best — for testimonials, ASK before using)
- ★★★★★ "Cleanest Elementor addon I've used in 5 years." — apr 2026
- ★★★★★ "30% smaller bundle than the competition. Real numbers." — apr 2026
```

---

## Pair with

- `/orbit-pm-rice` — feed the themes into a scored backlog
- `/orbit-pm-roadmap` — turn themes into roadmap themes
- `/orbit-competitor-compare` — compare your reviews vs competitor's

---

## Sources & Evergreen References

### Canonical docs
- [WP.org Plugin Page Format](https://make.wordpress.org/plugins/handbook/plugin-readme/) — review format
- [Plugin Support Forum](https://wordpress.org/support/) — forum structure
- [GitHub Issues API](https://docs.github.com/en/rest/issues/issues) — for repo mining

### Rule lineage
- WP.org reviews — long-stable
- Sentiment-mining patterns — common LLM-assisted approach since 2023

### Last reviewed
- 2026-04-29
