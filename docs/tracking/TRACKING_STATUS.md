# Tracking Status

Phase 6 — Live Tracking, Realtime, Customer Tracking Experience & Multi-Office Isolation.
2026-07-29.

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

### R2 — Retention is not scheduled · **Medium**

`prune_trip_live_locations()` exists but nothing calls it: there is no `pg_cron` on this
project. Until something does, `trip_live_locations` grows without bound — roughly 25M rows a
year for a fifty-vehicle fleet — and keeps a permanent movement history of every journey every
passenger has taken.

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

### R5 — No offline queue on the captain side · **Low**

A fix taken with no signal is dropped; the next tick takes a fresh one. For live tracking this
is arguably correct — a stale position is worse than none — but it means a tunnel produces a
gap in the trip's record with nothing to backfill it.

### R6 — The dashboard board polls rather than subscribes · **Low**

Freshness is the poll interval. Correct for a fleet-wide board (one query beats N sockets), but
it means the operator's view can be a poll behind the passenger's.

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
| Publish cadence | 30 s per active trip |
| Rows per vehicle per service day | ~1,400 |
| Client read pattern | 1 realtime subscription + 1 poll / 8 s, both `limit 1` |
| Dashboard read pattern | 1 `distinct on` per refresh for the whole fleet |
| Index serving every read | `idx_trip_live_locations_trip_recent (trip_id, recorded_at desc)` |
| Current table size | 14 rows / 56 kB (development data) |
| Policy cost | one `STABLE SECURITY DEFINER` call per row per subscriber |

The policy call is the one new cost this phase introduces. It is `STABLE`, so the planner may
cache it within a statement, and it is index-backed on both arms. Worth re-measuring once the
table carries production volume — with retention scheduled (R2), it should stay small.
