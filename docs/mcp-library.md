# Orbit — MCP Library for WordPress Developers

> What MCPs power Orbit agents. What every WordPress dev should have.
> Organized by: must-have → strong recommendation → nice-to-have.
> POSIMYTH internal team gets additional MCPs (marked below).

---

## Finding MCPs (any category)

Use the built-in discovery skill — searches 23,000+ MCPs across all public registries simultaneously:

```
/orbit-mcp-discover  "wordpress management"
/orbit-mcp-discover  "playwright browser testing"
/orbit-mcp-discover  "security vulnerability scanner"
/orbit-mcp-discover  "stripe payments"
```

Sources searched in parallel: **glama.ai** (23,945 servers) + **smithery.ai** + **mcp-get.com** + **npm** + **GitHub** + **awesome-mcp-servers** (87k ★). Returns deduplicated results with install commands. No auth required. Always live — never a hardcoded list.

Or ask the CTO agent: `"Find MCPs for [capability]"` → 00-CTO runs `/orbit-mcp-discover` and recommends which Orbit agent should use it.

---

## Tier model

| Tier | Who | Access |
|---|---|---|
| **Team** | Any Orbit user | Read brain + code tools + browser testing |
| **Admin** | POSIMYTH team | Write brain + WP publish + release tools + Slack/n8n |

---

## Must-Have for Every Orbit User

### 1. `brain-posimyth` — Memory + Services
**What it is:** The central connector. Exposes brain search, WP operations, Apify, and more through one URL.
**Why devs need it:** Every Orbit agent starts with 5 brain searches. Without this, agents run cold.
**Orbit use:** Recall past audit findings, store approved patterns, search WP knowledge base.
**Access:** Team key (read) or Admin key (write).
```
URL: https://brain.posimyth.com/connectors
Key: orbit_team_key or orbit_admin_key
Setup: docs/team-access.md
```

### 2. GitHub via `gh` CLI — Code + PRs + Issues
**What it is:** GitHub CLI. Already available in most dev environments.
**Why devs need it:** Orbit Security agent reads source code, Release Manager creates PRs, Test Auto opens issues for failures.
**Orbit use:** PR creation, issue tracking, code reading, release tagging.
**Setup:** `brew install gh && gh auth login`
```
Tools: gh pr create, gh issue create, gh repo view, gh release create
Orbit agents that use it: 05-uat, 07-security, 08-release, 02-code-reviewer
```

### 3. `Claude in Chrome` / `Control Chrome` — Browser Testing
**What it is:** Browser automation tools built into Claude Code.
**Why devs need it:** Visual regression testing, block editor UAT, Elementor widget visual checks.
**Orbit use:** UAT (05) uses for visual regression. Dev Designer (04) uses for accessibility inspection.
**Already installed:** Available as built-in MCP tools.

### 4. Context7 — Live Library Docs
**What it is:** Fetches up-to-date docs for any library at runtime. Critical for WP development.
**Why devs need it:** WordPress APIs change with every release. PHP version requirements change. React in Gutenberg evolves. Context7 always has current docs.
**Orbit use:** Code Reviewer (02) and Senior Dev (03) use it to verify current API signatures.
**Why it beats Googling:** Fetches directly from official sources. No SEO spam. No outdated Stack Overflow.
```
Skill: /context7-auto-research
Usage: "Get current docs for wp_enqueue_block_editor_assets"
```

### 5. `wp-env` / `wp-cli` via Bash — Local WP Environment
**What it is:** Official WordPress local dev environment. Spin up fresh WP installs instantly.
**Why devs need it:** Every Orbit audit needs a clean WP install to test against. Security agent needs source. Performance agent needs a running instance for Lighthouse.
**Setup:**
```bash
npm install -g @wordpress/env
# Start: wp-env start
# WP-CLI: wp-env run cli wp --info
# Clean install: wp-env destroy && wp-env start
```
**Orbit use:** All agents that need live plugin testing (02, 03, 05, 06, 07).

---

## Strong Recommendations

### 6. Apify — Scraping Engine
**What it is:** Web scraping and automation platform. Already available via `brain-posimyth` connector.
**Why devs need it:**
- Mine WP.org reviews for user feedback → feeds 10-PM agent
- Scrape CVE databases for plugin vulnerabilities → feeds 07-security
- Competitor plugin data → feeds 10-PM competitor pulse
- WP.org plugin stats (active installs, ratings) → feeds 10-PM
**Access:** Via `brain-posimyth` (Team key can read scraped data. Admin key can trigger new scrapes.)
```
Orbit agents: 07-security (CVE scraping), 01-pm (review mining), 09-docs (SERP data)
```

