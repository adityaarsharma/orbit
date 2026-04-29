---
name: orbit-pay-stripe
description: Stripe API integration audit for a WordPress plugin — API key handling, idempotency keys, webhook signature verification, PaymentIntent flow (3DS / SCA), Customer + Subscription lifecycle, Stripe-CLI tunnel for local testing, PCI scope minimisation. Use when the user says "Stripe integration", "Stripe API", "PaymentIntent", "Stripe webhook", "SCA / 3DS".
---

# 🪐 orbit-pay-stripe — Stripe SDK integration audit

Stripe is the most-used payment gateway for WP plugins. Mistakes here = real money + customer trust risk. This skill catches them.

---

## What this skill checks

### 1. API key handling
**Whitepaper intent:** Stripe keys are sensitive. They must NEVER:
- Be hardcoded in source
- Be committed to git
- Be in client-side JS
- Be logged in plain text

```php
// ❌ Hardcoded
$stripe = new \Stripe\StripeClient( 'sk_live_xxx' );

// ✅ From option, encrypted at rest preferred
$stripe = new \Stripe\StripeClient( get_option( 'my_plugin_stripe_secret_key' ) );
```

For client-side, use **publishable key** only (`pk_live_*`), never secret (`sk_*`).

### 2. Idempotency keys (prevent double-charges)
```php
$stripe->paymentIntents->create([
  'amount' => 2000,
  'currency' => 'usd',
], [
  'idempotency_key' => 'order_' . $order_id,
]);
```

Without idempotency, network retries can double-charge.

### 3. Webhook signature verification
```php
$payload = file_get_contents( 'php://input' );
$sig_header = $_SERVER['HTTP_STRIPE_SIGNATURE'] ?? '';

try {
  $event = \Stripe\Webhook::constructEvent(
    $payload, $sig_header, $endpoint_secret
  );
} catch ( \Stripe\Exception\SignatureVerificationException $e ) {
  http_response_code( 400 );
  exit;
}
```

**Whitepaper intent:** Without signature verification, anyone can forge webhook events and trigger your handler — fake "payment_succeeded" → grant access to a paid product without paying.

### 4. PaymentIntent vs legacy Charge
Use PaymentIntents API. The older Charges API doesn't handle SCA / 3DS, which Stripe now requires for EU customers.

```php
// ✅ Modern
$intent = $stripe->paymentIntents->create([
  'amount' => 2000,
  'currency' => 'eur',
  'payment_method_types' => ['card'],
  'capture_method' => 'automatic',
  'confirmation_method' => 'automatic',
]);
```

### 5. Subscription lifecycle (if applicable)
- Renewal: handle `invoice.payment_succeeded`
- Failed renewal: handle `invoice.payment_failed`, retry strategy, dunning emails
- Cancel: `customer.subscription.deleted`
- Pause / resume

### 6. Stripe-CLI for local testing
```bash
# Forward Stripe events to local wp-env
stripe listen --forward-to localhost:8881/?stripe-webhook=1
```

### 7. PCI scope minimisation
**Whitepaper intent:** Touching card numbers directly = PCI-DSS scope. Use Stripe Elements (collect card client-side, get a token, send token to your server). Your server NEVER touches card data.

```js
const elements = stripe.elements();
const card = elements.create('card');
const { paymentMethod } = await stripe.createPaymentMethod({ type: 'card', card });
// Send paymentMethod.id to your server, NOT the card number
```

### 8. Test mode vs live mode detection
```php
$is_live = strpos( get_option( 'stripe_secret_key' ), 'sk_live_' ) === 0;
if ( $is_live && wp_get_environment_type() !== 'production' ) {
  wp_die( 'Live keys on non-production environment — refusing.' );
}
```

---

## Output

```markdown
# Stripe Integration — my-plugin

✓ Secret key in option, not source
✓ Webhook signature verified
✓ PaymentIntents API used (SCA-compatible)
❌ No idempotency key on PaymentIntent create — double-charge risk on network retry
⚠ Webhook handler does NOT verify event.created timestamp — replay attack possible
   → Reject events older than 5 minutes
✓ Stripe Elements used for card capture (no PCI scope)
⚠ Plugin allows live keys on staging environment — block via wp_get_environment_type
```

---

## Pair with

- `/orbit-pay-paypal` — for plugins offering both
- `/orbit-wp-security` — secret-handling
- `/orbit-uat-membership` — subscription-lifecycle UAT

---

## Sources & Evergreen References

### Canonical docs
- [Stripe API Reference](https://docs.stripe.com/api) — root
- [PaymentIntents Guide](https://docs.stripe.com/payments/payment-intents) — modern flow
- [Webhook Signatures](https://docs.stripe.com/webhooks/signatures) — verification
- [SCA / 3D Secure 2](https://docs.stripe.com/strong-customer-authentication) — EU compliance
- [Idempotent Requests](https://docs.stripe.com/api/idempotent_requests) — duplicate prevention
- [PCI-DSS Compliance](https://docs.stripe.com/security/guide) — scope reduction

### Last reviewed
- 2026-04-29 — re-fetch docs quarterly (Stripe ships major API versions yearly)
