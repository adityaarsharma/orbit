---
name: orbit-uninstall-test
description: Uninstall hygiene test for a WordPress plugin — verifies that deleting the plugin completely removes options, postmeta, custom tables, transients, scheduled crons, user meta, capabilities, and uploaded files. Use when the user says "uninstall test", "deactivation cleanup", "remove all data on uninstall", or before any release touching the activation/uninstall paths.
---

# 🪐 orbit-uninstall-test — Uninstall hygiene

90% of WP plugins leave junk behind on uninstall. Site owners hate this. WP.org grumbles about it. This skill catches what your `uninstall.php` should clean.

---

## Quick start

```bash
PLUGIN_SLUG=my-plugin npx playwright test --project=uninstall
```

The spec:
1. Activates the plugin
2. Triggers it to write data (settings, meta, transients, cron)
3. Records the DB state ("before")
4. Deactivates + deletes the plugin
5. Records the DB state ("after")
6. Diffs — anything created in step 2 but still present in step 5 = leak

---

## What it checks

### Options
```sql
SELECT option_name FROM wp_options
WHERE option_name LIKE 'my_plugin_%'
   OR option_name LIKE '_transient_my_plugin_%'
   OR option_name LIKE '_site_transient_my_plugin_%';
-- → must be empty after uninstall
```

### Custom tables
```sql
SHOW TABLES LIKE 'wp_my_plugin_%';
-- → must be empty after uninstall
```

### Postmeta
```sql
SELECT DISTINCT meta_key FROM wp_postmeta WHERE meta_key LIKE 'my_plugin_%';
-- → must be empty after uninstall
```

### User meta
```sql
SELECT DISTINCT meta_key FROM wp_usermeta WHERE meta_key LIKE 'my_plugin_%';
-- → must be empty after uninstall
```

### Custom capabilities
```php
$role = get_role( 'administrator' );
foreach ( $role->capabilities as $cap => $_ ) {
  if ( str_starts_with( $cap, 'my_plugin_' ) ) {
    // ❌ Capability leaked
  }
}
```

### Scheduled crons
```bash
wp-env run cli wp cron event list --format=csv | grep my_plugin
# → must be empty after uninstall
```

### Uploaded files
- `wp-content/uploads/my-plugin/` — must be removed if your plugin used it
- (Or kept if your plugin generated user content the user might want)

### Roles
If your plugin added custom roles (`add_role`), uninstall must remove them.

---

## Standard uninstall.php

```php
<?php
// uninstall.php
if ( ! defined( 'WP_UNINSTALL_PLUGIN' ) ) exit;

global $wpdb;

// 1. Delete options + transients
$opts = $wpdb->get_col( "SELECT option_name FROM {$wpdb->options}
                         WHERE option_name LIKE 'my_plugin_%'
                            OR option_name LIKE '_transient_my_plugin_%'
                            OR option_name LIKE '_site_transient_my_plugin_%'
                            OR option_name LIKE '_transient_timeout_my_plugin_%'
                            OR option_name LIKE '_site_transient_timeout_my_plugin_%'" );
foreach ( $opts as $opt ) delete_option( $opt );

// 2. Drop custom tables
$tables = $wpdb->get_col( "SHOW TABLES LIKE '{$wpdb->prefix}my_plugin_%'" );
foreach ( $tables as $t ) $wpdb->query( "DROP TABLE IF EXISTS `$t`" );

// 3. Delete postmeta
$wpdb->query( "DELETE FROM {$wpdb->postmeta} WHERE meta_key LIKE 'my_plugin_%'" );

// 4. Delete usermeta
$wpdb->query( "DELETE FROM {$wpdb->usermeta} WHERE meta_key LIKE 'my_plugin_%'" );

// 5. Remove custom capabilities
foreach ( wp_roles()->role_names as $role => $_ ) {
  $r = get_role( $role );
  if ( $r ) {
    foreach ( $r->capabilities as $cap => $__ ) {
      if ( str_starts_with( $cap, 'my_plugin_' ) ) $r->remove_cap( $cap );
    }
  }
}

// 6. Remove custom roles
remove_role( 'my_plugin_subscriber' );

// 7. Clear all scheduled crons
wp_clear_scheduled_hook( 'my_plugin_daily_task' );

// 8. Multisite — iterate sites
if ( is_multisite() ) {
  $sites = get_sites( [ 'fields' => 'ids' ] );
  foreach ( $sites as $sid ) {
    switch_to_blog( $sid );
    // Repeat steps 1-7 per site
    restore_current_blog();
  }
  delete_site_option( 'my_plugin_network_setting' );
}
```

---

## Common leaks

### `_transient_timeout_*` (50% of plugins miss these)
For every `set_transient`, WP creates `_transient_X` AND `_transient_timeout_X`. Both must be deleted.

### Auto-load options
Use `WHERE autoload='yes'` filter to specifically clean those if you bloated the autoload.

### Postmeta in nested structures
If you stored serialised meta with nested keys, `LIKE 'my_plugin_%'` may miss them. Audit by exporting wp_postmeta and grepping.

### Cron hooks not cleared
If your plugin scheduled `my_plugin_daily_task`, `wp_clear_scheduled_hook('my_plugin_daily_task')` must be called. WP-CLI:
```bash
wp cron event list | grep my_plugin
```

### Uploaded files
`wp-content/uploads/my-plugin/` — use `WP_Filesystem` to remove:
```php
require_once ABSPATH . 'wp-admin/includes/file.php';
WP_Filesystem();
global $wp_filesystem;
$dir = wp_upload_dir()['basedir'] . '/my-plugin';
if ( $wp_filesystem->is_dir( $dir ) ) $wp_filesystem->rmdir( $dir, true );
```

---

## "Keep data on uninstall" option

Many plugins (WPForms, Yoast) offer a setting: "Keep all data on uninstall (for upgrades)". Implement:

```php
// uninstall.php
if ( ! defined( 'WP_UNINSTALL_PLUGIN' ) ) exit;

$opts = get_option( 'my_plugin_settings' );
if ( ! empty( $opts['keep_data_on_uninstall'] ) ) {
  return; // skip cleanup
}

// ... cleanup as before ...
```

Default this to **off** (clean uninstall). Power users opt in.

---

## Output

```
[Uninstall Test] my-plugin

Pre-uninstall state:
  options:    my_plugin_settings, my_plugin_version, _transient_my_plugin_x
  postmeta:   2 keys (my_plugin_data, my_plugin_state)
  usermeta:   1 key (my_plugin_pref)
  tables:     wp_my_plugin_logs, wp_my_plugin_cache
  cron:       my_plugin_daily_task
  files:      wp-content/uploads/my-plugin/

After uninstall:
  options:    ✓ all removed
  postmeta:   ❌ my_plugin_state still present in 14 rows
  usermeta:   ✓ all removed
  tables:     ❌ wp_my_plugin_cache still exists
  cron:       ✓ cleared
  files:      ✓ removed

→ Block release. uninstall.php missing cleanup for postmeta key 'my_plugin_state' and table 'wp_my_plugin_cache'.
```

---

## Pair with `/orbit-multisite`

This skill checks single-site uninstall. `/orbit-multisite` checks the network-level uninstall. Both must pass before any release that adds DB writes.
