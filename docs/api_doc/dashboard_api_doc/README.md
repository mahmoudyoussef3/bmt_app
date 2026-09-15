# Dashboard (Ops Console) — API Reference (Supabase → .NET hand-off)

> **Scope:** every backend call the **Ops Dashboard** (`lib/apps/dashboard/`, a Flutter **web** app,
> Arabic-only, RTL) makes today. Source read at branch `api_docs`. Server-side rules:
> `supabase/migrations/` (latest definition of each function/view wins) and `supabase/functions/`.
> Companion: `docs/API_DOCUMENTATION.md` §10 (narrative) and §11.5–11.6 (endpoint index — the
> proposed `/api/v1/...` names below are the same ones).

---

## 1. How the dashboard reaches the backend today

There is **no REST layer of our own**. The web app holds the Supabase publishable key and talks to
Supabase directly through `supabase_flutter`, routed through one Dio instance
(`lib/core/network/dio_factory.dart` → `AppInterceptors`, adapter `supabase_dio_adapter.dart`).

```
Base URL (all flavors; override with --dart-define DASHBOARD_SUPABASE_URL):
  https://nbwzourpbnmewwklewyr.supabase.co

  /auth/v1/...                 GoTrue         sign-in (password), sign-up, sign-out, refresh
  /rest/v1/<table_or_view>     PostgREST      direct reads/writes, always narrowed by RLS
  /rest/v1/rpc/<function>      PostgREST      SECURITY DEFINER SQL functions = the business layer (84 of them)
  /storage/v1/object/...       Storage        fleet documents, vehicle images, office logo
  /functions/v1/<name>         Edge Function  office-manage-user, platform-create-office
  wss://.../realtime/v1/...    Realtime       Postgres CDC (5 channels + 3 table streams)
```

Config: `lib/core/flavors/app_flavor.dart` (`AppFlavorConfig.forFlavor(AppFlavor.dashboard)`); bootstrap
in `lib/apps/dashboard/main.dart` (`Supabase.initialize` → `registerDashboardDependencies()` →
`_DashboardAuthGate`). Headers, timeouts and the generic HTTP error mapping are identical to the client app
(see `../client_api_doc/README.md` §1.1 / §1.5).

### 1.1 Identity: the office context is the whole model

After sign-in the app calls `current_office_context` **once** and holds the result in
`DashboardSession` (`lib/apps/dashboard/core/session/`). Everything else follows from it:

| Fact | Source | Used for |
|---|---|---|
| `office_id` | `office_users` row of `auth.uid()` | every scoped query (`.eq('office_id', session.officeId)`) **and** independently by RLS (`current_office_id()`) |
| `role` | `office_users.role` = `dashboard_admin` (المالك) \| `support_agent` (خدمة العملاء) | sidebar/permission gate (UX) — server re-checks with `office_role()` / `office_can()` |
| `is_platform_admin` | `platform_admins.user_id = auth.uid()` | shows the platform console; every platform RPC re-checks `is_platform_admin()` |
| `listing_status`, `office_name`, `logo_url`, `username`, `full_name` | `offices` + `office_users` | shell chrome |

**Rule for the .NET backend:** the office is **never a request parameter** (the one exception,
`dashboard_active_trip_fixes(p_office_id)`, verifies it server-side). Take the office, the role and the
platform-admin flag from the token; scope every query by them.

### 1.2 Authorization today = three ANDed predicates

```
may = role_permits ∧ office_entitled ∧ quota_allows
```

* **role** — UX table `DashboardPermissions` (`core/permissions/dashboard_permission.dart`; admin = everything,
  support agent = liveOps, bookings, tickets, reports, paymentVerification, notifications, customerWallets,
  customers). Server: RLS predicates with `office_role() = 'dashboard_admin'` on writes (fleet, offices,
  office_users, wallet policies, logo storage) and `office_can(capability)` inside the wallet/customer RPCs
  (`20260820150000_office_customers_module.sql:63`). **Most other office tables are still `FOR ALL` for both
  roles** (bookings, trips, routes, subscriptions, tickets, alerts) — the UI is the only gate there.
* **entitlement** — the office's plan (`platform_licensing/`), resolved by `office_entitlements()` into
  `EntitlementContext` (`core/entitlements/`). Client-side it is a **hint that fails open**; server-side
  every metered write is refused by a trigger (`drivers`, `vehicles`, `operation_routes`, `operation_trips`,
  `office_users`, `storage.objects`) or an `assert_feature()` inside an RPC (`office_dispatch_notification`,
  `office_consume_export`).
