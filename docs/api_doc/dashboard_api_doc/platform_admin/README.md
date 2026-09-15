# Dashboard · Platform Admin — Offices (مكاتب المنصة)

The EWT platform console for **platform admins only** (`platform_admins` table): every office on
the platform (drafts and suspended ones included), one office's details and marketplace preview,
cross-office analytics, onboarding a new office with its first owner account, publishing/unlisting
an office on the marketplace, and changing an office's operational status. Every RPC re-checks
`is_platform_admin()` server-side under the caller's own JWT; `OfficeContext.isPlatformAdmin` only
decides whether the sidebar shows the module.

## Overview

| Layer | Files (relative to `lib/apps/dashboard/features/platform_admin/`) |
|---|---|
| Screens | `presentation/screens/` (`DashboardRoutes.platformOffices` = `/platform-offices`; browse list → office workspace) |
| Cubit | `presentation/cubit/platform_admin_cubit.dart` |
| Use cases | `domain/usecases/` (`GetPlatformOfficesUseCase`, `GetPlatformOfficeDetailsUseCase`, `GetPlatformAnalyticsUseCase`, `OnboardOfficeUseCase`, `SetOfficeListingStatusUseCase`, `SetOfficeStatusUseCase`) |
| Repo | `data/repositories/platform_admin_repository_impl.dart` |
| **Datasource** | `data/datasources/supabase_platform_admin_datasource.dart` (`SupabasePlatformAdminDatasource implements PlatformAdminDatasource`) |
| Entities | `domain/entities/platform_office.dart`, `platform_office_details.dart`, `platform_analytics.dart`, `office_onboarding.dart` (`OfficeOnboardingRequest.toPayload()`, `OfficeOnboardingResult`) |
| Permission | `DashboardPermission.platformOffices` (admin role **and** `isPlatformAdmin`) |

## Operations

| # | Operation | Today (Supabase) | Proposed .NET |
|---|---|---|---|
| M1 | List all offices | `POST rpc/platform_list_offices` | `GET /api/v1/platform/offices` |
| M2 | Office details | `POST rpc/platform_office_details {p_office_id}` | `GET /api/v1/platform/offices/{officeId}` |
| M3 | Platform analytics | `POST rpc/platform_office_analytics {p_window_days}` | `GET /api/v1/platform/analytics?windowDays=` |
| M4 | Onboard an office | Edge `POST /functions/v1/platform-create-office` | `POST /api/v1/platform/offices` |
| M5 | Listing status | `POST rpc/platform_set_office_listing {p_office_id, p_listing_status}` | `PATCH /api/v1/platform/offices/{officeId}/listing` |
| M6 | Operational status | `POST rpc/platform_set_office_status {p_office_id, p_status}` | `PATCH /api/v1/platform/offices/{officeId}/status` |
| — | Broadcast notification | see `notifications/` A6 | `POST /api/v1/platform/notifications/broadcast` |

Error codes mapped in `_messageForCode` (line 161; keep them): `platform_admin_required`, `not_authenticated`,
`slug_taken`, `username_taken`, `admin_user_already_assigned`, `invalid_username`, `invalid_slug`,
`invalid_office_name` / `office_name_too_long`, `invalid_logo_url` (must be https), `invalid_email`,
`invalid_phone`, `description_too_long`, `too_many_service_areas` / `invalid_service_area`, `weak_password`,
`office_profile_incomplete`, `office_not_active`, `office_not_found`, `auth_user_creation_failed`,
`join_code_generation_failed`, `onboarding_failed` (+ `invalid_listing_status`, `invalid_status`).

---

## M1 — `getOffices()` (line 32)

`POST rpc/platform_list_offices {}` → rows `{ id, name, slug, logo_url, description, phone, email, service_areas[],
status (active|paused|suspended|archived), listing_status (draft|listed|unlisted), listed_at, rating, ratings_count,
operators, drivers, routes, vehicles, trips, owner_name, owner_username, created_at, updated_at }`
(`20260722090000_platform_office_management.sql:55`). `join_code` is deliberately **not** returned.

## M2 — `getOfficeDetails(officeId)` (line 61)

`POST rpc/platform_office_details { p_office_id }` → one jsonb: the same office keys as M1 at top level +
`counts { operators, drivers, vehicles, routes, trips, bookings, reviews }`, `operators[] { username, full_name,
role, status, created_at }`, `marketplace { name, slug, description, service_areas, rating, ratings_count, logo_url }`
(what `public_offices` would show).

## M3 — `getAnalytics({windowDays})` (line 45)

