# Dashboard · Captain Requests (طلبات الكباتن)

The office's queue of captain (driver) self-enrolment requests submitted from the Captain app
(name + phone, no SMS). The operator **approves** — which opens the full driver form, creates an
active `drivers` row, and links it to the request — or **rejects** with a reason. The captain app polls
`get_captain_request_status` and, once approved, signs in.

## Overview

| Layer | Files (relative to `lib/apps/dashboard/features/captain_requests/`) |
|---|---|
| Screen | `presentation/screens/` (`DashboardRoutes.captainRequests` = `/captain-requests`) |
| Cubit | `presentation/cubit/captain_requests_cubit.dart` — `load()`, `approve({requestId, driverId})`, `reject({requestId, reason})` |
| Use cases | `domain/usecases/captain_requests_usecases.dart` (`GetCaptainRequestsUseCase` — also used by Home/Business Overview, `WatchCaptainRequestsUseCase`, `ApproveCaptainRequestUseCase`, `RejectCaptainRequestUseCase`) |
| Repo | `data/repositories/captain_requests_repository_impl.dart` |
| **Datasource** | `data/datasources/supabase_captain_requests_datasource.dart` (`SupabaseCaptainRequestsDatasource`) |
| Model | `data/models/captain_request_model.dart` (`id, full_name, phone, note, status, driver_id, rejection_reason, reviewed_at, created_at`) |
| Driver creation | reuses `fleet/` F2 (`FleetDriverFormView`) — the approve dialog creates the driver first, then calls Q3 with its id |
| Permission | `DashboardPermission.captainRequests` (admin only); feature key `driver_app`; limit `max_captains` (metered when a driver gains a `user_id`, trigger `trg_quota_captains`) |

## Operations

| # | Operation | Today (Supabase) | Proposed .NET |
|---|---|---|---|
| Q1 | List requests | `GET captain_requests?select=*&order=created_at.desc` (unbounded) | `GET /api/v1/dashboard/captain-requests` |
| Q2 | Live queue | `.stream(primaryKey:['id'])` on `captain_requests` | WebSocket `captain-requests.changed` |
| Q3 | Approve | (fleet F2 creates the driver) → `PATCH captain_requests {status:'approved', driver_id, reviewed_by, reviewed_at, updated_at}` | `POST /api/v1/dashboard/captain-requests/{id}/approve` |
| Q4 | Reject | `PATCH captain_requests {status:'rejected', rejection_reason, reviewed_by, reviewed_at, updated_at}` | `POST /api/v1/dashboard/captain-requests/{id}/reject` |

`RLS` `captain_requests_office` (`FOR ALL`, `office_id = current_office_id()`; anon revoked). Q3 is wrapped
in `LicensingGuard.run` (a `quota_exceeded` on `max_captains` surfaces as a `LicensingFailure`); Q4 has no
error mapping.

## Q1 / Q2 — `getRequests()` / `watchRequests()` (lines 12 / 22)

Row: `id, full_name, phone, phone_normalized, office_id, note, status (pending|approved|rejected), driver_id,
rejection_reason, reviewed_by, reviewed_at, created_at, updated_at`. Filtering (pending/approved/rejected,
search over name/phone/note) is Dart-side.

**How a request is born** (`submit_captain_request`, `20260721090300_multi_office_rpcs.sql:532`, called by the
Captain app, anon): validates phone/name, requires an **office** (`office_required`, resolved from a join
code or office id; `office_inactive`), inserts `captain_requests` (`status:'pending'`), and trigger
`on_captain_request_insert` pushes an operational alert `captain_request` (`high`, `/captain-requests`).

## Q3 — Approve: `approve({requestId, driverId})` (line 39)

Two-step, client-orchestrated:
1. `fleet/` F2 — `POST drivers { office_id, full_name, phone, … , status:'active' }` from the driver form pre-filled with the request.
2. `PATCH /rest/v1/captain_requests?id=eq.<id> { status:'approved', driver_id:'<new driver>', reviewed_by:<auth uid>, reviewed_at, updated_at }`.

`BUSINESS RULE` — the captain's auth user is **not** linked here. The Captain app's `CaptainActivationCubit`
polls `get_captain_request_status(p_phone)` (returns `status`, `driver_id`, `employee_code`) and then signs
in by phone; `link_current_driver_account()` binds `auth.uid()` to the driver row whose phone matches — that
`drivers.user_id` write is what `trg_quota_captains` meters (`max_captains`, stock).

**Proposed .NET:** `POST /api/v1/dashboard/captain-requests/{id}/approve { driver: {…full driver payload…} }`
→ creates the driver and marks the request in one transaction; quota check on the same call.

## Q4 — Reject: `reject({requestId, reason})` (line 57)

`PATCH captain_requests?id=eq. { status:'rejected', rejection_reason, reviewed_by, reviewed_at, updated_at }`.
No captain notification (the app learns by polling).

## Notes for the .NET team

1. Approval is a two-write flow with no rollback: a driver created and a failed request update leaves an
   orphan driver. Make it atomic.
2. There is no OTP/SMS in the captain auth model by owner's choice; approval **is** the security gate.
3. `phone_normalized` is the matching key between the request, the driver row and the captain's sign-in.