* **quota** — limit features (`max_drivers`, `max_vehicles`, `max_routes`, `max_admin_users`, `max_captains`,
  `max_trips_per_month`, `max_exports_per_month`, `max_storage_mb`, `logo_max_kb`), `stock` or `flow` meters.

### 1.3 The six licensing refusal codes (`core/entitlements/licensing_failure.dart`)

`not_authorized`, `feature_not_licensed`, `feature_dependency_blocked`, `quota_exceeded`,
`license_suspended`, `license_expired`. They arrive as a `PostgrestException` whose message contains the
code and whose `details` is the verdict JSON
`{ allowed, reason, feature|key, limit, used, plan_key, blocked_by }`. Every datasource runs
`LicensingGuard.check(error)` first; the shell then shows the upgrade card. **The .NET backend must return
these exact codes with the same verdict payload** (and through any proxy layer — the Edge Function forwards
Postgres `detail` for this reason).

### 1.4 Error contract — bare machine codes

Every RPC raises **bare exception names** (`cross_office_denied`, `booking_not_pending`,
`trip_not_publishable:no_pricing`, `refund_exceeds_payment`, …). Datasources match with
`message.contains('<code>')` and translate to Arabic. Each feature file lists its codes. The .NET backend
must return them as a stable `code` field; an unmapped code silently becomes a generic message.

### 1.5 Query caps (`core/query/dashboard_query_caps.dart`)

Lists read the **newest N rows** and flag `capReached`: bookings 2 000, trips 1 500, tickets 1 000,
subscriptions 1 500, reviews 1 500, finance ledger 3 000. Filtering, sorting and paging happen in Dart.
Server-side paging with server-side tallies is the target state (the customers and wallet modules already
do it via RPC `total + limit/offset`).

---

## 2. Session lifecycle & cross-cutting calls

| Moment | Calls | Documented in |
|---|---|---|
| App start | `auth.currentSession` (SDK cache) → `POST rpc/current_office_context` | `auth/` A5 |
| Sign-in | `rpc/resolve_office_user_login` → `POST /auth/v1/token?grant_type=password` → `rpc/current_office_context` (→ `rpc/register_office` once, if pending) | `auth/` A1–A3 |
| Sign-up | `POST /auth/v1/signup` → `rpc/register_office` → `rpc/current_office_context` | `auth/` A4 |
| Right after sign-in | `rpc/office_entitlements` (unawaited) + realtime channel `dashboard_entitlements_<office>` on `office_licenses`, `office_feature_overrides`, `platform_plan_features`, `platform_features` | §1.2, `office_billing/` |
| Shell mounted | `operational_alerts` stream (latest 100) + `count=exact` unread query | `notifications/` A1–A2 |
| Any export | `rpc/office_consume_export {p_kind: pdf\|excel\|csv}` | `bookings/` B11, `finance/` N6, `reports/` P9, `wallet/` W15 |
| Sign-out | `POST /auth/v1/logout`; session, entitlements, filter memory cleared | `auth/` A6 |

All three EWT apps share one Supabase session store per device (`SUPABASE-SPECIFIC`); a restored non-office
session fails `current_office_context` and is signed out. `NEEDS BACKEND DECISION`: audience-scoped tokens.

---

## 3. Feature index

