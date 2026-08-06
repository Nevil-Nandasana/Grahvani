# ADR-005: Multi-Provider Hybrid Billing Architecture

> [[ADR Index](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/adr/README.md) | [Subscriptions Lifecycle](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/billing/SUBSCRIPTIONS.md) | [Entitlements Engine](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/billing/ENTITLEMENTS.md) | [Razorpay Specs](file:///e:/AI-WorkSpace/Projects/Active/Grahvani/docs/billing/RAZORPAY.md)]

---

## Metadata
- **Status**: Accepted
- **Date**: 2026-08-01
- **Deciders**: Product Director, Lead Mobile Engineer, Backend Lead
- **Technical Story**: Defining the payment processing and subscription entitlement verification architecture for India-first and international users across mobile and web.

---

## Context & Problem Statement

Grahvani targets both domestic Indian users and global international audiences. India-first users prefer localized payment methods (UPI, Netbanking, Credit/Debit cards, Razorpay web checkout) due to high conversion rates, whereas mobile app stores (Google Play Billing, Apple App Store IAP) require native in-app subscriptions for mobile app distribution. We need a payment architecture that handles multi-channel subscriptions seamlessly.

---

## Options Considered

### Option 1: 100% Mobile Store Billing Only (Google Play + Apple IAP)
Restrict all purchases exclusively to Google Play Billing and Apple In-App Purchases.

- **Pros**: Simplified entitlement sync; no web payment gateway integration.
- **Cons**: High commission fees (15%-30%); poor UPI conversion rates in India; inability to offer direct web checkout or custom promotional discounts.

---

### Option 2: 3rd-Party Abstraction SaaS (e.g. RevenueCat / Adapty)
Delegate all subscription management to a third-party subscription platform SaaS.

- **Pros**: Pre-built Flutter SDKs and dashboard metrics.
- **Cons**: Additional percentage fee on top of store/gateway fees; external SaaS dependency for core billing logic; limited support for Indian local payment gateways (Razorpay UPI recurring).

---

### Option 3: In-House Hybrid Billing Engine (Razorpay + Google Play + Apple IAP) — **ACCEPTED**
Build a centralized **Entitlement Service module** inside the FastAPI backend that normalizes subscription events from three gateway channels:
1. **Razorpay Web / UPI Checkout** (India domestic web & Android fallback).
2. **Google Play Billing** (Android native app store).
3. **Apple In-App Purchases** (iOS native app store).

- **Pros**:
  - **Highest India Conversion**: Direct Razorpay UPI AutoPay integration.
  - **Compliance**: Adheres to Google Play and Apple App Store billing guidelines for digital content consumed inside mobile apps.
  - **Unified User Entitlement State**: A single PostgreSQL `subscriptions` table tracks active access regardless of purchase channel.
- **Cons**: Requires maintaining webhook receivers for three independent payment providers.

---

## Decision Outcome

**Chosen Option**: **Option 3: In-House Hybrid Billing Engine**.

### Positive Consequences
- Maximum flexibility in offering localized pricing (INR vs USD) and UPI payment flows.
- Full ownership of entitlement state, subscriber retention data, and webhook processing.

---

## Re-evaluation Trigger
- Re-evaluate if maintenance of store webhook APIs exceeds 15% of backend developer bandwidth.
