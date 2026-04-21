// @ts-check
/**
 * Orbit — REST API Application Passwords Test (WP 5.6+)
 *
 * WP Application Passwords are a separate auth path from cookie auth.
 * Different code path = different security surface. If your plugin adds REST
 * endpoints, they MUST work with Application Password auth, AND permission
 * checks must still hold.
 *
 * Tests:
 *   - Can authenticate with app password
 *   - Permission checks still enforced (admin-only endpoints reject app pwd of subscriber)
 *
 * Usage:
 *   PLUGIN_REST_ADMIN_ENDPOINT=/wp-json/myplugin/v1/settings \
 *   npx playwright test app-passwords.spec.js
 */

const { test, expect } = require('@playwright/test');
const { execSync } = require('child_process');

const ADMIN_ENDPOINT = process.env.PLUGIN_REST_ADMIN_ENDPOINT;
const PUBLIC_ENDPOINT = process.env.PLUGIN_REST_PUBLIC_ENDPOINT;
const WP_TEST_URL     = process.env.WP_TEST_URL || 'http://localhost:8881';
const WP_ENV_RUN      = process.env.WP_ENV_RUN || 'npx wp-env run cli wp';

function wp(cmd) {
  return execSync(`${WP_ENV_RUN} ${cmd}`, { encoding: 'utf8' }).trim();
}

test.describe('REST API — Application Passwords', () => {
  test.skip(!ADMIN_ENDPOINT,
    'Set PLUGIN_REST_ADMIN_ENDPOINT (and optionally PUBLIC_ENDPOINT) to test app passwords');

  let adminAuth, subAuth;

  test.beforeAll(async () => {
    // Create admin app password
    const adminPw = wp(`user application-password create admin orbit-test --porcelain`);
    adminAuth = 'Basic ' + Buffer.from(`admin:${adminPw}`).toString('base64');

    // Create subscriber + app password
    try { wp(`user create orbit-sub orbit-sub@test.local --role=subscriber --porcelain`); } catch {}
    const subPw = wp(`user application-password create orbit-sub orbit-test --porcelain`);
    subAuth = 'Basic ' + Buffer.from(`orbit-sub:${subPw}`).toString('base64');
  });

  test.afterAll(async () => {
    try { wp(`user application-password delete admin --all`); } catch {}
    try { wp(`user application-password delete orbit-sub --all`); } catch {}
    try { wp(`user delete orbit-sub --yes --network`); } catch {}
  });

  test('admin endpoint accepts admin app password', async ({ request }) => {
    const res = await request.get(`${WP_TEST_URL}${ADMIN_ENDPOINT}`, {
      headers: { Authorization: adminAuth },
    });
    expect(res.status(), 'Admin endpoint should accept admin app password').toBeLessThan(400);
  });

  test('admin endpoint REJECTS subscriber app password (permission_callback works)', async ({ request }) => {
    const res = await request.get(`${WP_TEST_URL}${ADMIN_ENDPOINT}`, {
      headers: { Authorization: subAuth },
    });
    expect(res.status(),
      'Admin endpoint MUST reject non-admin app password — permission_callback is broken'
    ).toBeGreaterThanOrEqual(401);
  });

  test('admin endpoint REJECTS unauthenticated request', async ({ request }) => {
    const res = await request.get(`${WP_TEST_URL}${ADMIN_ENDPOINT}`);
    expect(res.status(),
      'Admin endpoint MUST reject unauthenticated request'
    ).toBeGreaterThanOrEqual(401);
  });
});
