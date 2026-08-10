# Orbit — Self-Eval Fixtures

> 20 known-buggy fixtures with ground-truth findings. Run these before shipping any skill/agent change; every EXPECT must be caught. A miss = regression = block. Every bug that escapes a real audit becomes a new fixture here — so Orbit can never silently lose a detection it once had.

## Set A — Security
- **A-01 XSS:** `echo '<input value="'.$_GET['name'].'">';` → EXPECT unescaped-output XSS (A1); require `esc_attr`.
- **A-02 SQLi:** `$wpdb->get_var("SELECT * FROM t WHERE id=".$_GET['id']);` → EXPECT SQLi via concat (A5); require `$wpdb->prepare`.
- **A-03 CSRF:** `add_action('wp_ajax_save', fn()=>update_option('k',$_POST['v']));` → EXPECT state change without nonce (A8).
- **A-04 Access:** `register_rest_route('x/v1','/del',['methods'=>'POST','callback'=>'del','permission_callback'=>'__return_true']);` → EXPECT broken access control (A11).
- **A-05 POI:** `$o=unserialize($_COOKIE['data']);` → EXPECT PHP Object Injection (A18).

## Set B/C — Core compat + WooCommerce
- **B-01 i18n-early:** (plugin main file, pre-`init`) `__('Hello','td');` → EXPECT translation loaded too early on WP 6.7+ (B1).
- **B-02 autoload:** `add_option('my_cache',$big_array);` → EXPECT large option autoloaded (B2/E1).
- **B-03 deprecated:** `get_page_by_title('About');` → EXPECT deprecated since WP 6.2 (B7).
- **C-01 HPOS-meta:** `get_post_meta($order_id,'_order_total',true);` → EXPECT direct order postmeta breaks under HPOS (C1).
- **C-02 HPOS-query:** `new WP_Query(['post_type'=>'shop_order']);` → EXPECT order query breaks under HPOS (C2).
- **C-03 HPOS-declare:** touches orders, no `declare_compatibility('custom_order_tables',...)` → EXPECT HPOS compat not declared (C4).

## Set D/E/F — i18n + perf/DB + PHP 8
- **D-01 domain:** `__('Save','not-the-slug');` → EXPECT text domain ≠ slug (D1).
- **D-02 js-i18n:** block uses `wp.i18n __()` but PHP never calls `wp_set_script_translations` → EXPECT JS translations missing (D3).
- **D-03 unicode:** `file_put_contents($f, json_encode($strings));` → EXPECT missing `JSON_UNESCAPED_UNICODE` (D6).
- **E-01 N+1:** `foreach($ids as $id){ get_post_meta($id,'x',true); }` → EXPECT N+1 meta in loop (E2).
- **E-02 uninstall:** no `uninstall.php`, leaves prefixed options → EXPECT uninstall cleanup missing (E4).
- **E-03 assets:** `add_action('wp_enqueue_scripts', fn()=>wp_enqueue_script('big',...));` → EXPECT over-eager asset load (E5).
- **F-01 create_function:** `create_function('$a','return $a;');` → EXPECT removed PHP 8.0 = FATAL (F1).
- **F-02 null-string:** `trim(get_option('maybe_missing'));` → EXPECT null-to-string deprecation (F4).
- **F-03 dyn-prop:** `class X{ function f(){ $this->foo=1; } }` → EXPECT dynamic property deprecated 8.2 (F5).

## Gate protocol
Before shipping any skill/agent change: run each fixture through the relevant check, assert the EXPECT finding is produced. One miss = regression = block. Grow the set on every escaped real-world bug.
