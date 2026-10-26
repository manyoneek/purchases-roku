# Captioned explainer

October 26, 2026 brs-engine simulator footage and title cards. No voice narration.

## intro

Roku SDK: setLogLevel or setProxyURL
unconfigures the SDK

purchases-roku main 3011f85 (0.0.5)
October 26, 2026

## before

BEFORE / upstream main

configure()
  isConfigured() = true
setLogLevel("debug")
  isConfigured() = false
The proxy URL is gone too.

getCustomerInfo throws
"Purchases SDK not configured".

## cause

ROOT CAUSE

setLogLevel and setProxyURL call configuration.set()
with a single key.
set() replaces the whole configuration with that object,
so apiKey and the other setting become invalid.

configure() also drops a log level or proxy set before it.

## fix

THE FIX

set() updates only the keys it receives
and keeps the rest.

No public API change.
Draft PR #39 has a similar merge inside a larger change.

## after

AFTER / same client, fix 6708a44

setLogLevel("debug") keeps
the configuration.
isConfigured() = true
The proxy URL is kept.
getCustomerInfo returns
the customer.

## verified

CHECKED ON CURRENT MAIN

3 new tests: fail before, pass after
Full suite: 30 pass
Present in every release since 0.0.1

Synthetic Test Store user, no purchases.
brs-engine 2.6.2 simulator, not a Roku device.