| Feature folder | Sidebar | Roles | Backend touchpoints |
|---|---|---|---|
| [auth](auth/README.md) | login / sign-up | — | GoTrue; RPCs `resolve_office_user_login`, `current_office_context`, `register_office` |
| [dashboard_home](dashboard_home/README.md) | الرئيسية | both | composition over 8 use cases (no own calls) |
| [business_overview](business_overview/README.md) | نظرة تنفيذية | admin | composition over 11 use cases |
| [live_ops](live_ops/README.md) | العمليات المباشرة | both | `operation_trips`, `driver_trip_reports`; RPC `dashboard_active_trip_fixes`; realtime `trip_live_locations` |
| [trips](trips/README.md) | الرحلات | admin | `operation_trips` + children, `trip_pricing`, `trip_package_prices`, `transport_packages`, `drivers`, `operation_routes`, `route_stations`; RPCs `office_create_trip`, `office_update_trip_status`, `office_cancel_trip`, `office_close_stale_trip`; 2 realtime channels |
| [routes](routes/README.md) | المسارات | admin | `operation_routes`, `route_stations` (direct) |
| [bookings](bookings/README.md) | الحجوزات / مراجعة المدفوعات | both | `operation_bookings`, `operation_trips`; RPCs `office_approve_payment`, `office_reject_payment`, `office_request_payment_review`, `office_reassign_booking`; stream |
| [subscriptions](subscriptions/README.md) | الاشتراكات | admin | `subscriptions`, `subscription_ride_usage`, `packages`, `clients`, `transport_packages`; RPCs `office_expire_overdue_subscriptions`, `office_confirm_subscription_payment`, `office_request_subscription_renewal`, `office_consume_subscription_ride` |
| [customers](customers/README.md) | العملاء | both | 7 `office_customer*` RPCs (read-only) |
| [fleet](fleet/README.md) | إدارة الأسطول / السائقون / المركبات | admin (reads: both) | `drivers`, `vehicles`, `assignments`, `driver_documents`, `vehicle_documents`, `operation_trips`; Storage `documents`, `vehicle-images` |
| [captain_requests](captain_requests/README.md) | طلبات الكباتن | admin | `captain_requests` (+ stream) |
| [finance](finance/README.md) | المدفوعات | admin | `operation_bookings`, `subscriptions`, `refund_requests`, `wallet_transactions`; RPC `office_wallet_overview` |
| [wallet](wallet/README.md) | محفظة العملاء | both (writes: admin) | 14 `office_wallet_*` / `office_refund_*` RPCs; `refund_requests` |
| [tickets](tickets/README.md) | الشكاوى | both | `support_tickets`, `support_attachments`, `user_roles` (legacy) |
| [reviews](reviews/README.md) | التقييمات | admin | `trip_reviews` (+ stream) |
| [reports](reports/README.md) | التقارير | both | 4 views + `operation_trips`, `operation_bookings`, `subscriptions`, option lists |
| [notifications](notifications/README.md) | الإشعارات + bell | both | `operational_alerts` (stream); RPCs `office_dispatch_notification`, `platform_broadcast_notification` |
| [office_profile](office_profile/README.md) | ملف المكتب | admin | `offices`; RPCs `office_join_code_info`, `office_join_code`, `office_rotate_join_code`; Storage `office-logos` |
| [office_billing](office_billing/README.md) | الباقة والفوترة | admin | entitlement document; RPC `office_invoices` |
| [users](users/README.md) | المستخدمون والصلاحيات | admin | RPCs `get_dashboard_users`, `office_update_staff_role`, `office_set_staff_status`; Edge `office-manage-user`; `office_users` |
| [referrals](referrals/README.md) | برنامج الإحالة | admin | `referral_rewards`, `referrals`, `referral_codes`, `referral_reward_transactions`, views `referral_analytics`, `referral_leaderboard`, `clients` |
| [platform_admin](platform_admin/README.md) | مكاتب المنصة | platform admin | RPCs `platform_list_offices`, `platform_office_details`, `platform_office_analytics`, `platform_set_office_listing`, `platform_set_office_status`; Edge `platform-create-office` |
| [platform_licensing](platform_licensing/README.md) | الباقات والميزات / التراخيص / الفوترة والسجل | platform admin | 27 `platform_*` licensing RPCs |
| [settings](settings/README.md) | الإعدادات | admin | **local only** (theme) |

---

## 4. Master inventory (everything the dashboard touches)

### 4.1 RPCs (`POST /rest/v1/rpc/<name>`) — 84

**Session / identity:** `resolve_office_user_login` (anon), `current_office_context`, `register_office`,
`office_entitlements`, `get_dashboard_users`, `office_update_staff_role`, `office_set_staff_status`.

**Office operations:** `office_create_trip`, `office_update_trip_status`, `office_cancel_trip`,
`office_close_stale_trip`, `office_approve_payment`, `office_reject_payment`, `office_request_payment_review`,
`office_reassign_booking`, `office_expire_overdue_subscriptions`, `office_confirm_subscription_payment`,
`office_request_subscription_renewal`, `office_consume_subscription_ride`, `dashboard_active_trip_fixes`,
`office_dispatch_notification`, `office_consume_export`, `office_join_code`, `office_join_code_info`,
`office_rotate_join_code`, `office_invoices`.

**Wallet & refunds:** `office_wallet_overview`, `office_wallet_directory`, `office_wallet_summary`,
`office_wallet_ledger`, `office_wallet_refundable_bookings`, `office_cancelled_trips_with_refunds`,
`office_wallet_cashback`, `office_wallet_credit`, `office_wallet_debit`, `office_wallet_reverse`,
`office_wallet_set_status`, `office_wallet_verify_chain`, `office_refund_create`, `office_refund_decide`,
`office_refund_trip_batch`.

