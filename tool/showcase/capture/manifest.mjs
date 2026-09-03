// Builds the capture manifest: every showcase screen, at its platform's size.
//
//   node manifest.mjs > all.json

import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

// tool/showcase/capture → repo root
const REPO = resolve(dirname(fileURLToPath(import.meta.url)), '../../..');
const OUT = `${REPO}/showcase_assets/raw`;

// iPhone 14/15 logical size at 3x — the real device pixel grid.
const phone = (id, wait = 5000) => ({
  id,
  out: `${OUT}/${id.startsWith('client') ? 'client' : 'captain'}/${id}.png`,
  width: 390,
  height: 844,
  dpr: 3,
  wait,
});

// A desktop console viewport at 2x.
const desk = (id, wait = 6500) => ({
  id,
  out: `${OUT}/dashboard/${id}.png`,
  width: 1600,
  height: 1000,
  dpr: 2,
  wait,
});

const client = [
  'client-home',
  'client-offices',
  'client-office-profile',
  'client-route-results',
  'client-booking-trip',
  'client-booking-seat',
  'client-booking-package',
  'client-booking-summary',
  'client-booking-payment',
  'client-my-trips',
  'client-trip-details',
  'client-my-subscription',
  'client-wallet',
  'client-loyalty',
].map((id) => phone(id));
// The rider's live map draws real OSM tiles, so it gets longer to settle.
client.push(phone('client-tracking', 11000));

const captain = [
  'captain-home',
  'captain-trip-execution',
  'captain-passengers',
  'captain-notifications',
].map((id) => phone(id));
// The map draws real OSM tiles, so it gets longer to settle.
captain.push(phone('captain-trip-map', 11000));

const dashboard = [
  'dashboard-executive-overview',
  'dashboard-home',
  'dashboard-live-ops',
  'dashboard-trips',
  'dashboard-routes',
  'dashboard-bookings',
  'dashboard-fleet',
  'dashboard-finance',
  'dashboard-finance-analytics',
  'dashboard-finance-reports',
  'dashboard-wallet',
  'dashboard-reviews',
  'dashboard-office-profile',
  'dashboard-licensing-plans',
].map((id) => desk(id));

process.stdout.write(
  JSON.stringify([...client, ...captain, ...dashboard], null, 2),
);
