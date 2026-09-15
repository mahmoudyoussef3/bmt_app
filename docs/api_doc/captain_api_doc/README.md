# Captain App — API Reference (Supabase → .NET hand-off)

> **Scope:** every backend call the **Captain (driver) app** makes today.
> Source: `lib/apps/captain/` (package `bmt_app`), read at branch `api_docs`.
> Server-side rules: `supabase/migrations/` (latest definition of each function/view/policy wins).
> Companion: `docs/API_DOCUMENTATION.md` §9 (proposed endpoint names are kept consistent with its §11 index).

---

## 1. How the captain reaches the backend today

Same transport as the client: **no REST layer of our own**. The app holds the Supabase publishable
key and talks to Supabase through `supabase_flutter`, routed through the shared Dio instance
(`lib/core/network/dio_factory.dart` → `AppInterceptors`, wired in `lib/core/flavors/app_bootstrap.dart`
`_initializeSupabase`). Entry point: `lib/main_captain.dart` → `bootstrapFlavorApp(AppFlavor.captain)`.

```
Base URL (overridable by --dart-define CAPTAIN_SUPABASE_URL, default shared with the client):
  https://nbwzourpbnmewwklewyr.supabase.co

  /auth/v1/...                GoTrue        derived-credential sign-in / sign-up, sign-out
  /rest/v1/<table_or_view>    PostgREST     direct reads + the two direct writes (manifest status, GPS fix)
  /rest/v1/rpc/<function>     PostgREST     SECURITY DEFINER SQL functions = the business layer
  wss://.../realtime/v1/...   Realtime      5 Postgres-CDC subscriptions (see §4.5)
```

Config: `lib/core/flavors/app_flavor.dart` (`AppFlavorConfig.forFlavor(AppFlavor.captain)`, app name
`EasyWay Captain`, bundle `com.bmt.captain`). Timeouts: connect/receive/send 60 s (shared `ApiConstants`).
Reachability: `lib/apps/captain/core/network/captain_connectivity_watcher.dart` opens a TCP socket to
the Supabase host on :443 (5 s timeout, re-checked every 10 s offline / 60 s online) and drives the
offline banner — `NEEDS BACKEND DECISION`: point it at a cheap `/health` endpoint.

### 1.1 Headers on every request

Identical to the client (`apikey`, `Authorization: Bearer <access_token>` when a session exists,
`Content-Type`/`Accept: application/json`, PostgREST `Prefer` per call). Nothing captain-specific.

### 1.2 Identity — the captain is a `drivers` row, not the auth user

The auth user is a synthetic GoTrue account (`<normalized_phone>@captain.bmt-app.internal`) whose
only job is to carry `auth.uid()`. Everything the app and the database reason about is the
**`drivers` row bound to that uid** (`drivers.user_id = auth.uid()`, `status = 'active'`):

| Fact | Where it comes from | Used for |
|---|---|---|
| `driver_id` | RPC `link_current_captain_driver` (sign-in) or `captain_session_context` (restore) | every `driver_id=eq.` filter, every insert that carries `driver_id` |
| `office_id`, `office_name` | same RPCs | profile header; office-scoped RLS server-side |
| `full_name`, `phone`, `employee_code` | same RPCs | profile, welcome screens |
| `licensing {driver_app, live_tracking, in_flight, blocked, message_ar}` | `captain_session_context` only | app gate + GPS publisher kill-switch (§1.4) |
| `auth.currentUser.id` | JWT `sub` | `notifications.user_id`, `notification_tokens.user_id`, incident driver lookup |

Held in memory by `CaptainOfficeSession` (`lib/apps/captain/core/session/captain_office_session.dart`)
and resolved lazily by `CaptainIdentityProvider.ensure()`
(`captain_identity_provider.dart:13-20` → `_restore()` :34-45 → `POST rpc/captain_session_context`).
Every datasource that needs the driver id awaits `_identity.driverId()`; a null means "not a captain"
and the read returns `[]`.

