// Photographs the built landing page in real Chrome, at real fonts.
//   node shoot_landing.mjs <outDir> [width] [scrollStops...]
import { chromium } from 'playwright-core';

const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const OUT = process.argv[2];
const WIDTH = Number(process.argv[3] || 1440);
const STOPS = process.argv.slice(4).map(Number);

const browser = await chromium.launch({ executablePath: CHROME });
const ctx = await browser.newContext({
  viewport: { width: WIDTH, height: 950 },
  deviceScaleFactor: 1,
  locale: 'ar-EG',
});
const page = await ctx.newPage();
page.on('pageerror', (e) => console.log('JS  ' + String(e).split('\n')[0]));
await page.goto('http://localhost:8751/', { waitUntil: 'load', timeout: 60000 });
await page.waitForSelector('flutter-view, flt-glass-pane', { timeout: 60000 });
await page.waitForTimeout(7000);

for (const y of STOPS) {
  await page.mouse.move(WIDTH / 2, 500);
  await page.evaluate(() => {}); // keep the frame loop honest
  // The page scrolls a Flutter ScrollView, not the document.
  await page.mouse.wheel(0, y);
  await page.waitForTimeout(1600);
  const name = `${OUT}/w${WIDTH}_y${y}.png`;
  await page.screenshot({ path: name });
  console.log('ok  ' + name);
  await page.mouse.wheel(0, -y);
  await page.waitForTimeout(900);
}

await browser.close();
