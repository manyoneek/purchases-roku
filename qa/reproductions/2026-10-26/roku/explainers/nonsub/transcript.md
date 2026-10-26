# Captioned explainer

October 26, 2026 brs-engine simulator footage and title cards. No voice narration.

## intro

Roku SDK: lifetime purchases are missing
from allPurchasedProductIds

purchases-roku main 3011f85 (0.0.5)
October 26, 2026

## before

BEFORE / upstream main

A synthetic Test Store customer owns
one non-consumable: bug_reporter_lifetime.

nonSubscriptionTransactions lists it.
allPurchasedProductIds = [<uninitialized>]

## cause

ROOT CAUSE

The non-subscription loop pushes productIdentifier,
a variable left over from the subscriptions loop.

No subscriptions: an uninitialized value.
With subscriptions: the last subscription ID again.

Regression from PR #12 (September 2024), first shipped in 0.0.2.

## fix

THE FIX

Push entry.key, the non-subscription product ID.
One-line change.

No public API change.

## after

AFTER / same client, fix a73c6b5

Same customer, same backend response.
allPurchasedProductIds =
["bug_reporter_lifetime"]

## verified

CHECKED ON CURRENT MAIN

2 new tests: fail before, pass after
Full suite: 29 pass
Historical runs: 0.0.1 correct, 0.0.2 through main affected

Real Test Store response for a synthetic user.
brs-engine 2.6.2 simulator, not a Roku device.