Server-side the same binding is the RLS root: `current_driver_id()` and `captain_office_id()`
(`20260721090100_multi_office_identity.sql:43-70`) resolve `auth.uid()` → active `drivers` row, and
**every captain policy** is written against them. `NEEDS BACKEND DECISION`: the .NET token must carry
`driver_id` + `office_id` as claims (or `/api/v1/captain/session` must return them) and every captain
endpoint must derive the driver from the token — **no captain endpoint accepts a driver id as input**.

### 1.3 Session model (three layers — read this before `auth/` and `onboarding/`)

`_CaptainAuthGate` (`lib/apps/captain/main.dart:153-176`) picks the screen in this order:

1. **Supabase session exists** ⇒ `CaptainLicensingGate` ⇒ `CaptainAppShell` (the real app).
2. Else **local post-approval session** (`SharedPreferences` `captain_local_session`, written by
   onboarding when a request is approved) ⇒ `CaptainWelcomeHome`, which polls sign-in every 20 s
   until the driver row is active (`CaptainActivationCubit`).
3. Else **pending phone** (`captain_pending_phone`) ⇒ onboarding flow polling request status every 4 s.
4. Else the login screen.

All three EWT apps share one Supabase session store per device (see `project_shared_session_store`
memory): a restored client/dashboard session lands in branch 1, `captain_session_context` returns
`null` (no driver row for that uid), the identity provider yields `null`, and every read returns
empty. `NEEDS BACKEND DECISION`: audience-scoped tokens so a rider token is rejected by captain endpoints.

Sign-out (`CaptainAuthDatasource.signOut`) = `POST /auth/v1/logout` + clear the in-memory identity;
`_CaptainAuthGate` also stops the GPS publisher and clears the local session on `signedOut`.

### 1.4 Licensing (SaaS entitlement) — resolved server-side, never by the app

`captain_session_context` (`20260807140000_licensing_marketplace.sql:262-368`) returns a `licensing`
block computed from the office's plan/overrides (`platform_resolve_feature(office, 'driver_app' | 'live_tracking')`):

| Key | Meaning | App reaction |
|---|---|---|
| `driver_app` | office is licensed for the captain app | — |
| `live_tracking` | office is licensed for live GPS | `false` ⇒ `LiveLocationCubit` refuses to start/send (`live_location_cubit.dart:63-64, 86-90`) |
| `in_flight` | this driver has a trip in `boarding`/`in_progress` | — |
| `blocked` | `not driver_app AND not in_flight AND enforcement_mode = 'enforcing'` | `CaptainLicensingGate` replaces the shell with a blocked screen + retry + sign-out (`captain_licensing_gate.dart:30-39`) |
| `message_ar` | Arabic copy for the blocked screen | shown verbatim |

`BUSINESS RULE` — **the mid-trip exemption**: a captain already driving is never blocked, whatever the
office owes. The read policy on `trip_live_locations` is also licence-gated (`trip_tracking_licensed`),
but the INSERT policy deliberately is not: the app stops publishing from the licensing block instead
of the server refusing a moving bus. Port both halves exactly.

### 1.5 Error contract — keep the machine codes

SQL functions raise **bare exception names** (`not_your_trip`, `invalid_transition`,
`passengers_not_boarded:<n>`, …). The datasources match with `message.contains('<code>')` and, for the
station RPCs, split a `code:detail` suffix (`station_action_failure.dart:67-100`). **The .NET backend
must return these exact codes** as a stable `code` field; each feature file lists the codes it maps.
Two RPCs signal outcomes in the **body** instead of raising (`resolve_captain_login.outcome`,
`submit_captain_request.outcome`) — keep those shapes too.

---

## 2. Reading a feature file

Each `<feature>/README.md` has: **Overview** (screens, cubits, datasource files) → **Operations table**
(one row per backend call) → **per operation**: Dart call chain with `file:line`, the exact Supabase
request as sent, request params/body, response shape and which fields the app reads, business rules
from SQL, error codes, proposed .NET endpoint → **Realtime** where relevant → **Notes for the .NET team**.