`POST rpc/platform_office_analytics { p_window_days: 30 }` (clamped 1..365) → `{ window_days, generated_at,
totals { offices, active, paused, suspended, archived, listed, draft, unlisted, trading, idle, never_traded,
onboarded_in_window, without_admin, listed_without_trips, trips_total, trips_recent, trips_upcoming, trips_stale,
bookings_total, bookings_recent, revenue_total, revenue_recent, payments_awaiting_review, payments_awaiting_amount,
tickets_open, captain_requests_pending, seats_offered, seats_sold }, trend[] { day, bookings, revenue },
offices[] { office_id, trips_total, trips_recent, trips_upcoming, trips_stale, trips_completed, trips_cancelled,
bookings_total, bookings_recent, bookings_confirmed, bookings_cancelled, bookings_cancelled_recent, revenue_total,
revenue_recent, payments_awaiting_review, payments_awaiting_amount, payments_rejected, seats_offered, seats_sold,
tickets_total, tickets_open, tickets_recent, captain_requests_pending, reviews_total, reviews_recent,
active_operators, active_admins, avg_office_rating, last_trip_date, first_booking_at, last_booking_at } }`
(`20260722140000_platform_office_analytics.sql`). Revenue = sum of approved bookings (never `operation_trips.revenue`).

## M4 — Onboard: `onboardOffice(request)` (line 77)

```
POST /functions/v1/platform-create-office        Authorization: Bearer <platform admin JWT>
{ "name", "admin_username": "<lowercase>", "slug"?, "description"?, "logo_url"?, "phone"?, "email"?,
  "service_areas"?: [...], "admin_full_name"?, "admin_password"?: "≥10" }
→ 200 { "office": { office_id, name, slug, join_code, username, listing_status:'draft', role, status:'active' },
        "login_username", "temporary_password"? }
→ 4xx/500 { "error": "<code>" }
```
Edge Function (`supabase/functions/platform-create-office/index.ts`): verifies the caller is a platform admin,
creates the owner's `auth.users` row with the service-role key (synthetic email
`<username>@office.ewt.internal`, generated 16-char password unless supplied), then calls
`platform_create_office(p_name, p_admin_user_id, p_admin_username, p_slug, p_description, p_logo_url, p_phone,
p_email, p_service_areas, p_admin_full_name)` **with the caller's JWT**; on failure the auth user is deleted.

`BUSINESS RULE` — `platform_create_office` (`20260721140000_platform_office_onboarding.sql`):
`platform_admin_required`; validates name (3..120), slug (`^[a-z0-9][a-z0-9-]*$`, unique → `slug_taken`;
generated `office-<10 hex>` when absent), username (`^[a-z0-9][a-z0-9._-]*$` 3..32, `username_taken`),
`admin_user_required/not_found/already_assigned`, logo https, email, phone, description ≤ N,
service areas count/shape; generates `join_code`; inserts `offices { status:'active', listing_status:'draft' }`
and `office_users { role:'dashboard_admin', status:'active' }`; returns the join code **once**. The office is
private until M5 publishes it. The self-service alternative is `register_office` (see `auth/`).

**Proposed .NET:** `POST /api/v1/platform/offices { … }` → `201 { office, loginUsername, temporaryPassword?, joinCode }`.

## M5 — Listing: `setListingStatus(officeId, listingStatus)` (line 125)

`POST rpc/platform_set_office_listing { p_office_id, p_listing_status: 'draft'|'listed'|'unlisted' }` →
`invalid_listing_status`, `office_not_found`; publishing (`listed`) requires `status = 'active'`
(`office_not_active`) and a complete profile — description + ≥1 service area (`office_profile_incomplete`);
stamps `listed_at` on first publish. This is the **only** way an office becomes visible to riders
(`public_offices` view = `active` + `listed`).

## M6 — Status: `setOfficeStatus(officeId, status)` (line 137)

`POST rpc/platform_set_office_status { p_office_id, p_status: 'active'|'paused'|'suspended'|'archived' }`.
A non-`active` office's operators get `office_suspended` at sign-in (`current_office_context`); its marketplace
rows disappear (`office_is_active`). Licensing has its own hold axis (`office_licenses.status`) — see
`platform_licensing/`.

## Notes for the .NET team

1. Platform-admin identity is a separate table (`platform_admins.user_id`), orthogonal to office membership;
   a platform admin is usually also an owner of the EWT office. Model it as a separate claim/role.
2. The three office axes: `status` (operational), `listing_status` (marketplace), license `status`
   (commercial). Never merge them.
3. Onboarding = identity-provider call + one SQL transaction, with compensation. Same pattern as `users/` U2.
