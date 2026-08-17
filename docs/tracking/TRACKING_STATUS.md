# Tracking Status

Phase 6 — Live Tracking, Realtime, Customer Tracking Experience & Multi-Office Isolation.
2026-07-29.

Phase 7 — the real-time pipeline (2026-08-17) — is recorded in §"Phase 7" below and
documented in full in [TRACKING_LIVE_PIPELINE.md](TRACKING_LIVE_PIPELINE.md).

---

## Phase 7 — the real-time pipeline (2026-08-17)

### Built

| | |
|---|---|
| Captain publishing | 30 s pull → validated GPS stream + 10 s latest-value throttle + 30 s heartbeat |
| Validation | moved to the **producer**: junk, coarse, duplicate and teleporting fixes no longer cost a write |
| Client live axis | new `LiveTrackingBloc` (8 events, 6 states, per-event transformers) |
| Client polling | 8 s unconditional → **gated on realtime socket health**; zero periodic queries while connected |
| Connection state | `subscribe()` status surfaced as a domain enum for the first time — previously no call site read it |
| Freshness | now a modelled transition on its own timer, not a value recomputed by unrelated rebuilds |
| Rebuild boundaries | marker / pill / header / stops follow the vehicle; booking, crew and chrome do not |
| Migration drift | `can_read_trip_fixes` in the history was wider than the deployed function; repaired |

### Verified

| Check | Result |
|---|---|
| `flutter analyze` | **0 new issues** (5 pre-existing warnings in untouched captain files) |
| `flutter test` | **2406 pass / 11 fail** — the same 11 pre-existing failures in the same 7 files as before the phase (baseline was 2335 / 11). **+71 tests, 0 regressions** |
| `supabase/tests/tracking_authority_regression.sql` | **15 OK, 1 honest SKIP** |
| `supabase/tests/boarding_tracking_boundary_regression.sql` | **14 / 14 OK** (new) |
| Measured publish rate | 60 GPS readings in a minute → **7 writes** |

### Found while verifying

**The boarding rule was already enforced server-side** — the audit that opened this
phase read it off the migration file and concluded it was app-only. The deployed
`can_read_trip_fixes` admits a passenger only while their booking is `confirmed`. The
Dart comments asserting the database is the real boundary are accurate. What was
wrong was the **history**: `20260729090000_tracking_authority.sql` still records
`in ('confirmed','boarded','completed')`, so rebuilding the schema from migrations
would have produced a weaker boundary than the one in force.
`20260817120000_tracking_boundary_drift_repair.sql` restates the deployed definition
verbatim — a verified no-op against the linked database.

**Phase 6 probe 15 was a false positive waiting to happen.** "Another office reads
this fleet" resolved its foreign operator as *any* active `office_users` row in
another office. On a single-office dataset it skipped; the moment a second office
existed it picked a **platform admin** out of it and reported correct behaviour
(`is_platform_admin()` is the first arm of the helper, by design) as a cross-office
leak. The cast now excludes admins. Same family as the false positive documented in
that suite's own header.

### Open from this phase

**P1 — the one positive probe cannot run on current data · Low, data-dependent.**
Probe 05 ("a passenger who paid CAN watch their vehicle") skips: of the 10 trips
carrying live fixes, all 12 bookings are `cancelled`, `completed` or `reserved` —
none `confirmed`. The fixture now *prefers* a trip with a confirmed booking, so it
will run as soon as one exists, but the positive path is currently proven only by
inspecting the function definition and by the app-level suites, not by role
simulation against live rows.

**P2 — retention is now load-bearing, not optional.** See R2 below. The write rate
roughly tripled for a moving vehicle; `prune_trip_live_locations()` still has nothing
calling it.

**P3 — background tracking still absent.** Unchanged (R3). The pipeline is now
`getPositionStream`-based, which is the shape a foreground service would need, so the
remaining work is platform permissions and store justification rather than a rewrite.

---

## Completed

### Database — the read boundary (`20260729090000_tracking_authority.sql`)

| | |
|---|---|
| `can_read_trip_fixes(uuid)` | one definer helper answering "may this caller watch this trip?" for all four surfaces |
| `can_publish_trip_fix(uuid)` | the write question, mirroring the Phase 5 trigger |
| `trip_live_locations` | RLS **on**; `anon` SELECT revoked; read policy + captain-only insert policy |
| `trip_progress_events` | RLS **on**; `anon` full DML revoked (the sibling of the hole Phase 5 closed) |
| `prune_trip_live_locations(int)` | retention, `service_role` only, skips trips still running |

### Database — TRUNCATE hygiene (`20260729093000_tracking_truncate_hygiene.sql`)

