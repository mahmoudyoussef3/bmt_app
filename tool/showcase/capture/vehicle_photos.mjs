// Draws the demo bus the rider app's vehicle gallery shows.
//
//   node vehicle_photos.mjs      # -> web/showcase/vehicles/*.webp
//
// Every other picture in this harness is a photograph of a real screen. These
// three are the deliberate exception, and they are drawings rather than
// photographs on purpose: the gallery's slot holds pictures an *operator*
// uploads against a fleet record, and the showcase has neither an operator nor
// a bus. A stock photograph of somebody's actual Hiace would put a real
// vehicle — and a real plate — into marketing material, so what goes in is an
// illustration of the van the app models, carrying the same invented plate as
// the rest of the demo data.
//
// The cabin view seats 2 + aisle + 1, which is the vehicle `VehicleSeatLayouts`
// describes; a picture of a 2+2 coach beside a Hiace seat map would be the
// screen contradicting itself.
//
// They live under `web/` rather than `assets/` because the gallery loads them
// through `Image.network`: the harness is a web build, so the files only have
// to be served alongside it — and this way three demo pictures never ship
// inside the mobile app bundle.

import { chromium } from 'playwright-core';
import { execFileSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, statSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { fileURLToPath } from 'node:url';
import { dirname, resolve, join } from 'node:path';

// tool/showcase/capture → repo root
const REPO = resolve(dirname(fileURLToPath(import.meta.url)), '../../..');
const OUT = `${REPO}/web/showcase/vehicles`;
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const CWEBP = '/opt/homebrew/bin/cwebp';

// The gallery draws at roughly 350x210 on a phone and covers its frame, so the
// pictures are authored 5:3 and shipped at about twice their on-screen size.
const W = 1200;
const H = 720;
const SHIP = [1000, 600];

const NAVY = '#004F7E';
const PLATE = 'ن ص ٤٢٧';

const defs = `
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#F1F5F9"/>
    <stop offset="1" stop-color="#DCE4EC"/>
  </linearGradient>
  <linearGradient id="body" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#FFFFFF"/>
    <stop offset="0.52" stop-color="#F2F6FA"/>
    <stop offset="1" stop-color="#D9E2EA"/>
  </linearGradient>
  <linearGradient id="glass" x1="0" y1="0" x2="0.4" y2="1">
    <stop offset="0" stop-color="#2C4157"/>
    <stop offset="0.55" stop-color="#1E2F41"/>
    <stop offset="1" stop-color="#16232F"/>
  </linearGradient>
  <linearGradient id="fabric" x1="0" y1="0" x2="0" y2="1">
    <stop offset="0" stop-color="#41566E"/>
    <stop offset="1" stop-color="#2B3B4E"/>
  </linearGradient>`;

/// One tyre with its rim, drawn over the body the way a van's wheels sit.
const wheel = (cx, cy, r) => `
  <circle cx="${cx}" cy="${cy}" r="${r}" fill="#1E2833"/>
  <circle cx="${cx}" cy="${cy}" r="${r * 0.98}" fill="none" stroke="#0F1720" stroke-width="2"/>
  <circle cx="${cx}" cy="${cy}" r="${r * 0.55}" fill="#DBE3EB"/>
  <circle cx="${cx}" cy="${cy}" r="${r * 0.55}" fill="none" stroke="#B4C1CE" stroke-width="3"/>
  <circle cx="${cx}" cy="${cy}" r="${r * 0.17}" fill="#A6B4C2"/>
  ${[0, 72, 144, 216, 288]
    .map((a) => {
      const rad = (a * Math.PI) / 180;
      return `<circle cx="${(cx + Math.cos(rad) * r * 0.36).toFixed(1)}" cy="${(
        cy +
        Math.sin(rad) * r * 0.36
      ).toFixed(1)}" r="${(r * 0.055).toFixed(1)}" fill="#9DABBA"/>`;
    })
    .join('')}`;

/// The van from the side — the shot an operator takes first.
const sideView = () => `
  <rect width="${W}" height="${H}" fill="url(#sky)"/>
  <rect y="628" width="${W}" height="92" fill="#CFD8E1"/>
  <ellipse cx="608" cy="634" rx="470" ry="26" fill="#0B1B34" opacity="0.17"/>

  <!-- one box, nose to tail: body, then everything that sits on it -->
  <path d="M 150 545 L 146 348 Q 144 316 168 300 L 296 214 Q 312 203 332 202
           L 1006 196 Q 1044 195 1050 228 L 1062 528 Q 1064 545 1046 545 Z"
        fill="url(#body)" stroke="#C2CDD9" stroke-width="3"/>

  <path d="M 150 452 L 1054 452 L 1056 492 L 150 492 Z" fill="${NAVY}"/>
  <path d="M 150 496 L 1056 496 L 1057 508 L 150 508 Z" fill="#2C89C4" opacity="0.85"/>

  <path d="M 190 332 Q 186 320 196 312 L 306 238 Q 316 231 330 231 L 376 231
           Q 386 231 386 241 L 386 322 Q 386 332 376 332 Z" fill="url(#glass)"/>
  ${[
    [406, 620],
    [634, 822],
    [836, 1004],
  ]
    .map(
      ([x1, x2]) =>
        `<rect x="${x1}" y="231" width="${x2 - x1}" height="101" rx="13" fill="url(#glass)"/>`,
    )
    .join('')}

  <!-- sliding door, and the seam of the one behind it -->
  <path d="M 626 231 L 626 545" stroke="#C7D1DC" stroke-width="3" fill="none"/>
  <path d="M 828 231 L 828 545" stroke="#C7D1DC" stroke-width="3" fill="none"/>
  <rect x="700" y="372" width="52" height="13" rx="6" fill="#BAC6D3"/>
  <rect x="884" y="372" width="52" height="13" rx="6" fill="#BAC6D3"/>

  <path d="M 149 378 L 196 374 Q 206 373 206 383 L 206 406 Q 206 416 196 415
           L 149 411 Z" fill="#E4F0F9" stroke="#AFC6DA" stroke-width="2"/>
  <rect x="149" y="424" width="38" height="13" rx="5" fill="#EFB63C"/>
  <path d="M 146 502 L 302 502 L 302 545 L 152 545 Q 144 545 144 532 Z"
        fill="#E3EAF1" stroke="#C7D1DC" stroke-width="2"/>
  <path d="M 198 302 L 166 292 Q 152 289 152 302 L 152 322 Q 152 334 166 331
           L 198 321 Z" fill="#D5DEE7" stroke="#BAC6D3" stroke-width="2"/>

  <path d="M 256 545 A 80 80 0 0 1 416 545" fill="none" stroke="#BDC9D5" stroke-width="5"/>
  <path d="M 820 545 A 80 80 0 0 1 980 545" fill="none" stroke="#BDC9D5" stroke-width="5"/>
  <rect x="416" y="527" width="404" height="20" fill="#B9C5D1"/>
  ${wheel(336, 552, 76)}
  ${wheel(900, 552, 76)}`;

/// Head on — the view that shows it is a van and not a car.
const frontView = () => `
  <rect width="${W}" height="${H}" fill="url(#sky)"/>
  <rect y="628" width="${W}" height="92" fill="#CFD8E1"/>
  <ellipse cx="600" cy="632" rx="330" ry="24" fill="#0B1B34" opacity="0.17"/>

  <rect x="286" y="470" width="86" height="158" rx="14" fill="#1E2833"/>
  <rect x="828" y="470" width="86" height="158" rx="14" fill="#1E2833"/>

  <path d="M 322 150 Q 322 120 354 118 L 846 118 Q 878 120 878 150
           L 900 556 Q 903 590 870 590 L 330 590 Q 297 590 300 556 Z"
        fill="url(#body)" stroke="#C2CDD9" stroke-width="3"/>
  <path d="M 340 128 L 860 128 L 862 150 L 338 150 Z" fill="#E6ECF2"/>

  <path d="M 346 172 Q 346 158 362 158 L 838 158 Q 854 158 854 172
           L 860 332 Q 861 348 844 348 L 356 348 Q 339 348 340 332 Z"
        fill="url(#glass)"/>
  <path d="M 372 340 L 470 168 L 540 168 L 440 340 Z" fill="#FFFFFF" opacity="0.07"/>
  <path d="M 392 330 L 470 200" stroke="#7E8FA0" stroke-width="6" stroke-linecap="round" opacity="0.7"/>
  <path d="M 560 330 L 638 200" stroke="#7E8FA0" stroke-width="6" stroke-linecap="round" opacity="0.7"/>

  <path d="M 302 296 L 258 284 Q 242 281 242 297 L 242 330 Q 242 346 258 342
           L 302 330 Z" fill="#D5DEE7" stroke="#BAC6D3" stroke-width="2"/>
  <path d="M 898 296 L 942 284 Q 958 281 958 297 L 958 330 Q 958 346 942 342
           L 898 330 Z" fill="#D5DEE7" stroke="#BAC6D3" stroke-width="2"/>

  <rect x="312" y="368" width="118" height="66" rx="16" fill="#D3E6F5" stroke="#9FBBD2" stroke-width="2"/>
  <circle cx="356" cy="401" r="21" fill="#F7FBFE" stroke="#A9C4D8" stroke-width="2"/>
  <circle cx="356" cy="401" r="9" fill="#BDD5E8"/>
  <rect x="386" y="386" width="34" height="30" rx="8" fill="#EFB63C" opacity="0.85"/>
  <rect x="770" y="368" width="118" height="66" rx="16" fill="#D3E6F5" stroke="#9FBBD2" stroke-width="2"/>
  <circle cx="844" cy="401" r="21" fill="#F7FBFE" stroke="#A9C4D8" stroke-width="2"/>
  <circle cx="844" cy="401" r="9" fill="#BDD5E8"/>
  <rect x="780" y="386" width="34" height="30" rx="8" fill="#EFB63C" opacity="0.85"/>

  <rect x="446" y="370" width="308" height="62" rx="14" fill="#22303F"/>
  <rect x="464" y="386" width="272" height="8" rx="4" fill="#4E5F72"/>
  <rect x="464" y="408" width="272" height="8" rx="4" fill="#4E5F72"/>
  <circle cx="600" cy="401" r="23" fill="${NAVY}"/>
  <circle cx="600" cy="401" r="23" fill="none" stroke="#F2F6FA" stroke-width="3"/>

  <path d="M 300 444 L 900 444 L 901 470 L 299 470 Z" fill="${NAVY}"/>
  <path d="M 299 474 L 901 474 L 902 486 L 298 486 Z" fill="#2C89C4" opacity="0.85"/>
  <path d="M 300 486 L 900 486 L 906 560 Q 908 590 878 590 L 322 590
           Q 292 590 294 560 Z" fill="#E5ECF2" stroke="#C7D1DC" stroke-width="2"/>
  <rect x="446" y="498" width="308" height="26" rx="9" fill="#22303F" opacity="0.85"/>
  <circle cx="360" cy="552" r="15" fill="#D3DDE7" stroke="#BAC6D3" stroke-width="2"/>
  <circle cx="840" cy="552" r="15" fill="#D3DDE7" stroke="#BAC6D3" stroke-width="2"/>
  <rect x="514" y="532" width="172" height="48" rx="9" fill="#FFFFFF" stroke="#B4C1CE" stroke-width="2"/>
  <text x="600" y="565" text-anchor="middle" font-size="27" font-weight="700"
        fill="#1E2833" font-family="'Cairo','Arial Unicode MS',sans-serif">${PLATE}</text>`;

/// Down the aisle: 2 + aisle + 1, which is the cabin the seat map draws.
///
/// One vanishing point, and every plane in the picture — walls, roof, floor,
/// each row of seats — is measured off the same pair of ramps, so the van
/// narrows the way a van does instead of the rows simply getting smaller.
const cabinView = () => {
  const vp = 600;
  const rows = 5;
  const wallX = 2.6;
  const lerp = (a, b, t) => a + (b - a) * t;
  const at = (t) => ({
    unit: lerp(232, 62, t),
    floor: lerp(772, 404, t),
    ceil: lerp(-44, 170, t),
  });
  const x = (world, t) => vp + world * at(t).unit;
  const y = (key, t) => at(t)[key];

  /// A surface swept between two depths, as a polygon: one edge along `y0`
  /// from near to far, the other back along `y1`.
  const sweep = (world0, y0, world1, y1) =>
    [0, 0.25, 0.5, 0.75, 1]
      .map((t) => `${x(world0, t).toFixed(1)},${y(y0, t).toFixed(1)}`)
      .concat(
        [1, 0.75, 0.5, 0.25, 0].map(
          (t) => `${x(world1, t).toFixed(1)},${y(y1, t).toFixed(1)}`,
        ),
      )
      .join(' ');

  // A window per bay, inset from the frame so the wall reads as structure.
  const windows = (world) =>
    [
      [0.0, 0.28],
      [0.32, 0.6],
      [0.64, 0.9],
    ]
      .map(([t0, t1]) => {
        const pt = (t, f) => {
          const { ceil, floor } = at(t);
          return `${x(world, t).toFixed(1)},${(ceil + (floor - ceil) * f).toFixed(1)}`;
        };
        return `<polygon points="${pt(t0, 0.14)} ${pt(t1, 0.14)} ${pt(t1, 0.5)} ${pt(
          t0,
          0.5,
        )}" fill="#CBE1F1" stroke="#A9C1D5" stroke-width="2"/>`;
      })
      .join('');

  const seat = (world, t) => {
    const { unit, floor } = at(t);
    const w = unit * 1.25;
    const h = unit * 1.55;
    const cx = x(world, t);
    const top = floor - h;
    return `
      <rect x="${(cx - w / 2).toFixed(1)}" y="${(top + h * 0.2).toFixed(1)}"
            width="${w.toFixed(1)}" height="${(h * 0.8).toFixed(1)}"
            rx="${(w * 0.16).toFixed(1)}" fill="url(#fabric)"/>
      <rect x="${(cx - w * 0.33).toFixed(1)}" y="${top.toFixed(1)}"
            width="${(w * 0.66).toFixed(1)}" height="${(h * 0.26).toFixed(1)}"
            rx="${(w * 0.14).toFixed(1)}" fill="#4E657F"/>
      <rect x="${(cx - w * 0.3).toFixed(1)}" y="${(top + h * 0.4).toFixed(1)}"
            width="${(w * 0.6).toFixed(1)}" height="${(h * 0.4).toFixed(1)}"
            rx="${(w * 0.1).toFixed(1)}" fill="#56708C" opacity="0.55"/>
      <rect x="${(cx - w / 2).toFixed(1)}" y="${(top + h * 0.9).toFixed(1)}"
            width="${w.toFixed(1)}" height="${(h * 0.055).toFixed(1)}"
            rx="${(h * 0.028).toFixed(1)}" fill="${NAVY}"/>`;
  };

  const bench = [];
  // Back to front, so a nearer row overlaps the one behind it.
  for (let i = rows - 1; i >= 0; i--) {
    const t = i / (rows - 1);
    bench.push(seat(-1.95, t), seat(-0.65, t), seat(1.85, t));
  }

  // The cabin ends in the front bulkhead, not in more cabin: without it the
  // aisle runs off into a tunnel and the picture stops being a vehicle.
  const bx0 = x(-wallX, 1);
  const bx1 = x(wallX, 1);
  const by0 = y('ceil', 1);
  const by1 = y('floor', 1);

  return `
    <rect width="${W}" height="${H}" fill="#DCE3EB"/>
    <polygon points="${sweep(-wallX, 'ceil', wallX, 'ceil')}" fill="#F2F5F9"/>
    <polygon points="${sweep(-0.3, 'ceil', 0.3, 'ceil')}" fill="#FBFCFE"/>
    <polygon points="${sweep(-wallX, 'floor', wallX, 'floor')}" fill="#D0D9E2"/>
    <polygon points="${sweep(-0.03, 'floor', 1.23, 'floor')}" fill="#BFCAD6"/>
    <polygon points="${sweep(-wallX, 'ceil', -wallX, 'floor')}" fill="#E4EAF1" stroke="#C4CFDA" stroke-width="2"/>
    <polygon points="${sweep(wallX, 'ceil', wallX, 'floor')}" fill="#DCE4EC" stroke="#C4CFDA" stroke-width="2"/>
    ${windows(-wallX)}
    ${windows(wallX)}
    <rect x="${bx0.toFixed(1)}" y="${by0.toFixed(1)}" width="${(bx1 - bx0).toFixed(1)}"
          height="${(by1 - by0).toFixed(1)}" fill="#E7ECF2" stroke="#C4CFDA" stroke-width="2"/>
    <rect x="${(bx0 + 12).toFixed(1)}" y="${(by0 + 14).toFixed(1)}"
          width="${(bx1 - bx0 - 24).toFixed(1)}" height="${((by1 - by0) * 0.42).toFixed(1)}"
          rx="8" fill="#CBE1F1" stroke="#A9C1D5" stroke-width="2"/>
    <rect x="${(bx0 + 20).toFixed(1)}" y="${(by0 + (by1 - by0) * 0.58).toFixed(1)}"
          width="${(bx1 - bx0 - 40).toFixed(1)}" height="${((by1 - by0) * 0.12).toFixed(1)}"
          rx="5" fill="#3B4E64"/>
    ${bench.join('')}
    <rect x="0" y="0" width="${W}" height="${H}" fill="url(#sky)" opacity="0.10"/>`;
};

