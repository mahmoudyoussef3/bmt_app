// Builds the marketing and portfolio compositions from the raw screenshots.
//
//   node compose.mjs
//
// Each composition is an HTML page written next to the raw PNGs (so <img src>
// resolves), then photographed in headless Chrome at 2x. The product screens are
// never redrawn or retouched — the page only frames them.

import { chromium } from 'playwright-core';
import { writeFileSync, mkdirSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

// tool/showcase/capture → repo root
const REPO = resolve(dirname(fileURLToPath(import.meta.url)), '../../..');

const ROOT = `${REPO}/showcase_assets`;
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';

for (const dir of ['marketing', 'portfolio', '_build']) {
  mkdirSync(`${ROOT}/${dir}`, { recursive: true });
}

// ── Shared styling ──────────────────────────────────────────────────────────
//
// EWT's palette, taken from AppLightColors so the framing matches the product.
const CSS = `
:root {
  --primary: #2563EB;
  --deep: #4338CA;
  --page: #F4F7FB;
  --surface: #FFFFFF;
  --ink: #0F172A;
  --muted: #64748B;
  --line: #E2E8F0;
  --tint: #DBEAFE;
}
* { margin: 0; padding: 0; box-sizing: border-box; }
body {
  font-family: 'Cairo', -apple-system, system-ui, sans-serif;
  background: var(--page);
  color: var(--ink);
  -webkit-font-smoothing: antialiased;
}
.stage { position: relative; overflow: hidden; }
/* One restrained wash behind the product — no full-bleed gradient. */
.stage::before {
  content: '';
  position: absolute;
  inset: 0;
  background:
    radial-gradient(1100px 620px at 50% -8%, rgba(37, 99, 235, 0.09), transparent 70%),
    radial-gradient(760px 520px at 92% 104%, rgba(67, 56, 202, 0.05), transparent 72%);
}
.stage > * { position: relative; }

.eyebrow {
  font-size: 15px;
  font-weight: 700;
  letter-spacing: 0.16em;
  color: var(--primary);
  text-transform: uppercase;
}
h1 { font-size: 54px; line-height: 1.24; font-weight: 800; letter-spacing: -0.01em; }
h2 { font-size: 40px; line-height: 1.26; font-weight: 800; }
.sub { font-size: 21px; line-height: 1.6; color: var(--muted); font-weight: 500; }
.caption { font-size: 17px; font-weight: 700; }
.caption span { display: block; font-size: 14px; font-weight: 500; color: var(--muted); margin-top: 3px; }

/* ── Browser frame ── */
.win {
  background: var(--surface);
  border-radius: 14px;
  border: 1px solid var(--line);
  box-shadow: 0 40px 90px -30px rgba(15, 23, 42, 0.34),
              0 12px 28px -12px rgba(15, 23, 42, 0.14);
  overflow: hidden;
}
.win .bar {
  height: 38px;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 0 14px;
  background: #F7F9FC;
  border-bottom: 1px solid var(--line);
  direction: ltr;
}
.win .dot { width: 10px; height: 10px; border-radius: 50%; background: #D3DAE5; }
.win .url {
  flex: 1;
  margin: 0 10px;
  height: 22px;
  border-radius: 6px;
  background: var(--surface);
  border: 1px solid var(--line);
  display: flex;
  align-items: center;
  justify-content: center;
  font-family: -apple-system, system-ui, sans-serif;
  font-size: 11px;
  color: #94A3B8;
  letter-spacing: 0.01em;
}
.win img { display: block; width: 100%; }
.win.sm { border-radius: 11px; }
.win.sm .bar { height: 28px; padding: 0 10px; gap: 6px; }
.win.sm .dot { width: 7px; height: 7px; }
.win.sm .url { height: 17px; font-size: 9px; }

/* ── Phone frame ── */
.phone {
  position: relative;
  background: #0D1526;
  border-radius: 46px;
  padding: 9px;
  box-shadow: 0 34px 70px -22px rgba(15, 23, 42, 0.42),
              0 8px 20px -8px rgba(15, 23, 42, 0.20);
}
.phone .screen {
  position: relative;
  border-radius: 38px;
  overflow: hidden;
  background: #fff;
}
.phone .screen img { display: block; width: 100%; }
.phone.sm { border-radius: 34px; padding: 7px; }
.phone.sm .screen { border-radius: 28px; }
`;

const FONT =
  '<link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;500;600;700;800&display=swap" rel="stylesheet">';

const page = (title, body, css = '') => `<!doctype html>
<html lang="ar" dir="rtl"><head><meta charset="utf-8"><title>${title}</title>
${FONT}<style>${CSS}${css}</style></head><body>${body}</body></html>`;

const phone = (src, cls = '') => `
<div class="phone ${cls}">
  <div class="screen"><img src="${src}"></div>
</div>`;

const win = (src, cls = '', url = 'console.ewt.eg') => `
<div class="win ${cls}">
  <div class="bar"><i class="dot"></i><i class="dot"></i><i class="dot"></i>
    <div class="url">${url}</div></div>
  <img src="${src}">
</div>`;

// ── Compositions ────────────────────────────────────────────────────────────

const compositions = [];

// 1. Ecosystem hero — the dashboard carries the weight, the apps support it.
compositions.push({
  out: 'marketing/ewt-product-ecosystem',
  width: 1280,
  height: 900,
  html: page(
    'EWT ecosystem',
    `<div class="stage hero">
      <header>
        <p class="eyebrow">EWT · Easy Way Transportation</p>
        <h1>منصة واحدة تربط العملاء<br>والكباتن ومكاتب النقل</h1>
        <p class="sub">حجز الركاب، تشغيل الرحلات، وإدارة المكتب — في نظام واحد.</p>
      </header>
      <div class="rig">
        <div class="desk crop">${win('../raw/dashboard/dashboard-executive-overview.png')}</div>
        <div class="ph ph-a">${phone('../raw/client/client-home.png')}</div>
        <div class="ph ph-b">${phone('../raw/captain/captain-trip-map.png')}</div>
      </div>
      <div class="legend">
        <div><b>تطبيق العميل</b><span>يحجز ويتابع رحلته</span></div>
        <div><b>لوحة المكتب</b><span>تدير التشغيل والمال</span></div>
        <div><b>تطبيق الكابتن</b><span>ينفّذ الرحلة على الطريق</span></div>
      </div>
    </div>`,
    `
    .hero { width: 1280px; height: 900px; padding: 50px 64px 0; }
    .hero header { text-align: center; max-width: 880px; margin: 0 auto; }
    .hero .eyebrow { margin-bottom: 14px; }
    .hero .sub { margin-top: 18px; }
    .rig { position: relative; height: 462px; margin-top: 40px; }
    .desk { width: 792px; margin: 0 auto; }
    /* Show the top of the console rather than shrinking the whole page. */
    .desk.crop .win img { margin-bottom: -164px; }
    .ph { position: absolute; bottom: 0; width: 202px; }
    .ph-a { right: -16px; }
    .ph-b { left: -16px; }
    .legend {
      display: flex; justify-content: center; gap: 74px;
      margin-top: 40px; font-size: 14px;
    }
    .legend div { text-align: center; }
    .legend b { display: block; font-weight: 700; font-size: 15px; }
    .legend span { color: var(--muted); font-size: 13px; }
    `,
  ),
});

// 2. The two mobile apps, side by side.
compositions.push({
  out: 'marketing/ewt-client-captain',
  width: 1280,
  height: 880,
  html: page(
    'EWT mobile apps',
    `<div class="stage pair">
      <header>
        <p class="eyebrow">تطبيقان على الطريق</p>
        <h2>الراكب يحجز · الكابتن ينفّذ</h2>
      </header>
      <div class="row">
        <figure>
          ${phone('../raw/captain/captain-home.png')}
          <figcaption class="caption">تطبيق الكابتن<span>رحلات اليوم وحالة كل رحلة</span></figcaption>
        </figure>
        <figure>
          ${phone('../raw/client/client-home.png')}
          <figcaption class="caption">تطبيق العميل<span>البحث والحجز ومتابعة التذكرة</span></figcaption>
        </figure>
      </div>
    </div>`,
    `
    .pair { width: 1280px; height: 880px; padding: 52px 0 0; }
    .pair header { text-align: center; }
    .pair .eyebrow { margin-bottom: 12px; }
    .row { display: flex; justify-content: center; gap: 96px; margin-top: 40px; }
    figure { width: 268px; text-align: center; }
    figcaption { margin-top: 24px; }
    `,
  ),
});

// 3. The client journey, in the order a rider walks it.
compositions.push({
  out: 'marketing/ewt-client-journey',
  width: 1440,
  height: 780,
  html: page(
    'EWT client journey',
    `<div class="stage flow">
      <header>
        <p class="eyebrow">تجربة العميل</p>
        <h2>من البحث إلى التذكرة في أربع خطوات</h2>
      </header>
      <div class="row">
        ${['client-offices', 'client-route-results', 'client-booking-seat', 'client-trip-details']
          .map(
            (id, i) => `<figure>
          ${phone(`../raw/client/${id}.png`, 'sm')}
          <figcaption class="caption">${['يختار المكتب', 'يختار الخط والموعد', 'يختار مقعده', 'يستلم تذكرته'][i]}</figcaption>
        </figure>`,
          )
          .join('')}
      </div>
    </div>`,
    `
    .flow { width: 1440px; height: 780px; padding: 44px 0 0; }
    .flow header { text-align: center; }
    .flow .eyebrow { margin-bottom: 12px; }
    .row { display: flex; justify-content: center; gap: 44px; margin-top: 38px; }
    figure { width: 240px; text-align: center; }
    figcaption { margin-top: 20px; }
    `,
  ),
});

// 4. The captain's working surfaces.
compositions.push({
  out: 'marketing/ewt-captain-operations',
  width: 1280,
  height: 780,
  html: page(
    'EWT captain operations',
    `<div class="stage flow">
      <header>
        <p class="eyebrow">تطبيق الكابتن</p>
        <h2>المكتب متصل بمن يشغّل الرحلة</h2>
      </header>
      <div class="row">
        ${['captain-home', 'captain-trip-execution', 'captain-trip-map', 'captain-passengers']
          .map(
            (id, i) => `<figure>
          ${phone(`../raw/captain/${id}.png`, 'sm')}
          <figcaption class="caption">${['رحلات اليوم', 'تشغيل الرحلة', 'الخريطة المباشرة', 'قائمة الركاب'][i]}</figcaption>
        </figure>`,
          )
          .join('')}
      </div>
    </div>`,
    `
    .flow { width: 1280px; height: 780px; padding: 44px 0 0; }
    .flow header { text-align: center; }
    .flow .eyebrow { margin-bottom: 12px; }
    .row { display: flex; justify-content: center; gap: 34px; margin-top: 38px; }
    figure { width: 226px; text-align: center; }
    figcaption { margin-top: 20px; }
    `,
  ),
});

// 5. The console's breadth — six modules, not six tables.
const deskGrid = (ids, labels) =>
  ids
    .map(
      (id, i) => `<figure>
        ${win(`../raw/dashboard/${id}.png`, 'sm')}
        <figcaption class="caption">${labels[i]}</figcaption>
      </figure>`,
    )
    .join('');

compositions.push({
  out: 'marketing/ewt-dashboard-showcase',
  width: 1560,
  height: 2480,
  html: page(
    'EWT dashboard showcase',
    `<div class="stage grid">
      <header>
        <p class="eyebrow">لوحة تحكم المكتب</p>
        <h2>نظرة تنفيذية، تشغيل مباشر، ومال محسوب</h2>
        <p class="sub">ثماني وحدات من النظام — من مؤشرات المالك إلى محفظة العملاء.</p>
      </header>
      <div class="cells">
        ${deskGrid(
          [
            'dashboard-executive-overview',
            'dashboard-live-ops',
            'dashboard-trips',
            'dashboard-routes',
            'dashboard-fleet',
            'dashboard-bookings',
            'dashboard-finance',
            'dashboard-wallet',
          ],
          [
            'نظرة تنفيذية',
            'العمليات المباشرة',
            'إدارة الرحلات',
            'المسارات',
            'إدارة الأسطول',
            'الحجوزات',
            'المركز المالي',
            'محفظة العملاء',
          ],
        )}
      </div>
    </div>`,
    `
    .grid { width: 1560px; height: 2480px; padding: 52px 64px 0; }
    .grid header { text-align: center; }
    .grid .eyebrow { margin-bottom: 12px; }
    .grid .sub { margin-top: 14px; font-size: 18px; }
    .cells {
      display: grid; grid-template-columns: repeat(2, 1fr);
      gap: 46px 40px; margin-top: 48px;
    }
    figcaption { margin-top: 16px; text-align: center; font-size: 18px; }
    `,
  ),
});

// ── Portfolio ───────────────────────────────────────────────────────────────

// 6. Portfolio cover — what was built, across which platforms.
compositions.push({
  out: 'portfolio/ewt-overview',
  width: 1440,
  height: 856,
  html: page(
    'EWT — portfolio overview',
    `<div class="stage cover">
      <header>
        <p class="eyebrow">Transportation Management SaaS</p>
        <h1>EWT — Easy Way Transportation</h1>
        <p class="sub">A booking app, a driver app, and an operations console over one Supabase backend.</p>
        <ul class="chips">
          <li>Flutter · Client</li><li>Flutter · Captain</li>
          <li>Flutter Web · Dashboard</li><li>Supabase / PostgreSQL</li>
        </ul>
      </header>
      <div class="rig">
        <div class="desk">${win('../raw/dashboard/dashboard-home.png')}</div>
        <div class="ph ph-a">${phone('../raw/client/client-trip-details.png')}</div>
        <div class="ph ph-b">${phone('../raw/captain/captain-trip-execution.png')}</div>
      </div>
    </div>`,
    `
    .cover { width: 1440px; height: 856px; padding: 50px 72px 0; direction: ltr; }
    .cover header { text-align: center; max-width: 900px; margin: 0 auto; }
    .cover h1 { font-size: 50px; margin-top: 14px; }
    .cover .sub { margin-top: 16px; font-size: 20px; }
    .chips {
      list-style: none; display: flex; justify-content: center; flex-wrap: wrap;
      gap: 10px; margin-top: 24px;
    }
    .chips li {
      font-size: 13px; font-weight: 600; color: var(--primary);
      background: var(--tint); border-radius: 999px; padding: 7px 15px;
    }
    .rig { position: relative; height: 470px; margin-top: 30px; }
    .desk { width: 860px; margin: 0 auto; }
    .desk .win img { margin-bottom: -152px; }
    .ph { position: absolute; bottom: 0; width: 206px; }
    .ph-a { left: -22px; }
    .ph-b { right: -22px; }
    `,
  ),
});

// 7. Portfolio: the console in depth.
compositions.push({
  out: 'portfolio/ewt-dashboard',
  width: 1560,
  height: 2520,
  html: page(
    'EWT dashboard — portfolio',
    `<div class="stage grid">
      <header>
        <p class="eyebrow">Flutter Web · RTL · Arabic-first</p>
        <h2>EWT Dashboard</h2>
        <p class="sub">Operations, fleet, money and business intelligence in one console.</p>
      </header>
      <div class="cells">
        ${deskGrid(
          [
            'dashboard-executive-overview',
            'dashboard-live-ops',
            'dashboard-finance-analytics',
            'dashboard-finance-reports',
            'dashboard-wallet',
            'dashboard-licensing-plans',
            'dashboard-routes',
            'dashboard-bookings',
          ],
          [
            'Executive overview — نظرة تنفيذية',
            'Live operations — العمليات المباشرة',
            'Money analytics — التحليلات',
            'Financial statements — التقارير',
            'Customer wallets — محفظة العملاء',
            'SaaS plan catalogue — الخطط والباقات',
            'Route management — المسارات',
            'Booking operations — الحجوزات',
          ],
        )}
      </div>
    </div>`,
    `
    .grid { width: 1560px; height: 2520px; padding: 54px 64px 0; direction: ltr; }
    .grid header { text-align: center; }
    .grid h2 { margin-top: 10px; }
    .grid .eyebrow { margin-bottom: 4px; }
    .grid .sub { margin-top: 12px; font-size: 18px; }
    .cells {
      display: grid; grid-template-columns: repeat(2, 1fr);
      gap: 46px 40px; margin-top: 48px;
    }
    figcaption { margin-top: 16px; text-align: center; font-size: 16px; }
    `,
  ),
});

// 8. Portfolio: the two mobile apps in depth.
compositions.push({
  out: 'portfolio/ewt-mobile-apps',
  width: 1600,
  height: 800,
  html: page(
    'EWT mobile apps — portfolio',
    `<div class="stage flow">
      <header>
        <p class="eyebrow">Flutter · Cubit + Freezed · Clean Architecture</p>
        <h2>Client &amp; Captain apps</h2>
      </header>
      <div class="row">
        ${[
          ['client', 'client-home', 'Client · home'],
          ['client', 'client-booking-summary', 'Client · booking'],
          ['client', 'client-wallet', 'Client · wallet'],
          ['captain', 'captain-trip-map', 'Captain · live map'],
          ['captain', 'captain-passengers', 'Captain · manifest'],
        ]
          .map(
            ([app, id, label]) => `<figure>
          ${phone(`../raw/${app}/${id}.png`, 'sm')}
          <figcaption class="caption">${label}</figcaption>
        </figure>`,
          )
          .join('')}
      </div>
    </div>`,
    `
    .flow { width: 1600px; height: 800px; padding: 46px 0 0; direction: ltr; }
    .flow header { text-align: center; }
    .flow .eyebrow { margin-bottom: 8px; }
    .row { display: flex; justify-content: center; gap: 32px; margin-top: 44px; }
    figure { width: 250px; text-align: center; }
    figcaption { margin-top: 20px; font-size: 15px; }
    `,
  ),
});

// ── Render ──────────────────────────────────────────────────────────────────

const browser = await chromium.launch({ executablePath: CHROME });

for (const c of compositions) {
  const file = `${ROOT}/_build/${c.out.replace('/', '__')}.html`;
  writeFileSync(file, c.html);

  const context = await browser.newContext({
    viewport: { width: c.width, height: c.height },
    deviceScaleFactor: 2,
  });
  const p = await context.newPage();
  await p.goto(`file://${file}`, { waitUntil: 'load' });
  await p.evaluate(() => document.fonts.ready);
  await p.waitForTimeout(900);
  await p.screenshot({ path: `${ROOT}/${c.out}.png` });
  console.log(`ok   ${c.out}.png  (${c.width * 2}×${c.height * 2})`);
  await context.close();
}

await browser.close();
console.log(`\n${compositions.length} compositions rendered`);