TRUNCATE revoked from `anon` and `authenticated` on `driver_trip_reports`, `trip_events`,
`trip_route_points`, `trip_passengers`. RLS does not gate TRUNCATE; the policies on those tables
would not have stopped a caller emptying them.

### Captain — the publisher

| | |
|---|---|
| Ownership | `registerFactory` → `registerLazySingleton`; provided with `BlocProvider.value` |
| Survives | scrolling, rebuilds, navigation to the map or chat, backing out to the trip list |
| Stops on | the trip ending (`enabled: false`), and sign-out — nothing else |
| Duplicate timers | structurally impossible: one singleton, idempotent start, named stop |
| Trip switching | cancels the old timer; the previous trip cannot keep publishing |
| App resume | `resumeIfStale()` publishes at once if the last fix is older than the cadence |
| Failure honesty | consecutive failures counted; ≥ 2 in a row is named on the card |
| Clock | injected, so the resume threshold is testable without waiting |

### Comments that documented the old model

Four call sites asserted "trip_live_locations has no RLS by design". All corrected — a stale
security comment is worse than none, because the next engineer trusts it.

---

## Verified

| Check | Result |
|---|---|
| `supabase/tests/tracking_authority_regression.sql` | **17 probes, 17 green** (1 honest SKIP: single-office dataset) |
| `flutter analyze lib/` | **0 issues** |
| `flutter test test/apps/captain` | **292 / 292 pass** |
| `flutter test` (tracking + live_ops) | **132 / 132 pass** |
| `flutter test` (full suite) | **1423 pass, 1 fail** |

The single failure is `test/apps/client/support_ticket_details_test.dart` — a `pumpAndSettle`
timeout in the support-ticket screen. Confirmed **pre-existing**: it fails identically on a
clean worktree at `HEAD` (`f494923`), untouched by this phase.

New tests: `test/apps/captain/features/live_location/live_location_publisher_test.dart` — 9
tests covering publisher ownership, stop authority, resume behaviour and failure counting.

---

## Remaining risks

### R1 — TRUNCATE is still granted on ~45 other tables · **High severity, low reachability**

`anon` and `authenticated` hold TRUNCATE on most of `public`, including `operation_bookings`,
`booking_payments`, `clients`, `notifications`, `office_users`, `user_roles` and `admins`. RLS
does not gate it.

Not reachable over PostgREST (it issues no TRUNCATE). Becomes reachable if anything ever runs
caller-supplied SQL, any `SECURITY INVOKER` function uses dynamic SQL, or the database port is
exposed.

The remediation is one statement, and nothing legitimate would notice:

```sql
revoke truncate on all tables in schema public from anon, authenticated;
alter default privileges in schema public revoke truncate on tables from anon, authenticated;
```

Left for a dedicated grant-hygiene pass rather than applied platform-wide under a tracking
phase. **This is the single highest-value next action in the database.**

### R2 — Retention is not scheduled · **Medium → High since Phase 7**

`prune_trip_live_locations()` exists but nothing calls it: there is no `pg_cron` on this
project. Until something does, `trip_live_locations` grows without bound — and Phase 7
roughly **tripled the write rate for a moving vehicle** (2/min → ~6/min), so the
fifty-vehicle figure is now closer to 40–75M rows a year than 25M. Growth was a
documented risk before; it is now the direct cost of a shipped improvement, which
makes scheduling this the top action in the database.

Options: enable `pg_cron`; a Supabase scheduled Edge Function; or an external cron hitting an
RPC with the service key. **A capability the platform has but does not exercise is not a
mitigation.**

### R3 — Background tracking does not exist · **Medium, and a product decision**

A minimised or screen-locked captain app stops publishing. The app is honest about it — health
comes from the last landed fix, so a suspended app reads *stale* in red — but a passenger
watching that trip sees a frozen marker.

Real background tracking is not a small change:

- Android: a foreground service with a persistent notification, plus battery-optimisation
  exemption prompts.
- iOS: the `location` background mode, `allowsBackgroundLocationUpdates`, and an App Store
  review justification for continuous background location.
- Both: a new permission tier (`Always` rather than `While Using`), which materially lowers
  opt-in rates, and a rewrite of the publisher onto `getPositionStream` with a distance filter
  rather than a periodic `getCurrentPosition`.

Recommended shape when it is taken on: `flutter_background_geolocation` or a foreground service
via `flutter_foreground_task`, with the publisher's ownership rules (single publisher, named
stop, resume catch-up) carried over unchanged — they are what make it safe.

### R4 — Realtime delivery under RLS is unverified end-to-end · **Low**

