# Tracking User Stories

What each party needs from tracking, and whether the platform delivers it today.

Status key: **✅ delivered** · **◐ partial** · **○ not built** — with the gap named, never
implied. Cross-references: [TRACKING_ARCHITECTURE.md](TRACKING_ARCHITECTURE.md),
[TRACKING_STATUS.md](TRACKING_STATUS.md).

---

## Passenger

| # | Story | Status |
|---|---|---|
| P1 | As a passenger with a paid booking, I can watch my vehicle move on a map so I know when to be at the stop. | ✅ realtime INSERT stream + 8 s poll fallback |
| P2 | I see how far away the vehicle is and roughly when it arrives. | ✅ progress engine drives distance and ETA |
| P3 | I see which stop it is at now and which stops remain. | ✅ station timeline, seeded from captain arrival events |
| P4 | I can tell whether what I am looking at is *live* or a stale last-known position. | ✅ signal pill; age is derived from `recorded_at`, never from the socket |
| P5 | I can see the captain and vehicle I am waiting for. | ✅ name and rating; phone and plate never reach the Client app |
| P6 | I cannot be tracked by strangers, and I cannot track vehicles I have no booking on. | ✅ **Phase 6** — `can_read_trip_fixes`; before this, anyone with the app could |
| P7 | Tracking is unavailable until my payment is approved. | ✅ enforced in the database, not just by hiding the button |
| P8 | The map keeps working on a poor connection. | ◐ realtime + poll both degrade gracefully; no offline cache of the last fix across app restarts |
| P9 | I am told when the captain has not reported for a while, rather than watching a frozen marker. | ✅ staleness surfaces in the signal pill |
| P10 | I can reach support or the office from the tracking screen. | ✅ support entry points on the sheet |
| P11 | I get a push when my vehicle is approaching my stop. | ○ **not built** — arrival proximity notifications do not exist |

## Captain

| # | Story | Status |
|---|---|---|
| C1 | While driving a trip, my position is reported automatically without me touching anything. | ✅ 30 s cadence |
| C2 | Reporting does not stop because I scrolled the page, opened the map, or answered the office in chat. | ✅ **Phase 6** — publisher is an app-lifetime singleton; it used to die with the widget |
| C3 | Only one publisher ever runs, so my battery is not paying for duplicate GPS wake-ups. | ✅ **Phase 6** — was a `registerFactory`; every mount built another timer |
| C4 | I can push my position on demand when a passenger phones asking where I am. | ✅ manual send button |
| C5 | The card never claims tracking is fine when it is not. | ✅ health is computed from the last **landed** fix, not from whether a timer exists |
| C6 | If sends keep failing, I am told — not left to discover it. | ✅ **Phase 6** — a run of ≥2 consecutive failures is named explicitly |
| C7 | Coming back to the app after a call, reporting catches up immediately. | ✅ **Phase 6** — `resumeIfStale` on `AppLifecycleState.resumed` |
| C8 | Position keeps reporting while the app is minimised or the screen is locked. | ○ **not built** — foreground only; see [TRACKING_STATUS.md](TRACKING_STATUS.md) §R3. The app does not claim otherwise: a suspended app reads *stale*, in red, with the age of the last fix. |
| C9 | Fixes taken while offline are queued and sent when the signal returns. | ○ **not built** — a failed send is dropped and the next tick takes a fresh fix |
| C10 | I can see my own position and the route on a map in-app. | ✅ captain trip map, device GPS, display-only |
| C11 | I am warned when battery optimisation will interfere with tracking. | ○ **not built** |
| C12 | I cannot accidentally publish to a trip that is not mine. | ✅ refused by policy *and* by trigger; `driver_id` is stamped server-side |

## Office Operator

| # | Story | Status |
|---|---|---|
| O1 | I see every active trip in my office on one live board. | ✅ Live Operations Center |
| O2 | I see each vehicle's latest position on a fleet map. | ✅ via `dashboard_active_trip_fixes` |
| O3 | I can tell at a glance which trips are reporting and which have gone quiet. | ✅ LIVE / STALE / OFFLINE / UNKNOWN health badges |
| O4 | I see captain-filed incidents and SOS as they arrive. | ✅ incident queue with an acknowledge → resolve lifecycle |
| O5 | I cannot see, and am not seen by, any other office. | ✅ **Phase 6** — now enforced by RLS on the table itself, not only by the RPC |
| O6 | The incident queue cannot be wiped by a client-side caller. | ✅ **Phase 6** — TRUNCATE revoked; RLS never gated it |
| O7 | The board updates itself without me reloading. | ◐ polled, not subscribed — freshness is the poll interval |
| O8 | I can see where a vehicle *has been* over a trip, not just where it is. | ○ **not built** — the data exists but nothing draws a breadcrumb trail |
| O9 | I am alerted when a vehicle stops reporting, rather than having to notice a badge. | ○ **not built** — health is displayed, never pushed |

## Platform Admin

| # | Story | Status |
|---|---|---|
| A1 | I can see any office's live positions when investigating an incident. | ✅ `is_platform_admin()` is the one unscoped read |
| A2 | That access is deliberate and documented, not a side effect of an open table. | ✅ **Phase 6** — before this it was indistinguishable from everyone else's access, because there was none |
| A3 | Position history is retained for a bounded, chosen period. | ◐ `prune_trip_live_locations()` exists; **nothing schedules it** (no `pg_cron`) |
| A4 | I can audit who read a vehicle's position. | ○ **not built** — no read audit trail |

---

## What changed in Phase 6

| Story | Before | After |
|---|---|---|
| **P6** | Anyone holding the app could stream any vehicle on the platform | denied at the database |
| **O5** | Enforced only by the dashboard's RPC; the table itself was open to all | enforced by RLS on the table |
| **C2** | Reporting died silently when the captain left the trip screen | bound to the trip, not the screen |
| **C3** | Every card mount could add another publisher | structurally impossible — one singleton |
| **C6** | A run of failures looked the same as one | counted and named |
| **C7** | A resumed app waited out the interval | publishes immediately if stale |
| **O6** | Any signed-in user could TRUNCATE the incident queue | revoked |
| **A2** | No admin distinction existed, because nothing was restricted | explicit |
