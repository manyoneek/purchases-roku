// Usage: node run-scenario.cjs <app> <scenario> <userId> <proxyPath> <sdkLabel> <outDir>
const { chromium } = require('/opt/homebrew/lib/node_modules/openclaw/node_modules/playwright-core');
const fs = require('fs'), path = require('path');
const [app, scenario, userId, proxyPath, sdk, outDir] = process.argv.slice(2);
const apiKey = process.env.RC_TEST_STORE_KEY;
if (!apiKey) throw new Error('RC_TEST_STORE_KEY missing');
(async () => {
  fs.mkdirSync(outDir, { recursive: true });
  const browser = await chromium.launch({ executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', headless: true });
  const context = await browser.newContext({ viewport: { width: 1280, height: 720 }, recordVideo: { dir: outDir, size: { width: 1280, height: 720 } } });
  const page = await context.newPage();
  const consoleLines = [];
  page.on('console', (m) => consoleLines.push(m.text().replaceAll(apiKey, '<test-store-key>')));
  page.on('pageerror', (e) => consoleLines.push('pageerror: ' + e.message));
  const started = Date.now();
  await page.addInitScript((k) => { window.__rcKey = k; }, apiKey);
  const qs = new URLSearchParams({ app: app + '.zip', scenario, userId, proxyUrl: 'http://localhost:8787' + proxyPath, sdk });
  await page.goto('http://localhost:8787/?' + qs.toString());
  let outcome = 'none';
  for (let i = 0; i < 400; i++) {
    await page.waitForTimeout(100);
    const text = consoleLines.join('\n');
    if (text.includes('------ Finished')) {
      if (text.includes('EXIT_BRIGHTSCRIPT_CRASH')) outcome = 'crash';
      else if (text.includes('[repro] RESULT: PASS')) outcome = 'pass';
      else if (text.includes('[repro] RESULT: FAIL')) outcome = 'fail';
      else outcome = 'exit-without-result';
      break;
    }
  }
  await page.waitForTimeout(1500);
  await page.screenshot({ path: path.join(outDir, 'screenshot.png') });
  const video = page.video();
  await context.close();
  const videoPath = await video.path();
  fs.renameSync(videoPath, path.join(outDir, 'recording.webm'));
  await browser.close();
  const result = { app, scenario, userId, proxyPath, sdk, outcome, durationMs: Date.now() - started, finishedAt: new Date().toISOString() };
  fs.writeFileSync(path.join(outDir, 'console.log'), consoleLines.join('\n') + '\n');
  fs.writeFileSync(path.join(outDir, 'result.json'), JSON.stringify(result, null, 2));
  console.log(JSON.stringify(result));
})().catch((e) => { console.error(e); process.exit(1); });
