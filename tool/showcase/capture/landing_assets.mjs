// Prepares the product shots the landing page embeds.
//
//   node landing_assets.mjs          # raw/**.png -> assets/showcase/*.webp
//
// Unlike the marketing compositions in compose.mjs these carry **no chrome of
// their own** — no browser bar, no phone body, no headline. The landing page
// draws the device frame in Flutter (`landing_device.dart`), so the same
// capture can appear at any size without its frame resampling with it, and a
// palette change to the site does not mean re-photographing the product.
//
// Output is WebP because the page ships over the web: a console capture is a
// ~500KB PNG and a ~150KB WebP at a quality no reader can tell apart on a
// screenshot of flat UI. `-sharp_yuv` is what keeps small Arabic text from
// fringing at these sizes.

import { execFileSync } from 'node:child_process';
import { existsSync, mkdirSync, statSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

// tool/showcase/capture → repo root
const REPO = resolve(dirname(fileURLToPath(import.meta.url)), '../../..');

const RAW = `${REPO}/showcase_assets/raw`;
const OUT = `${REPO}/assets/showcase`;
const CWEBP = '/opt/homebrew/bin/cwebp';

// Phones are captured at 390x844@3 and consoles at 1600x1000@2. Both are far
// larger than the page ever draws them, so each is resampled down to roughly
// twice its on-page size — enough for a retina panel, half the bytes.
const PHONE = [585, 1266];
const CONSOLE = [1760, 1100];

/// `dashboard-live-ops` is deliberately absent: its board photographs as a
/// flat grey rectangle under the harness (the capture is a 738KB PNG that
/// compresses to 27KB — the tell), so it is not a screen the site can show.
/** raw capture id → the name the landing page imports it under. */
const shots = [
  // The rider app.
  ['client/client-home', 'shot-client-home', PHONE],
  ['client/client-route-results', 'shot-client-search', PHONE],
  ['client/client-booking-seat', 'shot-client-seats', PHONE],
  ['client/client-trip-details', 'shot-client-trip', PHONE],
  ['client/client-tracking', 'shot-client-track', PHONE],
  ['client/client-wallet', 'shot-client-wallet', PHONE],

  // The captain app. `captain-trip-map` is deliberately absent: following a
  // vehicle on a map is a *rider* feature, and shipping the captain's own map
  // to the landing page told the reader the tracking story twice, once from
  // the wrong app. `shot-client-track` is the screen that claim belongs to.
  ['captain/captain-home', 'shot-captain-home', PHONE],
  ['captain/captain-trip-execution', 'shot-captain-trip', PHONE],

  // The office console.
  ['dashboard/dashboard-executive-overview', 'shot-console-overview', CONSOLE],
  ['dashboard/dashboard-home', 'shot-console-home', CONSOLE],
  ['dashboard/dashboard-trips', 'shot-console-trips', CONSOLE],
  ['dashboard/dashboard-routes', 'shot-console-routes', CONSOLE],
  ['dashboard/dashboard-bookings', 'shot-console-bookings', CONSOLE],
  ['dashboard/dashboard-fleet', 'shot-console-fleet', CONSOLE],
  ['dashboard/dashboard-finance', 'shot-console-finance', CONSOLE],
  ['dashboard/dashboard-finance-analytics', 'shot-console-analytics', CONSOLE],
];

mkdirSync(OUT, { recursive: true });

const missing = [];
let bytes = 0;

for (const [id, name, [w, h]] of shots) {
  const src = `${RAW}/${id}.png`;
  if (!existsSync(src)) {
    console.log(`MISS ${name.padEnd(24)} ${src}`);
    missing.push(id);
    continue;
  }
  const dst = `${OUT}/${name}.webp`;
  execFileSync(CWEBP, [
    '-q', '90',
    '-m', '6',
    '-sharp_yuv',
    '-resize', String(w), String(h),
    src,
    '-o', dst,
  ], { stdio: 'pipe' });
  const size = statSync(dst).size;
  bytes += size;
  console.log(`ok   ${name.padEnd(24)} ${w}x${h}  ${(size / 1024).toFixed(0)}KB`);
}

console.log(`\n${shots.length - missing.length}/${shots.length} written · ${(bytes / 1024 / 1024).toFixed(2)}MB total`);
if (missing.length) {
  console.log(`missing raw captures: ${missing.join(', ')}`);
  process.exit(1);
}