The policy is proven correct by role simulation: as a paid passenger, the rows are readable;
as a stranger, they are not. Realtime evaluates the same policies as the same role, and the
policy body touches only the row's own `trip_id` — which is the shape Realtime needs.

What has not been observed is an actual socket delivering a row to a real device under the new
policy. **The consequence if it did regress is bounded**: the Client map falls back to the
existing 8-second poll, which is subject to the same policy and is verified working. The map
gets coarser, not dark.

Confirm on the next device run with an active trip.

**Phase 7 makes that confirmation cheap.** The channel's subscribe status is now
surfaced all the way to the UI, so a device run answers this by looking at the signal
pill: "Live" means the socket delivered, "Reconnecting" means it did not and the
catch-up poll is carrying the map. Before this there was no call site reading channel
status anywhere in the codebase, which is precisely why the question stayed open for
a phase and why the poll had to be unconditional.

### R5 — No offline queue on the captain side · **Low**

A fix taken with no signal is dropped; the next tick takes a fresh one. For live tracking this
is arguably correct — a stale position is worse than none — but it means a tunnel produces a
gap in the trip's record with nothing to backfill it.

### ~~R6 — The dashboard board polls rather than subscribes~~ · **CLOSED 2026-08-17**

Was: freshness is the poll interval, so the operator's view runs a poll behind the passenger's.
The stated justification — "one query beats N sockets" — was sound about *N* and wrong about
the alternative: the board does not need a socket per trip. `trip_live_locations` carries no
office column, so nothing can be filtered server-side anyway, and one **filterless**
subscription scoped by the RLS office arm delivers the whole fleet on a single channel.

Now: `FleetTrackingBloc` holds that one subscription, and the fixes RPC survives only as the
first-paint backfill and the catch-up read while the socket is unhealthy. While the link is
connected the desk issues **zero** periodic queries, down from three every 15 seconds.

The same change closed a drift nobody had filed: `TrackingHealth.liveWindow` was a local 75s
derived from a captain cadence of 30s that stopped existing when the publisher was throttled to
10s, so the board called a bus «حية» for half a minute after its own passengers were being
shown «تأخر الإشارة». It now reads `kLiveTrackingConfig.staleAfter`.

See [TRACKING_LIVE_PIPELINE.md](TRACKING_LIVE_PIPELINE.md) §3b.

### R7 — No read audit trail · **Low**

Nothing records who read a vehicle's position. With platform-admin access now being a
deliberate, unscoped capability, an audit trail is what would make it accountable.

---

## Recommendations, in order

1. **Sweep the TRUNCATE grants** platform-wide (R1). One migration, minutes of work, removes a
   whole class of future accident.
2. **Schedule retention** (R2). Pick a mechanism and a retention window; 7 days is the default
   the function ships with.
3. **Confirm realtime delivery** on a device with a live trip (R4). Cheap, and it closes the
   one thing this phase could not observe.
4. **Decide on background tracking** (R3) as a product question, not an engineering one — it
   costs a permission tier and an App Store justification.
5. Then the feature gaps: arrival proximity push, breadcrumb history, tracking-loss alerting.

---

## Business roadmap

| Horizon | Item | Value |
|---|---|---|
| Now | TRUNCATE sweep, scheduled retention | removes latent data-loss risk and unbounded growth |
| Next | Arrival proximity push | the single most-requested feature in ride tracking; passengers stop watching the map |
| Next | Tracking-loss alerting for operators | turns a badge someone must notice into an incident someone is told about |
| Later | Background tracking | removes the "frozen marker" class of complaint entirely |
| Later | Breadcrumb history + trip replay | dispute resolution, route optimisation, driver coaching |
| Later | Read audit trail | needed before the platform carries anyone's data under a formal privacy commitment |

---

## Performance notes

| Measure | Value |
|---|---|
| Publish cadence | throttled 10 s while moving; 30 s heartbeat while parked |
| Rows per vehicle per service day | ~2,000–4,300 depending on how much of it is moving |
| Client read pattern | 1 realtime subscription; **0** queries while the socket is healthy, 1 / 8 s while degraded |
| Dashboard read pattern | 1 realtime subscription for the whole fleet; **0** queries while healthy, 1 `distinct on` / 8 s while degraded |
| Index serving every read | `idx_trip_live_locations_trip_recent (trip_id, recorded_at desc)` |
| Current table size | 14 rows / 56 kB (development data) |
| Policy cost | one `STABLE SECURITY DEFINER` call per row per subscriber |

The policy call is the one new cost this phase introduces. It is `STABLE`, so the planner may
cache it within a statement, and it is index-backed on both arms. Worth re-measuring once the
table carries production volume — with retention scheduled (R2), it should stay small.
