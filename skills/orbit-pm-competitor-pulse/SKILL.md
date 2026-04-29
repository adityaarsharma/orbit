---
name: orbit-pm-competitor-pulse
description: Monthly competitor-pulse report — tracks competitor releases, version cadence, bundle weight changes, new features shipped, review-rating shifts. Cron-friendly, runs against your `qa.config.json` competitors list. Use when the user says "competitor pulse", "monthly competitor report", "what's the competition shipping".
---

# 🪐 orbit-pm-competitor-pulse — Monthly competitor monitoring

`/orbit-competitor-compare` is a deep one-time analysis. This skill is the lightweight monthly heartbeat — what shipped, what changed, what to react to.

---

## Quick start

```bash
bash ~/Claude/orbit/scripts/competitor-pulse.sh
```

Or schedule monthly:
```cron
0 9 1 * * cd ~/plugins/my-plugin && \
  bash ~/Claude/orbit/scripts/competitor-pulse.sh | mail -s "Monthly Competitor Pulse — my-plugin" pm@example.com
```

---

## What it tracks (delta from last run)

### 1. Version cadence
```
Plugin              Last 30d releases   This week     Last month
Yoast SEO            2 releases          24-Apr        15-Apr
RankMath             5 releases          27-Apr        21-Apr
Essential Addons     1 release           18-Apr        —
Premium Addons       0                   —             —          ⚠ stale 60+ days
```

### 2. Bundle weight shifts
```
Plugin              JS now       JS Δ vs last month
Yoast SEO           412 KB       +8 KB    (added settings page)
RankMath            580 KB       -42 KB   (rewrote analytics module)  ← interesting
Essential Addons    438 KB       0
```

### 3. Active install count
WP.org shows install ranges (10K+, 100K+, 1M+). Detect when a competitor ticks up to a new tier.

### 4. Review rating shift
```
Plugin              Avg rating now    1-month change
Yoast               4.8 ★             ↓ 0.1 (regression release?)
RankMath            4.7 ★             0
Essential Addons    4.6 ★             0
```

### 5. New features detected
Diff competitor's `readme.txt` changelog vs last pulse. Highlights:
```
RankMath shipped:
  + Local SEO module (Apr 18) — was paid, now free
  + AI title suggestions (Apr 22) — new feature
  ⚠ Reaction: re-evaluate our positioning
```

### 6. Strategic alerts
Auto-flag conditions worth a meeting:
- Competitor matches a feature we charge for
- Competitor drops a feature you compete on
- Bundle-weight gap closes (was ahead, now they're leaner)
- Rating drops 0.3+ stars in a month (incident)
- Active installs jumps a tier

---

## Output

```markdown
# Competitor Pulse — my-plugin · 2026-04 (monthly)

## Tracked: 4 competitors (configured in qa.config.json)

## Headlines
- 🚨 RankMath dropped JS bundle by 42KB — re-evaluate our "lightest" positioning
- 🆕 RankMath launched Local SEO free → Yoast Local Pro + ours both threatened
- 📉 Premium Addons hasn't shipped in 60 days — opportunity to capture share

## Cadence
- Yoast:        2 releases this month (slow)
- RankMath:     5 releases (aggressive)
- Essential:    1 release
- Premium:      0 releases

## Bundle weight delta
[table]

## Rating shift
[table]

## Recommended actions
1. Investigate RankMath's bundle-shrink technique — may apply to us
2. PR / blog post comparing our perf vs theirs — claim updated lead
3. Flag Premium Addons stagnation in next sales call
```

---

## Pair with

- `/orbit-competitor-compare` — once a quarter, run the deep version
- `/orbit-pm-roadmap` — feed alerts into next quarter's planning
- `/orbit-pm-feedback-mining` — see if competitor moves correlate with our review changes

---

## Sources & Evergreen References

### Canonical docs
- [WP.org Plugin API](https://developer.wordpress.org/reference/functions/plugins_api/) — programmatic access
- [BuiltWith trends](https://trends.builtwith.com/cms/plugin) — install-tier external proxy

### Last reviewed
- 2026-04-29