const scenes = [
  ['hiace-side', sideView()],
  ['hiace-front', frontView()],
  ['hiace-cabin', cabinView()],
];

const page = (svg) => `<!doctype html><html><head><meta charset="utf-8">
<style>html,body{margin:0;padding:0;background:#fff}svg{display:block}</style>
</head><body>
<svg width="${W}" height="${H}" viewBox="0 0 ${W} ${H}" xmlns="http://www.w3.org/2000/svg">
  <defs>${defs}</defs>
  ${svg}
</svg>
</body></html>`;

mkdirSync(OUT, { recursive: true });
const scratch = mkdtempSync(join(tmpdir(), 'ewt-vehicles-'));

const browser = await chromium.launch({
  executablePath: CHROME,
  args: ['--force-device-scale-factor=1', '--font-render-hinting=none'],
});
const context = await browser.newContext({
  viewport: { width: W, height: H },
  deviceScaleFactor: 2,
  locale: 'ar-EG',
});

for (const [name, svg] of scenes) {
  const page_ = await context.newPage();
  await page_.setContent(page(svg), { waitUntil: 'load' });
  const png = `${scratch}/${name}.png`;
  await page_.screenshot({ path: png });
  await page_.close();

  const dst = `${OUT}/${name}.webp`;
  execFileSync(
    CWEBP,
    ['-q', '88', '-m', '6', '-sharp_yuv', '-resize', String(SHIP[0]), String(SHIP[1]), png, '-o', dst],
    { stdio: 'pipe' },
  );
  console.log(`ok   ${name.padEnd(14)} ${SHIP[0]}x${SHIP[1]}  ${(statSync(dst).size / 1024).toFixed(0)}KB`);
}

await browser.close();
console.log(`\n${scenes.length} written -> web/showcase/vehicles`);
console.log(`png intermediates: ${scratch}`);