---

## 3. Feature index

| Feature folder | What it covers | Backend touchpoints |
|---|---|---|
| [auth](auth/README.md) | phone-only sign-in (derived credentials), driver binding, session restore + licensing, sign-out, Remember-Me | RPCs `resolve_captain_login`, `link_current_captain_driver`, `captain_session_context`; GoTrue |
| [onboarding](onboarding/README.md) | self-service join request (office list + join code), status polling, post-approval activation polling | `public_offices`; RPCs `submit_captain_request`, `get_captain_request_status`; then `auth/` sign-in |
| [splash](splash/README.md) | launch screen | **local only** |
| [assigned_trips](assigned_trips/README.md) | Home: today's/upcoming assigned trips with stops, headcounts, arrival floor; "new trip" badge; realtime refresh | `operation_trips` (+`operation_routes`, `vehicles`, `trip_route_points`, `trip_passengers`, `trip_events` embeds); channel `captain_assigned_trips:<driverId>` |
| [trip_execution](trip_execution/README.md) | the trip screen: start boarding / depart / complete, live snapshot, station-arrival shortcut | RPCs `captain_update_trip_status`, `captain_arrive_station`; `operation_trips` + `trip_live_locations` reads; channel `captain_trip_execution:<tripId>` |
| [station_progress](station_progress/README.md) | the station board: arrive / depart (boarding-gated) / no-show, riders at a station | `trip_station_progress` (+ realtime), `trip_passengers`; RPCs `captain_arrive_station`, `captain_depart_station`, `captain_resolve_no_show` |
| [passenger_manifest](passenger_manifest/README.md) | manifest list/search/filter, check-in (direct write), no-show (RPC), live manifest stream | `trip_passengers` (select/update/stream), `trip_route_points`; RPC `captain_resolve_no_show` |
| [live_location](live_location/README.md) | **the GPS publisher** — 10 s throttle / 30 s heartbeat, validation, licensing kill-switch | `trip_live_locations` INSERT, `operation_trips` (vehicle lookup) |
| [trip_map](trip_map/README.md) | captain in-app map (device GPS, display only) | **no writes of its own**; `RETIRED` route — nothing navigates to it |
| [incidents](incidents/README.md) | SOS / incident report | `drivers` (id lookup), `driver_trip_reports` INSERT |
| [trip_status_updates](trip_status_updates/README.md) | "report to operations" narrative events | `trip_events` INSERT |
| [notifications](notifications/README.md) | inbox stream, unread badge, mark read; FCM token registration | `notifications` (stream/update), `notification_tokens` (core `FcmService`) |
| [profile](profile/README.md) | driver profile + lifetime stats + last vehicle | `drivers`, `operation_trips` (+`trip_passengers`, `vehicles` embeds) |
| [trip_history](trip_history/README.md) | completed trips list + stops of one trip | `operation_trips` (+embeds), `trip_route_points` |

---

## 4. Master inventory (everything the captain touches)

### 4.1 RPCs (`POST /rest/v1/rpc/<name>`)

| RPC | Feature | Latest SQL definition | Grant | Status |
|---|---|---|---|---|
| `resolve_captain_login(p_phone)` | auth | `20260721090100_multi_office_identity.sql:271-313` | anon, authenticated | live — returns derived credentials (⚠ see auth/) |
| `link_current_captain_driver(p_phone)` | auth | `20260721090100_multi_office_identity.sql:320-370` | authenticated | live |
| `captain_session_context()` | auth (core identity) | `20260807140000_licensing_marketplace.sql:262-368` | authenticated | live — identity + licensing; binds driver on first restore |
| `submit_captain_request(p_full_name, p_phone, p_office_id, p_office_code)` | onboarding | `20260721100200_captain_office_join_code.sql:58-144` | anon, authenticated | live |
| `get_captain_request_status(p_phone)` | onboarding | `20260705120000_captain_access_requests.sql:119-152` | anon, authenticated | live — unauthenticated, phone-keyed |
| `captain_update_trip_status(p_trip_id, p_new_status, p_reason)` | trip_execution | `20260727160000_trip_lifecycle_authority.sql:572-604` → `update_trip_status` :125-380 | authenticated | live — the only way a captain moves a trip |
| `captain_arrive_station(p_trip_id)` | station_progress, trip_execution, trip_map | `20260811090000_station_boarding_authority.sql:526-593` | authenticated | live — no station argument, idempotent |
| `captain_depart_station(p_trip_id)` | station_progress | `20260819120000_station_departure_gated_on_boarding_only.sql:41-115` | authenticated | live — boarding-gated |
| `captain_resolve_no_show(p_trip_passenger_id, p_reason, p_note)` | station_progress, passenger_manifest | `20260811090000_station_boarding_authority.sql:698-780` | authenticated | live |

