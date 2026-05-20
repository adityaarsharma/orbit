# Orbit — Team vs Admin Key Setup

> Every Orbit install gets two keys: Team (read) and Admin (write).
> Exact same model as Golden Circle.

---

## Key model

```
brain-posimyth
└── orbit/ namespace
    │
    ├── Team key ──► READ orbit/* (search, recall, browse)
    │                  Cannot write. Cannot access Golden Circle drawers.
    │
    └── Admin key ──► READ + WRITE orbit/*
                       Can ingest findings, add patterns, update knowledge/
                       Can access WP publish, Slack, n8n (POSIMYTH internal only)
```

---

## What each key unlocks

### Team key — `orbit_team_key`

**Brain operations:**
- `posimyth_brain_search` — search all `orbit/*` drawers
- `posimyth_brain_wake_up` — wake up brain context
- `posimyth_brain_list_drawers` — browse orbit namespace

**MCP access:**
- GitHub read (code, PRs, issues — no write)
- Claude in Chrome / Control Chrome
- DataForSEO (read-only queries)
- Context7 (docs fetch)

**Cannot:**
- Write to brain (`posimyth_brain_add_note` blocked)
- Publish to WP sites
- Send Slack messages
- Trigger n8n workflows
- Access FluentCRM

**Best for:** External developers, contractors, QA reviewers who use Orbit on their own plugins.

---

### Admin key — `orbit_admin_key`

**Everything in Team key, plus:**

**Brain write operations:**
- `posimyth_brain_add_note` — ingest findings, approved patterns, redlines
- `posimyth_brain_add_drawer` — create new plugin namespace (e.g. `orbit/plugins/new-plugin/`)
- Update `orbit/knowledge/` base drawers (carefully — affects all agents)

**Service operations:**
- `wp_nexterwp_*` — publish release notes to NexterWP site
- `wp_tpae_*` — publish to The Plus Addons site
- Slack notifications via `slack-aditya`
- n8n workflow triggers
- FluentCRM release email drafts
- GitHub write (create PRs, close issues, push tags)

**Seed operations:**
- `bash brain/seed-brain.sh` — seed starter brain on new install

**Best for:** POSIMYTH internal team (Aditya, Sagar, Jigar, Raj). Release coordinators. QA leads.

---

## First-time setup

### For a new Orbit install (Admin)

```bash
# 1. Install Orbit
curl -fsSL https://raw.githubusercontent.com/adityaarsharma/orbit/main/install.sh | bash

# 2. Get your keys from Aditya (brain.posimyth.com admin panel)
# Request: orbit_team_key and/or orbit_admin_key

# 3. Add to Claude Code settings
# Open: ~/.claude/settings.json or Claude Code > Settings > MCP
# Add under brain-posimyth: { "key": "orbit_admin_key" }

# 4. Seed the starter brain (Admin only, one time per brain instance)
bash brain/seed-brain.sh --key <orbit_admin_key>

# 5. Create your first plugin namespace (optional)
# In Claude Code, run: /orbit-setup
# This will create orbit/plugins/<your-plugin>/ namespace in brain
```

### For a team member (Team key)

```bash
# 1. Install Orbit
curl -fsSL https://raw.githubusercontent.com/adityaarsharma/orbit/main/install.sh | bash

# 2. Get orbit_team_key from Admin
# 3. Add to Claude Code settings:
#    brain-posimyth key: orbit_team_key

# 4. Verify access:
# In Claude Code: posimyth_brain_search("orbit knowledge wp-standards")
# Should return starter brain drawers
```

---

## Key provisioning (for Admin / Aditya)

Keys are provisioned from the brain.posimyth.com admin panel under the `orbit` tenant.

```
brain.posimyth.com/admin
└── Tenants
    └── orbit
        ├── Team key    → orbit_team_key_<uuid>    [read only]
        └── Admin key   → orbit_admin_key_<uuid>   [read + write]
```

**Rotation:** Rotate keys every 90 days or when a team member leaves.
**Per-user keys:** Recommended for Admin keys so you can audit who ingested what.

---

## What agents do with each key

| Agent | Uses key | Why |
|---|---|---|
| 01-qa-lead | Admin (read brain + ingest findings) | Needs to write audit results |
| 02-security | Admin (ingest CVE findings) | Needs to write security patterns |
| 03-performance | Admin (ingest benchmarks) | Needs to write baseline benchmarks |
| 04-gutenberg | Admin (ingest block patterns) | Needs to write block-specific learnings |
| 05-elementor | Admin (ingest widget history) | Needs to write Elementor patterns |
| 06-designer | Admin (ingest a11y findings) | Needs to write accessibility patterns |
| 07-release | Admin (write brain + WP publish) | Needs publish + brain write |
| 08-compat | Admin (ingest compat results) | Needs to write compat matrix data |
| 09-test-auto | Admin (ingest test patterns) | Needs to write test results/baselines |
| 10-pm | Admin (ingest RICE decisions) | Needs to write prioritization history |
| 11-compliance | Admin (ingest compliance findings) | Needs to write compliance patterns |
| 12-seo-docs | Admin (write docs + brain) | Needs WP publish + brain write |

> If running in **Team mode** (external contractor or reviewer), all agents operate read-only. They produce reports but don't ingest to brain. Admin reviews and ingests manually.
