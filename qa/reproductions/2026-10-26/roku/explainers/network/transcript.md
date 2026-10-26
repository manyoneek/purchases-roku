# Captioned explainer

October 26, 2026 brs-engine simulator footage and title cards. No voice narration.

## intro

Roku SDK: a dropped connection crashes
getCustomerInfo instead of returning an error

purchases-roku main 3011f85 (0.0.5)
October 26, 2026

## before

BEFORE / upstream main

getCustomerInfo while the connection
to RevenueCat fails.

The callback never runs.
The client stops with:
"'Dot' Operator attempted with
invalid BrightScript Component"
at Purchases.brs:1039

## cause

ROOT CAUSE

Failed requests return { error: result.json() }.
A dropped connection has no JSON body, so error is invalid.
The SDK then treats the request as a success
and calls buildSubscriber(invalid), which throws.

Same path in getOfferings, logIn, logOut and purchase.
setAttributes reports success.

## fix

THE FIX

A failed request without a backend error body
returns NETWORK_ERROR (code 10).
Backend JSON errors pass through unchanged.

No public API change.

## after

AFTER / same client, fix f9fb0d9

callback(invalid, error)
error.code = 10
codeName = "NETWORK_ERROR"

The app can show an offline state.

## verified

CHECKED ON CURRENT MAIN

3 new tests: fail before, pass after
(getCustomerInfo, getOfferings, logIn)
Full suite: 30 pass
Every release from 0.0.1 to 0.0.5 crashes the same way

brs-engine 2.6.2 simulator, not a Roku device.
No purchases.