### 7. DataForSEO — Performance + SERP Data
**What it is:** SEO data API. PageSpeed, SERP results, keyword data, backlinks.
**Why devs need it:**
- PageSpeed Insights data for Performance agent (03)
- Plugin search results for SEO & Docs agent (12)
- Competitor plugin rankings for PM agent (10)
**Access:** Via `brain-posimyth` connector .
```
Orbit agents: 06-performance (PageSpeed), 01-pm (SERP), 09-docs (schema + speed)
```

### 8. Sentry — Error Monitoring
**What it is:** Production error tracking and performance monitoring.
**Why devs need it:** Catch PHP errors from production installs. See what users actually hit vs what tests miss.
**Orbit use:** UAT (05) can pull real-world errors before marking a plugin release-ready.
**Skill available:** `/sentry-automation`
```
Setup: sentry.io — add WP Sentry plugin to monitored sites
Orbit agents: 05-uat (production error review before release)
```

---

## Nice-to-Have (Power Users)

### 9. LambdaTest — Cross-Browser Testing
**What it is:** Cloud browser testing across 3000+ browser+OS combinations.
**Why devs need it:** Block editor and Elementor widgets must work across Chrome, Firefox, Safari, Edge.
**Orbit use:** UAT agent (05) for cross-browser UAT.
**Skill available:** `/lambdatest-agent-skills`

### 10. Linear — Issue Tracking
**What it is:** Developer-native issue tracker. Better than ClickUp for pure dev teams.
**Why devs need it:** Create issues from Orbit findings automatically. Track remediation.
**Orbit use:** UAT (05) creates Linear issues for Critical/High findings.
**Skill available:** `/linear-automation`, `/linear-claude-skill`

### 11. n8n — Workflow Automation
**What it is:** Open-source workflow automation. Connects Orbit findings to Slack, ClickUp, GitHub Issues.
**Why devs need it:** Auto-post audit results to Slack channel. Auto-create GitHub issues for Critical findings.
**Orbit use:** Automated notifications, CI/CD integration.
**Already available:** `n8n-mcp` in POSIMYTH brain.

---

## POSIMYTH Internal Team — Additional MCPs

These are not for public Orbit users. Internal POSIMYTH team only (Admin key).

| MCP | Purpose | Orbit agent that uses it |
|---|---|---|
| `wp-posimyth` / `wp-nexterwp` / `wp-theplusaddons` | Publish release notes, docs, changelogs | 08-release, 09-docs |
| `fluentcrm` (via brain-posimyth) | Release email announcements | 08-release |
| `n8n-mcp` | CI/CD automation, scheduled audits | 05-uat |

---

## MCP quick-start for new Orbit users

```bash
# Step 1: Install GitHub CLI
brew install gh && gh auth login

# Step 2: Install wp-env
npm install -g @wordpress/env

# Step 3: Get your Orbit brain key (from POSIMYTH)
# orbit_team_key for read access
# orbit_admin_key for write access (team only)

# Step 4: Add brain key to Claude Code settings
# Settings > MCP > brain-posimyth > orbit_team_key or orbit_admin_key

# Step 5: Seed starter brain (Admin only, first time)
bash brain/seed-brain.sh --key <orbit_admin_key>
```

---

## What developers most ask for (and where to find it)

| "I need to…" | MCP/Tool | Orbit agent |
|---|---|---|
| Check live WP API docs | Context7 skill | 02-code-reviewer, 03-senior-dev |
| Scrape WP.org user reviews | Apify via brain | 01-pm |
| Run PageSpeed on staging | DataForSEO via brain | 06-performance |
| Create a GitHub issue for a bug | `gh issue create` | 05-uat |
| Test cross-browser (Chrome/Firefox/Safari) | LambdaTest | 05-uat |
| Monitor production errors | Sentry | 05-uat |
| Publish release notes to WP site | WP MCP (Admin) | 08-release |
| Automate findings → Slack | n8n MCP (Admin) | 05-uat |
| Mine CVE databases | Apify via brain | 07-security |
| Track feature backlog | Linear | 01-pm |