### 4.2 Tables / views read or written (`/rest/v1/<name>`)

| Name | Kind | Features | Captain access today (RLS) |
|---|---|---|---|
| `public_offices` | **view** (8 public columns of active+listed offices) | onboarding | anon + authenticated select |
| `operation_trips` | table | assigned_trips, trip_execution, live_location, profile, trip_history | `trips_captain_read` (`office_id = captain_office_id() AND driver_id = current_driver_id()`); `trips_captain_update` exists but `trg_enforce_trip_write_authority` **forbids every direct captain write** |
| `operation_routes` | table (embedded) | assigned_trips, trip_history | `routes_captain_read` (own office) |
| `vehicles` | table (embedded) | assigned_trips, profile, trip_history | `vehicles_captain_read` (own office) |
| `drivers` | table | profile, incidents | `drivers_self_read` (`user_id = auth.uid()`), select only |
| `trip_route_points` | table | assigned_trips (embed), passenger_manifest, trip_history | `trip_route_points_captain_read` (own trips) |
| `trip_passengers` | table | assigned_trips/trip_execution/profile/trip_history (embeds), passenger_manifest, station_progress | `trip_passengers_captain_read`; **update** via `trip_passengers_captain_board` (status `reserved`↔`confirmed` only) + column trigger `enforce_captain_manifest_scope` |
| `trip_events` | table | assigned_trips/trip_execution (embeds), trip_status_updates | `trip_events_captain_read`; **insert** via `trip_events_captain_append` (lifecycle `event_code`s denied) |
| `trip_station_progress` | table | station_progress | `trip_station_progress_read` via `can_read_trip_stations()`; **no write policy at all** |
| `trip_live_locations` | table | live_location (insert), trip_execution (read latest) | insert `trip_live_locations_captain_publish` (`can_publish_trip_fix`) + trigger `enforce_live_location_authorship`; read `can_read_trip_fixes() AND trip_tracking_licensed()` |
| `driver_trip_reports` | table | incidents | insert `driver_trip_reports_captain_file` (own trip, `status='pending'`); read own; no update/delete |
| `notifications` | table | notifications | own rows select/update + realtime stream |
| `notification_tokens` | table | notifications (core `FcmService`) | own rows (upsert/update) |
| `operation_bookings`, `trip_seats`, `trip_pricing` | tables | *not read directly* — appear only as unfiltered realtime subscriptions | `bookings_captain_read`, `trip_seats_captain_read`, `trip_pricing_captain_read` (own trips) |

### 4.3 GoTrue (auth) endpoints used

`POST /auth/v1/token?grant_type=password` (derived email + secret), `POST /auth/v1/signup`
(first sign-in only, with `data: {full_name, employee_code, role:'driver'}`), `POST /auth/v1/logout`,
plus the SDK's implicit refresh. No password reset, no OTP, no social.

### 4.4 Storage / Edge functions

**None.** The captain app uploads nothing and calls no Edge Function.

### 4.5 Realtime subscriptions

