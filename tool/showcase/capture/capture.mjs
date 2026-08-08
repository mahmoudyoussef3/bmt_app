// Capture raw product screenshots from the EWT showcase web build.
//
//   node capture.mjs <manifest.json>
//
// Each manifest entry is { id, out, width, height, dpr, wait }. The script
// drives the real app in headless Chrome and writes one PNG per entry.

import { chromium } from 'playwright-core';
import { readFileSync, mkdirSync } from 'node:fs';
import { dirname } from 'node:path';

const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const BASE = process.env.SHOWCASE_BASE || 'http://localhost:8750';

const manifest = JSON.parse(readFileSync(process.argv[2], 'utf8'));

const browser = await chromium.launch({
  executablePath: CHROME,
  args: ['--force-device-scale-factor=1', '--font-render-hinting=none'],
});

let ok = 0;
const failures = [];

for (const shot of manifest) {
  const { id, out, width, height, dpr = 3, wait = 3500, theme } = shot;
  const context = await browser.newContext({
    viewport: { width, height },
    deviceScaleFactor: dpr,
    locale: 'ar-EG',
  });
  const page = await context.newPage();
  const errors = [];
  page.on('pageerror', (e) => errors.push(String(e).split('\n')[0]));

  const url = `${BASE}/?screen=${encodeURIComponent(id)}${theme ? `&theme=${theme}` : ''}`;
  try {
    await page.goto(url, { waitUntil: 'load', timeout: 60000 });
    // Flutter web mounts <flt-glass-pane>/<flutter-view> once the first frame
    // is up; the extra settle covers fonts, tiles and entry animations.
    await page.waitForSelector('flutter-view, flt-glass-pane', { timeout: 60000 });
    await page.waitForTimeout(wait);
    mkdirSync(dirname(out), { recursive: true });
    await page.screenshot({ path: out });
    console.log(`ok   ${id.padEnd(34)} -> ${out}`);
    ok++;
  } catch (e) {
    console.log(`FAIL ${id.padEnd(34)} ${String(e).split('\n')[0]}`);
    failures.push(id);
  }
  if (errors.length) {
    console.log(`     js: ${[...new Set(errors)].slice(0, 3).join(' | ')}`);
  }
  await context.close();
}

await browser.close();
console.log(`\n${ok}/${manifest.length} captured`);
if (failures.length) {
  console.log(`failed: ${failures.join(', ')}`);
  process.exit(1);
}
