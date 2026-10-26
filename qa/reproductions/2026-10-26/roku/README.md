# purchases-roku reproduction client, October 26, 2026

A minimal Roku client that calls the RevenueCat Roku SDK through `Purchases()` against the real RevenueCat backend, run in the [brs-engine](https://github.com/lvcabral/brs-engine) browser simulator.

- Upstream: `RevenueCat/purchases-roku` main `3011f857472c6d11ae55e125e9faa220c9d5458e` (0.0.5).
- Fixes: `f9fb0d9` (network errors), `a73c6b5` (non-subscription product IDs), `6708a44` (configuration), `d97000d` (test runner exit code).
- RevenueCat project `proj602cc762`, Test Store app `app4ca00b430f` ([dashboard](https://app.revenuecat.com/projects/602cc762/apps/app4ca00b430f)). Synthetic users only. The lifetime customer's purchase was created with `rc customers simulate-purchase` (`captures/simulate-purchase.json`).
- Simulator: brs-engine 2.6.2 and brs-scenegraph 0.6.2 (`package-lock.json`) in headless Chrome, driven by `run-scenario.cjs`.

## Limits

- This is a simulator, not a Roku device.
- The SDK normally runs requests in `PurchasesTask` and returns results through a field it adds to the task at runtime. brs-engine 2.6.2 does not deliver task writes to fields added at runtime, so the client turns on the SDK's synchronous main-thread mode (`isRunningRevenueCatTests`, the same path the SDK's test suite uses). Everything after `Purchases()` (configuration, request building, `roUrlTransfer`, response parsing) is the unchanged SDK code.
- Requests go through `server.mjs`, a same-origin pass-through to `https://api.revenuecat.com` (the browser blocks the SDK's custom headers cross-origin). Its `/offline/` route closes each connection without a response to simulate a dropped network. `captures/requests.jsonl` lists every request and status.
- The SDK sends `X-Platform: roku` with the Test Store public key because the project has no Roku app.

## Run it

```sh
npm ci
./build.sh before <purchases-roku checkout>      # writes web/apps/before.zip
cp node_modules/brs-engine/lib/brs.api.js node_modules/brs-engine/lib/brs.worker.js node_modules/brs-scenegraph/lib/brs-sg.js web/
mkdir -p web/assets && cp node_modules/brs-scenegraph/assets/common.zip web/assets/
node server.mjs &
RC_TEST_STORE_KEY=test_... node run-scenario.cjs before network some-user /offline/v1/ "main 3011f85" out/network-before
```

Scenarios: `network` (proxy `/offline/v1/`), `lifetime` (proxy `/rc/v1/`, user in `captures/roku-lifetime-user.txt`), `loglevel` (proxy `/rc/v1/`).

## Contents

- `client/`: the Roku client (`source/main.brs`); `build.sh` adds an SDK revision's `Purchases.brs`.
- `captures/<scenario>-<before|after>/`: assertion-time screenshot, continuous recording, simulator console and result.
- `tests/`: suite logs for each fix branch with the fix and with upstream `Purchases.brs` (`run-roku-tests.sh`).
- `history/`: probe run against every release tag and the PR #12 boundary (`historical-probes.log`).
- `explainers/`: captioned explainer videos, transcripts and source manifest.