| Channel / stream | Feature | Tables watched | Filter | Reaction |
|---|---|---|---|---|
| `captain_assigned_trips:<driverId>` | assigned_trips | `operation_trips` (event `*`, `driver_id=eq.<driverId>`); `operation_bookings`, `trip_passengers`, `trip_events`, `trip_route_points`, `trip_seats` (event `*`, **unfiltered**) | RLS scopes delivery | re-fetch list, debounced 250 ms |
| `captain_trip_execution:<tripId>` | trip_execution | `operation_trips` UPDATE (`id=eq.`), `trip_passengers` `*` (unfiltered), `trip_events` `*` (unfiltered), `trip_live_locations` INSERT (`trip_id=eq.`) | | re-fetch snapshot, debounced 250 ms |
| `captain_station_progress:<tripId>` | station_progress | `trip_station_progress` `*` (`trip_id=eq.`) | | re-fetch board, debounced 200 ms |
| `.stream(primaryKey:['id'])` on `trip_passengers` | passenger_manifest | own trip's manifest (`trip_id=eq.`) | | re-fetch manifest |
| `.stream(primaryKey:['id'])` on `notifications` (×2) | notifications | own rows (`user_id=eq.`) | | inbox list + unread count |

`SUPABASE-SPECIFIC`: the unfiltered subscriptions are safe only because Realtime evaluates the
`*_captain_read` RLS policies per delivered row. In .NET, publish per-driver / per-trip groups
(SignalR) and never rely on the client to filter.

---

## 5. Cross-cutting vocabulary (exact wire values)

**`operation_trips.status`**: `scheduled` → `open_for_booking` → `boarding` → `in_progress` →
`completed`; `cancelled` from any non-terminal state. A captain may cause only `boarding`,
`in_progress`, `completed` (`captain_update_trip_status` allowlist). App enum `AssignedTripStatus`
maps unknown ⇒ `scheduled`.

**Captain stage (derived, app-side, `captain_trip_stage.dart`)**: `awaitingRelease` (scheduled),
`awaitingWindow` / `readyToBoard` (open_for_booking; boarding window opens **30 min** before
`departure_time`), `boarding`, `underway`, `finished`, `cancelled`. GPS publishing runs while
`stage.isLive` (= `boarding | underway`).

**`trip_passengers.status`**: `reserved` (expected) | `confirmed` (aboard) | `no_show` | `cancelled` |
`completed`. App enum `PassengerBoardingStatus`: `pending` ← `reserved`; `boarded` ← `confirmed|boarded`;
`absent` ← `no_show|absent`; `cancelled`. "Boarded" counts everywhere = `confirmed OR completed`.

**`trip_station_progress.status`**: `upcoming` | `arriving` | `waiting_for_passengers` | `departed`.
"Current station" = row with `actual_arrival_at NOT NULL AND actual_departure_at IS NULL`.

**`trip_events.title` load-bearing strings**: `وصول محطة` (station arrival marker, counted by all 3
apps — `kStationArrivalEventTitle`), and the narrative titles in `trip_status_updates/`. `event_code`
lifecycle values (`trip_published | boarding_started | trip_departed | trip_completed | trip_cancelled`)
are reserved for `update_trip_status`; captain inserts take the default `other`.

**`driver_trip_reports.report_type`**: `passenger_issue | vehicle_issue | delay | emergency |
route_blockage | other`; `status`: `pending | acknowledged | resolved | dismissed` (captain writes only `pending`).

**`no_show_reason`**: `did_not_arrive | cancelled_by_passenger | passenger_requested | other`
(`other` requires a note).

**Dates/times:** `trip_date` `yyyy-MM-dd`; `departure_time`/`arrival_time` Postgres `time` `HH:mm:ss`
(the app composes date+time locally, clamping bad values to 00:00); `arrival_offset`/`departure_offset`
on `trip_route_points` are **"HH:MM" durations from route start**, not clock times; timestamps ISO-8601
UTC, rendered local.

**Phone normalisation:** every phone-keyed RPC runs `normalize_egyptian_phone()` on both sides; the
app sends whatever the captain typed (digits only, `captain_input_formatters.dart`).
