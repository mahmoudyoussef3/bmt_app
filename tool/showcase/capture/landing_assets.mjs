// Renders the framed, transparent-background product shots the landing page
// embeds. Unlike the marketing compositions these carry no headline of their
// own — the page supplies the copy, the asset supplies the product.

import { chromium } from 'playwright-core';
import { writeFileSync, mkdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

// tool/showcase/capture → repo root
const REPO = resolve(dirname(fileURLToPath(import.meta.url)), '../../..');

const RAW = `${REPO}/showcase_assets/raw`;
const OUT = `${REPO}/assets/showcase`;
const BUILD = `${REPO}/showcase_assets/_build`;
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';

mkdirSync(OUT, { recursive: true });
mkdirSync(BUILD, { recursive: true });

const CSS = `
* { margin: 0; padding: 0; box-sizing: border-box; }
html, body { background: transparent; }
.win {
  background: #fff;
  border-radius: 14px;
  border: 1px solid #E2E8F0;
  box-shadow: 0 40px 90px -34px rgba(15, 23, 42, 0.36),
              0 12px 28px -14px rgba(15, 23, 42, 0.16);
  overflow: hidden;
}
.win .bar {
  height: 36px; display: flex; align-items: center; gap: 8px;
  padding: 0 14px; background: #F7F9FC; border-bottom: 1px solid #E2E8F0;
}
.dot { width: 10px; height: 10px; border-radius: 50%; background: #D3DAE5; }
.url {
  flex: 1; margin: 0 10px; height: 21px; border-radius: 6px;
  background: #fff; border: 1px solid #E2E8F0;
  display: flex; align-items: center; justify-content: center;
  font-family: -apple-system, system-ui, sans-serif; font-size: 11px; color: #94A3B8;
}
.win img { display: block; width: 100%; }
.phone {
  background: #0D1526; border-radius: 46px; padding: 9px;
  box-shadow: 0 34px 72px -24px rgba(15, 23, 42, 0.44),
              0 8px 20px -10px rgba(15, 23, 42, 0.22);
}
.phone .screen { border-radius: 38px; overflow: hidden; background: #fff; }
.phone .screen img { display: block; width: 100%; }
`;

const doc = (body, css = '') =>
  `<!doctype html><html><head><meta charset="utf-8"><style>${CSS}${css}</style></head><body>${body}</body></html>`;

const win = (src) => `<div class="win"><div class="bar">
  <i class="dot"></i><i class="dot"></i><i class="dot"></i>
  <div class="url">console.ewt.eg</div></div><img src="${src}"></div>`;

const phone = (src) => `<div class="phone"><div class="screen"><img src="${src}"></div></div>`;

const shots = [
  // The hero rig: console with a phone at each shoulder, nothing else.
  {
    name: 'ewt-ecosystem-devices',
    width: 1180,
    height: 620,
    body: `<div class="rig">
      <div class="desk">${win(`${RAW}/dashboard/dashboard-executive-overview.png`)}</div>
      <div class="ph a">${phone(`${RAW}/client/client-home.png`)}</div>
      <div class="ph b">${phone(`${RAW}/captain/captain-trip-map.png`)}</div>
    </div>`,
    css: `
      .rig { position: relative; width: 1180px; height: 620px; }
      .desk { width: 880px; margin: 0 auto; }
      .desk .win img { margin-bottom: -222px; }
      .ph { position: absolute; bottom: 0; width: 196px; }
      .ph.a { right: 0; }
      .ph.b { left: 0; }`,
  },
  ...[
    ['dashboard-executive-overview', 'ewt-shot-overview'],
    ['dashboard-live-ops', 'ewt-shot-liveops'],
    ['dashboard-finance', 'ewt-shot-finance'],
    ['dashboard-finance-analytics', 'ewt-shot-analytics'],
    ['dashboard-licensing-plans', 'ewt-shot-plans'],
    ['dashboard-fleet', 'ewt-shot-fleet'],
  ].map(([id, name]) => ({
    name,
    width: 1120,
    height: 736,
    body: `<div class="one">${win(`${RAW}/dashboard/${id}.png`)}</div>`,
    css: `.one { width: 1120px; } .one .win img { margin-bottom: -34px; }`,
  })),
  ...[
    ['client/client-home', 'ewt-shot-client'],
    ['captain/captain-trip-map', 'ewt-shot-captain'],
  ].map(([id, name]) => ({
    name,
    width: 320,
    height: 700,
    body: `<div class="one">${phone(`${RAW}/${id}.png`)}</div>`,
    css: `.one { width: 320px; }`,
  })),
];

const browser = await chromium.launch({ executablePath: CHROME });

for (const s of shots) {
  const file = `${BUILD}/landing__${s.name}.html`;
  writeFileSync(file, doc(s.body, s.css));
  const ctx = await browser.newContext({
    viewport: { width: s.width, height: s.height },
    deviceScaleFactor: 2,
  });
  const p = await ctx.newPage();
  await p.goto(`file://${file}`, { waitUntil: 'load' });
  await p.waitForTimeout(700);
  await p.screenshot({ path: `${OUT}/${s.name}.png`, omitBackground: true });
  console.log(`ok   assets/showcase/${s.name}.png`);
  await ctx.close();
}

await browser.close();
