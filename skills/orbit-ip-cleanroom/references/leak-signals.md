# WordPress plugin leak signals & severity

The reference author's **expression** in a WordPress plugin goes far beyond PHP function bodies. These
are the tells `ip-leak-scan.sh` checks our plugin for. Triage with the abstraction-filtration-comparison
(AFC) test: strip out the ideas, the WP platform API, and anything dictated by function — what's left is
protectable expression. Reusing the protectable parts is the copy signal.

## Identifiers — the author's invented names (reusing them = copy signal + conflict risk)

| Signal | Where | Severity if matched |
|---|---|---|
| Text domain | `load_plugin_textdomain`, `__()/_e()` 2nd arg, header `Text Domain:` | 🔴 |
| Function / class / namespace prefix | everywhere | 🔴 (cluster) |
| Custom action/filter names | `do_action()/apply_filters()/add_action()` | 🔴 |
| Option / transient / post-meta / user-meta keys | `get_option`, `set_transient`, `*_meta` | 🔴 |
| DB table names, cron event hooks | `$wpdb->prefix.'…'`, `wp_schedule_event` | 🔴 |
| REST namespace & routes, AJAX actions, nonce actions | `register_rest_route`, `wp_ajax_*`, `wp_create_nonce` | 🔴 |
| Block name (`namespace/block`), shortcode tags, widget IDs | `block.json`, `add_shortcode`, `register_widget` | 🔴 |
| CSS class prefix, JS/CSS handle names | `wp_enqueue_*`, stylesheet classes | 🟡→🔴 |

> WordPress's *own* function names (`add_action`, `wp_enqueue_script`, hook names like `init`,
> `the_content`) are the platform's API — using them is required and fine. Only the **author-invented**
> names above are their expression.

## Text & metadata (copyrightable prose)

| Signal | Severity |
|---|---|
| Translatable UI strings copied verbatim | 🔴 |
| `readme.txt` description / FAQ / installation wording | 🔴 |
| Changelog phrasing copied | 🟡 |
| Plugin header fields mirroring theirs (Description, Author, Author URI) | 🟡→🔴 |
| Error / log / notice message strings | 🟡→🔴 |

## Assets

| Signal | Severity |
|---|---|
| Bundled images / icons / SVGs from the reference | 🔴 |
| Screenshots, WP.org banner/icon art reused | 🔴 |
| Fonts lifted from the reference | 🔴 |
| Bundled JS/PHP lib without its license/notice retained | 🔴 (compliance) |

## Structure & code

| Signal | Severity |
|---|---|
| Verbatim or paraphrased PHP/JS blocks | 🔴 |
| Identical file/dir layout + helper decomposition (structure/sequence/organization) | 🔴 |
| Magic constants / lookup tables copied | 🔴 |
| File names mirroring theirs | 🟢 (low weight, still scrub) |

## Action by severity
- 🟢 → scrub (it's a cosmetic trace on our own work).
- 🟡 → human judgment (extent + distinctiveness).
- 🔴 → reimplement from spec with our own identifiers/strings/assets; **do not** rename-and-ship.

> Engineering risk-reduction, NOT legal advice. The detailed escalation contact and authorization
> checklist live in brain (`orbit/07-security` → `ip-cleanroom RUNBOOK`). Read it before acting on 🔴.
