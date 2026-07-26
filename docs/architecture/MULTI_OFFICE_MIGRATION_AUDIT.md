# EWT Multi-Office Migration — Audit Report (Step 2)

**Date:** 2026-07-21 · **Branch:** `new-system-model` · **Status:** audit only, no code changed.

**Baselines measured before any work:**
- `flutter analyze` → 25 issues, **all in `test/`** (pre-existing Remember Me drift). `lib/` is clean.
- `flutter test` → **617 passed / 78 failed** — the known pre-existing failure set.

Any regression is measured against these two numbers.

---

## 1. Current architecture summary

One Flutter package (`bmt_app`), three flavors, **one shared Supabase project**
(`nbwzourpbnmewwklewyr`, [app_flavor.dart:39](../../lib/core/flavors/app_flavor.dart#L39)).

```
lib/apps/{dashboard,client,captain}/   # three apps, feature-first Clean Architecture
lib/core/                              # flavors, DI helpers, network, notifications, theming,
                                       # tracking/progress engine, geo, pricing
```

Each app follows `features/<x>/{data,domain,presentation}`. The client app has its own authoritative
convention doc ([.claude/docs/CLIENT_APP.md](../../.claude/docs/CLIENT_APP.md)): **Supabase directly,
Cubit + plain `sealed class` states, no freezed, no `ApiResult`, no Retrofit** — the root `CLAUDE.md`
Retrofit/Dio stack does *not* apply under `lib/apps/client`. The dashboard and captain apps follow the
same de-facto stack.

**Critical structural finding:** all three apps use the **same global GetIt container**
(`GetIt.instance` — [client_di.dart:176](../../lib/apps/client/core/di/client_di.dart#L176),
[captain_di.dart:107](../../lib/apps/captain/core/di/captain_di.dart#L107),
[dashboard_di.dart:194](../../lib/apps/dashboard/core/di/dashboard_di.dart#L194)). `CLIENT_APP.md:102`
documents `GetIt.asNewInstance()` — that is **doc/code drift**. Every datasource and repository is a
`registerLazySingleton`; cubits are `registerFactory`. Nothing anywhere calls `unregister` or `reset`.

---

## 2. Current authentication flow

### Dashboard — **there is no authentication at all**

[main.dart:60](../../lib/apps/dashboard/main.dart#L60) mounts `home: const DashboardShell()`
unconditionally. There is no auth gate, no `onAuthStateChange` listener, no `currentSession` check —
unlike the client ([client_app.dart:160-165](../../lib/apps/client/client_app.dart#L160-L165)) and
captain ([captain/main.dart:159-163](../../lib/apps/captain/main.dart#L159-L163)) apps, which both have one.

`DashboardLoginScreen` is **dead code** — a repo-wide grep finds it only inside its own file. It would
have used **email**+password anyway
([dashboard_auth_datasource.dart:13-16](../../lib/apps/dashboard/features/auth/data/datasources/dashboard_auth_datasource.dart#L13-L16)),
not the name+password you want.

The identity chain that *does* run:

```
DashboardShell.initState                        dashboard_shell.dart:83-87
 → _loadRole()                                  dashboard_shell.dart:89-94
   → GetCurrentUserRoleUseCase → UsersRepository → SupabaseUsersDatasource.getCurrentUserRole
       uid = auth.currentUser?.id               users_datasource.dart:45
       if (uid == null) return null             users_datasource.dart:46   ← anon path
 → setState only if role != null                dashboard_shell.dart:92
 → catch (_) {}  swallows everything            dashboard_shell.dart:93
```

With no session the role stays `DashboardRole.admin`
([dashboard_shell.dart:78-80](../../lib/apps/dashboard/core/routes/dashboard_shell.dart#L78-L80)) →
**full navigation and full data access as the Postgres `anon` role**. `_loadRole()` runs once in
`initState` and never re-evaluates. Permissions
([dashboard_permission.dart:3-45](../../lib/apps/dashboard/core/permissions/dashboard_permission.dart#L3-L45))
are **UI nav filtering only** — no datasource or repository consults them.

### Client — real Supabase email/password
`signInWithPassword` / `signUp` / `resetPasswordForEmail`
([supabase_client_auth_datasource.dart:23,59,102](../../lib/apps/client/features/auth/data/datasources/supabase_client_auth_datasource.dart#L23)),
with a `clients` row guard and `check_phone_exists` RPC.

### Captain — phone-only, synthetic credentials (works, keep it)

```
phone → rpc resolve_captain_login          captain_auth_datasource.dart:16
      → signInWithPassword(email, secret)  :29     (signUp fallback :33)
      → rpc link_current_captain_driver    :47     → sets drivers.user_id = auth.uid()
```

The RPC ([20260708120000_captain_phone_login.sql:26-59](../../supabase/migrations/20260708120000_captain_phone_login.sql#L26-L59))
matches `drivers` on normalized phone + `status='active'` and returns
`login_email = <phone>@captain.bmt-app.internal` and `login_secret = hmac(phone,'bmt-captain-login-v1')`.
The migration header states plainly: **no proof-of-possession** — anyone who knows a captain's phone
number can obtain that captain's credentials. Accepted for one fleet; a cross-office risk with many.

---

## 3. Current database relationships

```
operation_routes ──< route_stations
       │
       └──< operation_trips ──< trip_route_points / trip_seats / trip_pricing / trip_events
                   │                              └──< trip_passengers
                   └──< operation_bookings ──< booking_payments, trip_reviews
drivers  (user_id UNIQUE → auth.users)  ──< driver_documents,  operation_trips.driver_id
vehicles                                ──< vehicle_documents, operation_trips.vehicle_id
assignments (driver ↔ vehicle only)
clients (id = auth.users.id) ──< operation_bookings, subscriptions, loyalty_*, referrals, support_tickets
```

**There is no root above `operation_routes`.** No `offices` table, no `office_id` column, in any `.sql`
file. `grep -rn "office" lib/ --include=*.dart` → **zero hits**.

Two parallel, unreconciled admin models:
- `public.user_roles(user_id, role)` + `has_role()` — [migration_01:25-41](../../migration_01_safe_schema_fixes.sql#L25-L41)
- `public.admins(user_id, role)` + `is_admin()` — [migration_03:8-28](../../migration_03_dashboard_rls.sql#L8-L28)

**Captain → trip is `operation_trips.driver_id` only.** The `assignments` table exists
([all_app_scheme.sql:134-140](../../all_app_scheme.sql#L134-L140)) but **no captain code touches it**,
and it maps driver↔vehicle, not driver↔trip.

### RLS reality

[all_app_scheme.sql:973-993](../../all_app_scheme.sql#L973-L993) **disables** RLS on 21 core
operational tables. Later migrations re-enable a few then re-disable others
(`subscriptions` → [20260706100000:19](../../supabase/migrations/20260706100000_subscriptions_open_for_dashboard.sql#L19),
`captain_requests` → [20260706090000:15](../../supabase/migrations/20260706090000_captain_requests_open_for_dashboard.sql#L15),
`operational_alerts` → [20260706140000:43](../../supabase/migrations/20260706140000_notification_event_engine.sql#L43)).

**RLS is not enabled at all on:** `trip_passengers`, `trip_route_points`, `trip_events`, `drivers`,
`vehicles`, `assignments`, `driver_documents`, `vehicle_documents`.

**Not one policy in the repo references a tenant.** Every admin policy asks "is this person a dashboard
admin *at all*", never "an admin *of this office*".

---

## 4. Everywhere the system assumes one office

### 4a. Dashboard — 28 relations + 6 views, essentially all unfiltered

Every list query is a full-table read. The worst offenders:

| Area | file:line | Leak |
|---|---|---|
| Bookings | `supabase_bookings_datasource.dart:19-22`, `:108-111` | full table + full-table realtime stream |
| Fleet | `supabase_fleet_datasource.dart:58-77` | all drivers, vehicles, assignments, **both document tables with no filter whatsoever** |
| Routes | `supabase_routes_datasource.dart:26-34` | all routes **and every station of every route**, grouped client-side |
| Trips | `supabase_trips_datasource.dart:19-32` | full table **plus the entire seat/passenger/event graph, no limit** |
| Trips pickers | `:541-563`, `:573-576` | driver / vehicle / route pickers span all offices |
| Trips conflict check | `:590-616` | duplicate detection runs against other offices' trips |
| Trips realtime | `:676-694` | subscribes to every row change platform-wide |
| Reports | `supabase_reports_datasource.dart:271-289` | filter dropdowns leak **every driver name and plate number** |
| Tickets | `supabase_tickets_datasource.dart:12-18`, `:125-129` | all tickets + client PII; agent picker lists every office's staff |
| Subscriptions | `supabase_subscriptions_datasource.dart:128-132` | customer PII picker across all offices |
| Users | `users_datasource.dart:15-23`, `:30-40` | full staff directory; **any admin can re-role or delete another office's staff** |
| Alerts | `supabase_operational_alerts_datasource.dart:50-54` | `markAllRead` mass-updates **every unread alert in the table** |
| Referrals | `supabase_referral_datasource.dart:29-58` | `referral_rewards` is a **hardcoded singleton row `id=1`** — any office overwrites everyone's reward config |
| Payments | `booking_payments_store.dart:78-92` | reassign-target list spans all offices → `reassign_booking` is a **cross-office move vector** |
| Plans | `subscription_plans_datasource.dart:46` | any office can delete another's package |
| Subscriptions | `supabase_subscriptions_datasource.dart:20` | `expire_overdue_subscriptions()` expires **every** office's subscriptions |

### 4b. Client — every discovery query is a global read (which is *almost* right, but nothing is attributable)

- Home: [supabase_home_datasource.dart:56-75](../../lib/apps/client/features/home/data/datasources/supabase_home_datasource.dart#L56-L75)
- Primary discovery: `supabase_booking_search_datasource.dart:17-168` (`operation_routes` where
  `status='active'`), trips batched at `:173-200`. Ranking is **client-side fuzzy text matching**
  (`:203-259`) with stopwords `{'of','the','and','egypt'}` (`:262`).
- **The Routes tab is not data-backed at all** — `supabase_routes_hub_datasource.dart:6-53` discards
  the injected `SupabaseClient` and returns a compile-time constant, including a hardcoded
  `'date': 'Today, Jun 3'`.
- Realtime subscribes to the **whole `operation_trips` table** unfiltered
  (`supabase_home_datasource.dart:29-45`, `supabase_trips_datasource.dart:150-155`).
- **No entity carries a provider.** `RouteOptionData` (`booking_option.dart:15-47`),
  `RouteTripOptionData` (`:69-99`), `UpcomingTripData`, `TripData`, `SeatSelectionData`,
  `TrackingTripData` — none has an office field. `BookingSearchQuery`
  (`booking_search_query.dart:2-61`) has no office filter param. `TripReview`
  (`trip_review.dart:6-65`) rates driver/vehicle/route — **there is no office rating dimension**.
- **Brittle single-operator coupling:** `tracking/data/models/tracking_state_model.dart:30-34` infers
  trip state by **literal Arabic string match** on `trip_events.title` (`'اكتملت الرحلة'`,
  `'غادرت الرحلة'`, …). This breaks the moment a second office words its events differently.
- Booking sends **`p_route` as free text `"A → B"`** (`wizard_booking_params.dart:10-34`), re-parsed in
  three places (`trip_mapper.dart:17-21`, `home_booking_model.dart:52-58`,
  `supabase_seat_release_datasource.dart:138-146`).

### 4c. Captain — already correctly scoped, but only by accident of `driver_id`

Home ([captain_trip_remote_datasource.dart:60-91](../../lib/apps/captain/features/assigned_trips/data/datasources/captain_trip_remote_datasource.dart#L60-L91))
filters `.eq('driver_id', driverId)`. History does the same. **There is no office-wide trip listing
anywhere in the captain app.**

> **This resolves the spec's open question in Part 3.** The implemented model is
> **captain-assigned trips**, via `operation_trips.driver_id`. `assignments` is unused for this.
> We implement captain-assigned, and add office as a *second* guard — not as the primary filter.

Trip-scoped screens accept **any `tripId` with no ownership guard**, and the tables they hit have no
RLS: `passenger_manifest_datasource.dart:19-28` (full manifest — names + phones), `:75-78` (update by
`trip_passengers.id` with no trip/driver check), `trip_execution_datasource.dart:194-199`,
`trip_status_datasource.dart:15-21`, `trip_history_datasource.dart:14-18`.

`supabase_chat_datasource.dart:77-86` streams ops broadcasts filtered **only** by
`sender_type='operations'` — no trip, no driver. Every operations message to any captain pops this
captain's snackbar (`captain_app_shell.dart:64-65`).

`supabase_location_datasource.dart:40-50` writes `driver_id`/`vehicle_id` **taken from the trip row,
not from the signed-in captain**.

### 4d. Cross-cutting

- `operational_alerts` — one global feed, RLS off, `grant select,insert,update,delete to anon`.
- Global catalogues with no scoping: `transport_packages`, `packages`, `payment_methods`,
  `promo_codes`, `loyalty_tiers`, `loyalty_rewards`, `referral_rewards`.
- Storage bucket `documents` is shared with **non-tenant-prefixed keys**
  (`fleet_document_manager.dart:117-124`).
- Client-generated colliding identifiers: trip code `'TR-${millis % 1000000}'`
  (`supabase_trips_datasource.dart:158`), package type `'custom_${title.hashCode}'`
  (`subscription_plan.dart:49-51`), `_nextDisplayOrder()` global max+1.

### 4e. Hardcoded IDs

**No hardcoded UUIDs, emails, or phone numbers exist in any of the three app trees.** The
single-office assumption is structural, not literal — which makes this migration cleaner than usual.

Literals that do exist: `referral_rewards` PK `1`; `'فريق المالية'` written as reviewer name into the
audit trail (`booking_payments_store.dart:41,48-49`); the `'documents'` bucket. In migrations there are
committed test accounts (`20260704114236_add_new_test_captain.sql:26-33` —
`new_captain@bmt-app.com`/`password123`/`+201111111111`) and a hardcoded driver UUID
(`20260703010000_link_emp1_captain_auth.sql:6`), plus the HMAC key `'bmt-captain-login-v1'` committed
in the repo.

---

## 5. Required database changes

### New tables

```sql
create table public.offices (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text unique not null,
  logo_url text,
  description text not null default '',
  phone text, email text,
  service_areas text[] not null default '{}',
  status text not null default 'active'
    check (status in ('active','paused','suspended','archived')),
  rating numeric(3,2) not null default 0,   -- trigger-maintained, mirrors drivers.rating pattern
  ratings_count int not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.office_users (
  id uuid primary key default gen_random_uuid(),
  office_id uuid not null references public.offices(id) on delete cascade,
  user_id uuid not null unique references auth.users(id) on delete cascade,
  username text not null,
  role text not null default 'dashboard_admin'
    check (role in ('dashboard_admin','support_agent')),
  status text not null default 'active' check (status in ('active','disabled')),
  created_at timestamptz not null default now()
);
create unique index uq_office_users_username on public.office_users (lower(username));
```

`user_id UNIQUE` = one dashboard user ↔ one office. `username` globally unique so name-only login
resolves with no office picker.

### `office_id` placement

**Direct column:** `operation_routes`, `drivers`, `vehicles`, `assignments`, `operation_trips`
(denormalised from route by trigger — so every trip query filters without a join),
`operation_bookings` (denormalised from trip — the dashboard's heaviest query), `captain_requests`,
`operational_alerts`, `support_tickets`, `refund_requests`, `transport_packages`, `packages`,
`package_vehicle_tiers`, `subscriptions`, `transport_subscriptions`, `promo_codes`.

**Derived through parent (no column, RLS joins up):** `route_stations`; `trip_seats` / `trip_pricing` /
`trip_events` / `trip_route_points` / `trip_passengers`; `booking_payments` / `trip_reviews`;
`driver_documents` / `vehicle_documents`; `trip_live_locations` / `trip_progress_events` /
`driver_trip_reports`.

**Platform-level, no `office_id`** (a passenger belongs to EWT, not to an office): `clients`,
`loyalty_*`, `referral_*`, `notifications`, `notification_tokens`, `notification_preferences`,
`payment_methods`.

### Unique constraints to re-scope

`(office_id, employee_code)`, `(office_id, vehicle_code)`, `(office_id, trip_code)`,
`(office_id, ticket_number)`, `(office_id, booking_number)`.
Leave `clients.phone` / `clients.email` globally unique.
**Open decision:** `drivers.national_id`, `drivers.license_number`, `vehicles.plate_number` — real-world
unique, but global uniqueness forbids a driver ever working for two offices.

### Also required

- `trip_events` needs a stable **`event_code`** column. The client currently infers state from Arabic
  title text (`tracking_state_model.dart:30-34`); that cannot survive multiple offices.
- `trip_code` generation must move server-side into `create_trip` (currently client-side, colliding).
- Storage keys must become office-prefixed.

---

## 6. Required backend / RLS changes

### Helpers (replace the global `is_admin()`/`has_role()`)

```sql
create or replace function public.current_office_id() returns uuid
language sql stable security definer as $$
  select office_id from public.office_users
   where user_id = auth.uid() and status = 'active' limit 1;
$$;

create or replace function public.captain_office_id() returns uuid
language sql stable security definer as $$
  select office_id from public.drivers
   where user_id = auth.uid() and status = 'active' limit 1;
$$;
```

### Policy shape

```sql
-- office-owned
create policy office_rw on public.operation_routes for all to authenticated
  using (office_id = public.current_office_id())
  with check (office_id = public.current_office_id());

-- client marketplace: public surface only
create policy public_read on public.operation_routes for select to anon, authenticated
  using (status = 'active'
     and exists (select 1 from public.offices o
                  where o.id = office_id and o.status = 'active'));
```

Captain reads: `office_id = public.captain_office_id()` **and** `driver_id = <own driver row>`.

### Must be closed

1. **`approve_payment` / `reject_payment` currently allow anon** — the guard is
   `if auth.uid() is not null and not is_admin() then raise`
   ([20260706120000:38-40](../../supabase/migrations/20260706120000_dashboard_approve_auth.sql#L38-L40),
   granted to `anon` at `:243-244`). Once the dashboard has a real login this reverts to requiring an
   authenticated office user **and** asserting the booking's `office_id = current_office_id()`.
2. **Revoke anon** from `expire_overdue_subscriptions`, `confirm_subscription_payment`,
   `request_subscription_renewal`, `consume_subscription_ride`
   ([20260706100000:139-142](../../supabase/migrations/20260706100000_subscriptions_open_for_dashboard.sql#L139-L142)).
3. **Enable RLS** on the eight tables that have none (`trip_passengers`, `trip_route_points`,
   `trip_events`, `drivers`, `vehicles`, `assignments`, `driver_documents`, `vehicle_documents`).
4. **`update_trip_status`** is `SECURITY DEFINER` and does not check the caller is the assigned driver
   ([migration_13:47](../../migration_13_open_for_booking_status.sql#L47)).
5. **`operational_alerts`** loses its anon grant, gains `office_id` + RLS; `push_operational_alert`
   must route to the owning office.
6. **`reassign_booking`** must assert source and target trips share one office.
7. `resolve_captain_login` should return only the matched office's captain and be rate-limited.

### Name+password login without adding phone/OTP/email UX

Supabase Auth needs an email internally. Mirror the pattern **already proven in this codebase** by
`resolve_captain_login`: a `SECURITY DEFINER resolve_office_user_login(p_username)` returns a synthetic
`login_email` (`<slug>@office.ewt.internal`). The user-facing form stays **Name + Password** — the
synthetic email never surfaces. Unlike the captain flow, the password is a real Supabase password, so
this *does* have proof-of-possession.

---

## 7. Required Dashboard changes

1. **Add the auth gate** — wrap `DashboardShell` in a session gate; revive `DashboardLoginScreen` as
   Name+Password. Replace `_role` defaulting to `admin` with role resolved from `office_users`, and
   subscribe to `onAuthStateChange` instead of a one-shot `initState` read.
2. **Introduce `DashboardSession`** (office id + role), registered in DI and injected into datasources.
   **This is the blocker:** every datasource is a `registerLazySingleton` constructed before login, so
   it cannot capture an office id known only afterwards. Either (a) inject a `DashboardSession` holder
   object read per call, or (b) `dashboardDi.reset()` + re-register on login. **(a) is preferable** —
   it is a smaller diff and does not risk the unguarded registrations in `trips_di.dart:28-124`, which
   throw if re-run.
3. **Add `.eq('office_id', session.officeId)`** to every list query in §4a, and stamp `office_id` on
   every insert. ⚠ **`SupabaseFleetDatasource._onlyAllowed()`
   (`supabase_fleet_datasource.dart:753-768`) whitelists columns** — an `office_id` added to a model's
   `toJson` will be **silently discarded** unless `_driverColumns`/`_vehicleColumns` are updated too.
4. Scope realtime channels per office (`'dashboard_trip_management'` → per-office channel name).
5. Fix `markAllRead` (`:50-54`) to scope by office.
6. `referral_rewards` singleton row `id=1` → per-office config row.
7. Make `OperationalAlertsBadgeCubit` (the **only** singleton cubit,
   `dashboard_di.dart:1432-1438`) office-aware and closable on logout.

## 8. Required Client App changes

1. **New `offices` feature** (`data/domain/presentation`) per `CLIENT_APP.md` conventions —
   plain sealed states, Supabase datasource, `clientGetIt` registration, scope in
   `client_cubit_scopes.dart`.
2. **Add `office` to `RouteOptionData` and `RouteTripOptionData`.** Because
   `route_selection_screen.dart:60-62` passes the whole `RouteOptionData` into the wizard and
   `BookingWizardCubit:10-11` seeds all wizard state from it, **office identity then propagates through
   the entire booking flow for free**. Models are hand-rolled (no `@JsonSerializable`) on this path, so
   **no `build_runner` run is needed**.
3. Join `offices` into the discovery queries — `supabase_seat_selection_datasource.dart:51` already
   selects `operation_routes (*)`, so the office lands there at no extra query cost.
4. Add the office badge to the UI slots: `trip_option_tile.dart:8` (prime slot),
   `route_card_header.dart:10`, `route_overview_header.dart:11`, `home_trip_card_header.dart:19`
   (existing badge slot `:47-54`), `trip_card.dart:12`, `summary_ticket_card.dart:16`.
5. **Replace Arabic-string state inference** (`tracking_state_model.dart:30-34`) with the new
   `trip_events.event_code`.
6. Add optional office filter to `BookingSearchQuery`; keep default = all offices.
7. Filter realtime subscriptions (currently whole-table).
8. Make the Routes tab data-backed, or leave it static and note it — currently it is a hardcoded
   constant pretending to be a datasource.
9. Office rating: `trip_reviews` has no office dimension. Aggregate office rating from its drivers'
   and vehicles' existing ratings, or add `office_rating` to `submit_trip_review`.

## 9. Required Captain App changes

Smallest of the three — the app is already `driver_id`-scoped.

1. **Introduce a real `CaptainSession`** holding `driverId` **and** `officeId`. Today
   `CaptainLocalSession` (`captain_session_store.dart:9-36`) has no office field and **no feature
   datasource reads it**; `resolveCaptainDriverId()` returns a bare `String?` and runs **three separate
   round-trips per screen load** with no caching.
2. Resolve office from `drivers.office_id` at login (`link_current_captain_driver` returns it).
3. Add office as a second guard on trip-scoped screens, and fix the queries that accept any `tripId`
   (§4c) — manifest read/update, trip events insert, trip stops.
4. Scope the ops-broadcast stream (`supabase_chat_datasource.dart:77-86`) by trip/driver.
5. Take `driver_id` from the session, not the trip row
   (`supabase_location_datasource.dart:40-50`).
6. **Clear the DI singleton cache on sign-out.** `CaptainTripRemoteDataSource` is a lazy singleton
   holding a mutable `_cachedDriverId` (`:15`) that survives sign-out — a second captain on the same
   device can subscribe with the previous captain's id. Same for the device-global prefs keys
   (`captain_seen_trip_ids` etc.).
7. Remove the shipped, non-debug-gated dev mode switcher (`assigned_trips_page.dart:100`).

## 10. Migration risks

| # | Risk | Mitigation |
|---|---|---|
| 1 | **Adding `NOT NULL office_id` breaks live apps mid-deploy** | Add nullable → backfill → set `NOT NULL`. Steps 1–5 are additive and safe while current apps run; only the RLS swap is a cutover. |
| 2 | **Turning on RLS silently empties screens** — 21 tables currently have it off and the dashboard runs as `anon` | Land RLS *last*, behind the dashboard login. Verify each module against the 617-test baseline. |
| 3 | **`_onlyAllowed()` column whitelist silently drops `office_id`** (`supabase_fleet_datasource.dart:753-768`) | Update `_driverColumns`/`_vehicleColumns` in the same commit. A silent drop would create unowned rows. |
| 4 | **Lazy-singleton datasources constructed pre-login** cannot see the office id | Inject a mutable session holder rather than capturing the id at construction. |
| 5 | **`trips_di.dart:28-124` has no `isRegistered` guards** — re-running DI throws | Rules out "re-register on login"; use the session-holder approach. |
| 6 | **Global UNIQUE collisions** (`trip_code`, `employee_code`, …) surface only when office #2 is created | Re-scope constraints in the same migration as the backfill; move `trip_code` generation server-side. |
| 7 | **Arabic-string state inference breaks with office #2** (`tracking_state_model.dart:30-34`) | Add `event_code` and backfill from existing titles before onboarding a second office. |
| 8 | **`approve_payment` anon path** must not survive the cutover | Close it in the same migration that adds the dashboard login, or payments become globally approvable. |
| 9 | **Captain credentials derivable from a phone number** | Pre-existing and accepted; document it. Consider rate-limiting `resolve_captain_login`. |
| 10 | **78 pre-existing test failures** could mask new breakage | Baseline is recorded above; compare exact counts, not pass/fail. |
| 11 | **`reassign_booking` / `expire_overdue_subscriptions`** are cross-office action vectors | Add office assertions inside the RPCs, not just in Dart. |

---

## Decisions — confirmed by the product owner, 2026-07-21

1. **Packages / fares / subscription plans / pricing rules are PER-OFFICE.** Offices compete on price.
   `transport_packages`, `packages`, `package_vehicle_tiers`, `promo_codes` and `subscriptions` all
   carry `office_id`; `trip_pricing` inherits through its trip.
2. **A driver belongs to exactly one office; a vehicle belongs to exactly one office.** No
   many-to-many. `national_id`, `license_number` and `plate_number` therefore stay **globally**
   unique. Office-internal codes (`employee_code`, `vehicle_code`, `trip_code`, `route_code`) become
   unique **per office**.
3. **Loyalty, referrals and wallet are PLATFORM-WIDE.** One EWT identity per client across the whole
   marketplace. `clients`, `loyalty_*`, `referral_*`, `notifications` and `payment_methods` carry no
   `office_id`. Bookings and payments still retain office context.
4. **Payment configuration is PER-OFFICE / per-merchant.** New `office_payment_configs` table holds
   `integration_id`, `iframe_id`, api key and HMAC secret. It is RLS-enabled with **zero policies**,
   so only `service_role` reads it; the Edge Function resolves the merchant account from the
   booking's office. The Client app no longer sends merchant credentials at all.
5. **The office is rated EXPLICITLY, never inferred** from driver or vehicle ratings.
   `trip_reviews.office_rating` is a new required dimension, and `submit_trip_review` derives the
   office from `booking → trip → route`, so a client cannot aim a review at an arbitrary office.

### Flagged assumption still open

`support_tickets.office_id` and `refund_requests.office_id` are **nullable**: a ticket about a
specific trip inherits that trip's office, while a general "the app crashed" ticket stays
platform-level (`office_id IS NULL`) and is invisible to every office. If instead every ticket must
belong to an office, these become `NOT NULL` and the Client app needs an office picker on the support
form. **Confirm before the Client app work lands.**

> **RESOLVED (2026-07-26).** With no platform-support console reading `office_id IS NULL` tickets,
> client complaints reached no one. Decision: every complaint must reach an office, and the client
> **picks the office** on the create-ticket form (migration
> `20260726120000_support_ticket_client_office_selection.sql` reworks `sync_support_ticket_office()`
> to honour a client-supplied `office_id` when it is a real, pickable office in `public_offices`; a
> linked booking/trip still overrides it). `office_id` stays nullable — the fallback remains
> platform-level for a caller who supplies no valid office. `refund_requests` was left unchanged
> (refunds grow from an already-attributed booking/ticket).

---

# Part 2 — Production-readiness verification (2026-07-21)

**Method:** read-only introspection of the live database via the Supabase Management
API. No mutation, no migration push, no test tenant was created.

## Environment: the premise was wrong

| Check | Result |
|---|---|
| `supabase branches list` | **empty** — no staging/preview branch exists |
| Active projects | **one**: `nbwzourpbnmewwklewyr` "Easy Way". Others are INACTIVE, unrelated apps |
| App flavors | client/captain/dashboard all point at that same project ([app_flavor.dart:39](../../lib/core/flavors/app_flavor.dart#L39)) |
| Migrations 20260721090000–090300 | **already applied** to it |
| Live data | 24 auth users (20 signed in ≤30d), 20 clients, 11 booking payments, 10 drivers, 31 bookings |

The four multi-office migrations went to **production**, not to a staging database.
Branch creation was attempted and refused: *"Branching is supported only on the Pro
plan or above."* Docker is not installed, so a local stack is not available either.

## Findings on the live database

**F1 — anon-executable payment approval (critical).** `approve_payment(uuid, **uuid**)`
and `reject_payment(uuid, **uuid**, text)` are pre-office SECURITY DEFINER overloads
with no ownership check. 090300's revoke list named only the `(uuid, text)` forms, so
these survived with EXECUTE granted to `anon` — and the publishable key ships in the
app binaries.

**F2 — anon-executable tenancy takeover (critical).**
`link_office_user(uuid, uuid, text, text, text)` grants office membership with a
caller-supplied role, and was executable by `anon`. It appears in no revoke list.

**F3 — `clients` RLS disabled (critical, pre-existing).** Three policies defined but
RLS off, and `anon` held SELECT/UPDATE/DELETE over every customer's name and phone.

**F4 — root cause.** `pg_default_acl` grants EXECUTE **explicitly to `anon`**, so
090300 loop 2's `revoke ... from public` never removed it. Every `office_*` wrapper
remained anon-callable (they fail closed, but EXECUTE is the boundary, not the body).
Loop 1 used `from public, anon, authenticated` and did work.

**F5 — captains cannot drive (live breakage).** 090300 revoked `update_trip_status`
from `authenticated`, but the Captain app calls it directly
([trip_execution_datasource.dart:207](../../lib/apps/captain/features/trip_execution/data/datasources/trip_execution_datasource.dart#L207)).
Start/complete trip is broken in production. Captains are not `office_users`, so the
`office_*` wrapper cannot serve them.

**F6 — platform config writable by anyone.** `referral_rewards_update` was
`USING true / WITH CHECK true` addressed to PUBLIC, with anon holding UPDATE.
`loyalty_accounts` and `loyalty_transactions` had RLS off and were anon-writable.

**F7 — report views unscoped.** `revenue_daily_view`, `drivers_performance_view`,
`vehicles_efficiency_view`, `complaints_summary_view` aggregate across every office and
are anon-SELECTable. A view owned by `postgres` is not constrained by base-table RLS,
so the `office_id` columns added in 090000 do nothing for them.

**F8 — `office_payment_configs` deny-all.** RLS on with zero policies; the Dashboard
cannot read its own payment configuration.

## Verified sound

- All 14 `office_*` wrappers exist remotely with the expected signatures.
- Every underlying RPC they delegate to exists; the `(uuid, text)`-named revokes landed.
- `office_users` holds one correct row (`mahmoud` / `dashboard_admin` / office `…e0`)
  bound to a real auth user; the migrated office `المكتب الرئيسي` is `status='active'`.
- Captain identity post-approval is resolved server-side from the `drivers` row and is
  never client-supplied — captain isolation after approval is structurally sound.
- The Dashboard now genuinely authenticates (`signInWithPassword` via
  `resolve_office_user_login`) and carries an office context.

## Remediation authored (NOT applied)

- `20260721100000_multi_office_security_hardening.sql` — F1–F6, F8, plus
  `platform_admins` / `is_platform_admin()` and a driver-scoped
  `captain_update_trip_status`.
- `20260721100100_report_views_office_scoping.sql` — F7, plus `operation_complaints.office_id`.
- `20260721100200_captain_office_join_code.sql` — office join codes for onboarding.

**These three migrations have never been executed anywhere.** No staging database was
available to validate them against.

---

# Part 3 — Remediation applied and verified (2026-07-21)

Completed in the same project (`nbwzourpbnmewwklewyr`) at the owner's direction, since
no staging database was obtainable (Free plan: no branching; Docker not installed).

**Method.** Every migration was first executed inside `BEGIN … ROLLBACK` against the
live database to prove it runs clean, then the full cross-office security suite was run
the same way — Office B, four test identities and all attack rows created and rolled
back, leaving no trace. Only after 73/74 passed were the migrations committed with
`supabase db push`.

## Suite result: 73 passed / 1 failed (74 assertions)

Covered: office A↔B read isolation; UPDATE/DELETE/INSERT by ID manipulation;
cross-office rejection of all seven `office_*` RPCs; raw-RPC reachability for anon and
authenticated; ownership-trigger override of a client-supplied `office_id`; captain
isolation; client public-vs-private separation; anon surface; platform-config
authorization; report scoping.

Two test-methodology corrections were needed and are worth remembering: RLS **filters
writes silently** rather than raising, so blocked mutations must be asserted on
`row_count`, not on an exception; and a revoked table privilege raises where an RLS deny
returns empty, so read assertions must accept either.

## Fixed and verified on the live database

| Was | Now |
|---|---|
| `approve_payment(uuid,uuid)` / `reject_payment(uuid,uuid,text)` anon-executable | anon **false**, authenticated **false** |
| `link_office_user` anon-executable (tenancy takeover) | anon **false**, authenticated **false** |
| `bulk_update_booking_status`, `broadcast_notification` anon-executable | both **false**; broadcast replaced by platform-admin-gated wrapper |
| `clients` RLS off, anon SELECT/UPDATE/DELETE | RLS **on**, anon **no** select/update; self + office-scoped policies |
| `loyalty_accounts` / `loyalty_transactions` RLS off, anon-writable | RLS **on**, anon locked out |
| `referral_rewards` writable by PUBLIC | RLS **on**, read public, writes require `is_platform_admin()` |
| `office_payment_configs` RLS on with 0 policies (deny-all) | office-scoped read + `dashboard_admin` write |
| Captains could not start/complete trips | `captain_update_trip_status` (asserts caller owns the trip); app repointed |
| Four report views unscoped and anon-readable | filtered to `current_office_id()`, anon revoked |
| Captain could name any office in a request | office join code decides the queue; code beats caller-supplied id |

`platform_admins` seeded with 1 row (the sole pre-existing office admin).
`offices.join_code` is unreadable by anon **and** authenticated via column privileges —
`public_offices` and `office_join_code()` are the only doors.

## Remaining blocker — RESOLVED (2026-07-21, migration 20260721110000)

**Was:** `operation_trips` exposed whole rows cross-office. The `trips_marketplace_read`
policy from 090200 permitted reading any trip in a marketplace-visible status from any
active office, and — RLS being row-level — handed out `revenue`, `driver_id`,
`vehicle_id`, `passenger_count`, `occupancy_rate` and `notes` with it. Two pre-office
SELECT policies ("Clients can read bookable/active trips", "Drivers can read their
assigned trips") had additionally survived 090200's drop list under their older names.

**Fix (`20260721110000_public_trips_marketplace_surface.sql`):**

- `public_trips` view (`security_invoker = false`, same mechanism as
  `public_offices`/`public_driver_profiles`): id, trip_code, office_id, route_id,
  dates/times, status, capacity, booked_seats, available_seats, ticket_price,
  currency, plus sanitised `drivers` / `vehicles` **jsonb** columns carrying exactly
  the public-profile field set (no phone, no plate, no ids). Column names match the
  old table embeds, so response shapes stayed byte-compatible.
- All three client-facing SELECT policies dropped from `operation_trips`; the base
  table now answers only to office operators and captains.
- `trip_seats` / `trip_pricing` / `trip_route_points` marketplace policies re-founded
  on the SECURITY DEFINER helper `trip_office_is_active(trip_id)` — their old
  predicates subqueried `operation_trips` under the caller's RLS, which would have
  evaluated empty once clients lost the base-table policy.
- Every client call site repointed to `public_trips` (booking search ×3, daily +
  vehicle booking, home, seat selection, tracking, My-Trips/profile booking embeds via
  the `operation_trips:public_trips(...)` alias). Client realtime invalidation moved
  off `operation_trips` (whose events no longer reach clients) onto `trip_seats` +
  `trip_events`; tracking already listened to `trip_events`, which
  `update_trip_status` writes on every transition.

**Verified 2026-07-21** with a 32-check REST-level E2E run as anon / signed-in client /
operator A / operator B (two active offices, disposable fixtures, since deleted):
discovery, multi-office marketplace, trip detail + seat map, lock → book →
`office_approve_payment` → confirmed, availability updates, My-Trips + profile shapes,
office A↮B isolation on trips/bookings/approvals, and column-probing denial of
`revenue`/`driver_id`/`vehicle_id`/`passenger_count`/`occupancy_rate`/`notes` for
clients. Full test suite unchanged at the pre-existing 78-failure baseline.

Known acceptable degradation: marketplace lists no longer receive realtime nudges for
pure status flips of unbooked trips (`trip_seats`/`trip_events` cover creation,
bookings and booked-trip lifecycle); the next screen entry refetches.