**Customers:** `office_customers_overview`, `office_customer_directory`, `office_customer_profile`,
`office_customer_trips`, `office_customer_subscriptions`, `office_customer_payments`, `office_customer_activity`.

**Platform (admins only):** `platform_list_offices`, `platform_office_details`, `platform_office_analytics`,
`platform_set_office_listing`, `platform_set_office_status`, `platform_broadcast_notification`,
`platform_feature_catalog`, `platform_upsert_feature`, `platform_set_feature_status`, `platform_list_plans`,
`platform_plan_detail`, `platform_save_plan`, `platform_clone_plan`, `platform_compare_plans`,
`platform_preview_plan`, `platform_list_licenses`, `platform_office_license`, `platform_assign_plan`,
`platform_set_license_status`, `platform_start_trial`, `platform_extend_trial`, `platform_set_override`,
`platform_clear_override`, `platform_billing_overview`, `platform_issue_invoice`,
`platform_record_payment`, `platform_void_invoice`, `platform_usage_report`, `platform_audit_log`,
`platform_licensing_health`, `platform_settings_read`, `platform_update_settings`,
`platform_run_licensing_lifecycle`, `platform_run_billing_cycle`.

Every `office_*` RPC resolves the office from `current_office_id()`; the raw underlying functions
(`approve_payment`, `update_trip_status`, `create_trip`, `reassign_booking`, `wallet_post_entry`, …) are
**revoked from `authenticated`** — the wrappers are the only door.

### 4.2 Tables / views read or written directly (`/rest/v1/<name>`)

| Name | Kind | Features | Dashboard access today |
|---|---|---|---|
| `offices` | table | office_profile | own row select (14 columns; `join_code*` revoked); admin update |
| `office_users` | table | users (role lookup) | own office select |
| `operation_trips` | table | trips, bookings, fleet, live_ops, subscriptions, reports | office `FOR ALL`; `status` write forbidden by trigger; delete guarded |
| `trip_route_points`, `trip_seats`, `trip_pricing`, `trip_package_prices`, `trip_passengers`, `trip_events` | tables | trips (+ reports, live_ops) | office `FOR ALL` through the trip |
| `operation_routes`, `route_stations` | tables | routes, trips, subscriptions, reports | office `FOR ALL` (both roles) |
| `transport_packages` | table | trips (fare menu), subscriptions/plans | office rows + marketplace read |
| `operation_bookings` | table | bookings, finance, reports, (customers via RPC) | office `FOR ALL`; status writes via RPC only in practice (notes column written directly) |
| `subscriptions`, `subscription_ride_usage`, `packages` (legacy) | tables | subscriptions, finance, reports | office `FOR ALL` / read |
| `drivers`, `vehicles`, `assignments`, `driver_documents`, `vehicle_documents` | tables | fleet, trips, live_ops, reports | read both roles; write **admin only** (RLS) |
| `captain_requests` | table | captain_requests | office `FOR ALL` |
| `driver_trip_reports` | table | live_ops | office manage |
| `trip_reviews` | table | reviews | office read (write via client RPC only) |
| `support_tickets`, `support_attachments` | tables | tickets | office `FOR ALL` (office-routed tickets only) |
| `operational_alerts` | table | notifications (shell bell) | office read + update |
| `refund_requests`, `wallet_transactions` | tables | finance (read), wallet (refund queue read) | office read; **no write policy** (RPC only) |
| `clients` | table | subscriptions (picker), referrals (names) | global read (no `office_id` on clients) |
| `referral_rewards`, `referrals`, `referral_codes`, `referral_reward_transactions` | tables | referrals | rider-owned RLS (see `referrals/`) |
| `user_roles` | table (legacy) | tickets (agent picker) | `RETIRED` source |
| `revenue_daily_view`, `drivers_performance_view`, `vehicles_efficiency_view`, `complaints_summary_view` | views | reports | office-scoped in their bodies; 3 gated by `office_licensed('reports')` |
| `referral_analytics`, `referral_leaderboard` | views | referrals | authenticated select (global) |

### 4.3 Storage buckets

| Bucket | Feature | Path | Read |
|---|---|---|---|
| `documents` | fleet | `<drivers\|vehicles>/<ownerId>/<type>/<epoch>_<name>` | public |
| `vehicle-images` | fleet | `vehicles/<vehicleId\|new>/<epoch>_<i>_<name>` | public |
| `office-logos` | office_profile | `<officeId>/<epoch>-<slug>.<ext>` (owner-only write, mime allow-list, `logo_max_kb`) | public |

All uploads are subject to `trg_quota_storage` (`max_storage_mb`).

### 4.4 Edge functions

| Function | Feature | Purpose |
|---|---|---|
| `office-manage-user` | users | create a staff login / reset a password (Auth Admin API with the service-role key; membership written by RPC under the caller's JWT) |
| `platform-create-office` | platform_admin | onboard an office + its owner account (same split) |

### 4.5 Realtime

| Channel / stream | Feature | Tables |
|---|---|---|
| `dashboard_entitlements_<officeId>` | core | `office_licenses`, `office_feature_overrides` (filter `office_id`), `platform_plan_features`, `platform_features` |
| `dashboard_trip_management_<officeId>` | trips | `operation_trips`, `trip_seats`, `trip_passengers`, `trip_events` (unfiltered, RLS-scoped) |
| `dashboard_trip_details_<tripId>` | trips | same tables filtered `id`/`trip_id` |
| `dashboard_live_ops_<officeId>` | live_ops | `operation_trips` (filter `office_id`), `driver_trip_reports` |
| `dashboard_fleet_fixes_<officeId>` | live_ops | `trip_live_locations` INSERT (RLS `can_read_trip_fixes`) |
| `.stream(primaryKey:['id'])` | bookings, reviews, captain_requests, notifications | `operation_bookings`, `trip_reviews`, `captain_requests`, `operational_alerts` (latest 100) |

`SUPABASE-SPECIFIC`. The .NET replacement is a per-office push channel with `*.changed` events; the
dashboard re-fetches on every event today, so event payloads can stay minimal.

### 4.6 GoTrue endpoints

`POST /auth/v1/token?grant_type=password`, `POST /auth/v1/signup`, `POST /auth/v1/logout`, implicit refresh.
Staff/owner accounts provisioned by the platform use the synthetic email `<username>@office.ewt.internal`.

---

## 5. Cross-cutting vocabulary (exact wire values)

* **Roles:** `dashboard_admin` | `support_agent`. Platform admin = row in `platform_admins`.
* **Office:** `status ∈ active | paused | suspended | archived` (operational, platform-set);
  `listing_status ∈ draft | listed | unlisted` (marketplace, platform-set); license
  `status ∈ trialing | active | past_due | grace | suspended | cancelled | expired` (commercial).
* **Trip:** `scheduled` (draft) → `open_for_booking` → `boarding` → `in_progress` → `completed`; `cancelled` from
  any of the first four. Only `update_trip_status` may write it.
* **Seat:** `available | reserved | paid | subscription | blocked`.
* **Booking:** `draft | reserved | confirmed | boarded | completed | cancelled`; `payment_status ∈ pending |
  submitted | underReview (camelCase!) | approved | rejected | refunded | failed | cancelled`;
  `booking_payments.status` / `payment_review_status` use `under_review` (underscore).
* **Payment method:** `credit_card | instapay | vodafone_cash | bank_transfer` (+ free-text legacy spellings —
  see `finance/` normaliser).
* **Subscription:** `pending_payment | active | expired | cancelled` (`paused` read as pending);
  `payment_review_status ∈ pending | under_review | accepted`.
* **Wallet:** `kind ∈ refund | cashback | manual_credit | manual_debit | wallet_spend | wallet_topup | reversal`;
  wallet `status ∈ active | frozen`; entry `status ∈ posted | reversed`; refund
  `status ∈ pending | approved | settled | rejected | failed | cancelled`; settlement
  `wallet | original_method | cash | bank_transfer`.
* **Fleet:** driver `active | suspended | archived`; vehicle `active | maintenance | suspended | archived`;
  assignment `active | ended`; document `valid | expiring_soon | expired`; route `active | paused | draft | archived`.
* **Tickets:** `submitted | underReview | contacted | resolved | closed | rejected`; priority `low | medium | high | urgent`.
* **Incidents:** `report_type ∈ emergency | vehicle_issue | route_blockage | passenger_issue | delay | other`;
  `status ∈ pending | acknowledged | resolved | dismissed`.
* **Alerts:** `priority ∈ normal | high | urgent`; `type` list in `notifications/`.
* **Dates/times:** `trip_date` `yyyy-MM-dd`; `departure_time` `HH:mm:ss`; timestamps ISO-8601; the app
  converts to local on read and sends UTC ISO on write. **Money:** `numeric` may arrive as a JSON string —
  every datasource parses both.
