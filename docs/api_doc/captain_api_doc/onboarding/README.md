# Captain · Onboarding (self-service join request → dashboard approval → activation)

A prospective captain with **no account** submits name + phone (+ the office's join code when more than
one office exists). Operations reviews the queue on the dashboard (`../../dashboard_api_doc/captain_requests/`)
and approves — which creates the `drivers` row — or rejects with a reason. The app polls the request
status while pending, then, once approved, keeps trying the normal phone sign-in until the driver row
is `active` and bound.

## Overview

| Layer | Files (relative to `lib/apps/captain/`) |
|---|---|
| Screens | `features/onboarding/presentation/screens/captain_onboarding_flow.dart` (form → pending → approved/rejected/already-active), `captain_welcome_home.dart` + `captain_welcome_home_screen.dart` (post-approval "activating your account" screen), hosted by `features/auth/presentation/screens/captain_request_access_screen.dart` (route `/captain/request-access`) or inline by `_CaptainAuthGate` (`main.dart:192-208`) |
| Cubits | `CaptainOnboardingCubit` (`presentation/cubit/captain_onboarding_cubit.dart` — `init(pendingPhone)`, `submit(...)`, `refreshNow()`, `establishSession()`, `discard()`), `CaptainActivationCubit` (`captain_activation_cubit.dart` — `start(phone)`, `check(phone)`) |
| Use cases | `SubmitCaptainRequestUseCase`, `GetCaptainRequestStatusUseCase`, `GetActiveOfficesUseCase` (`domain/usecases/onboarding_usecases.dart`); activation reuses `SignInCaptainUseCase` from `auth/` |
| Repo | `data/repositories/captain_onboarding_repository_impl.dart` (maps Postgres codes → Arabic copy :50-67; swallows list/status errors) |
| **Datasource** | `data/datasources/captain_onboarding_datasource.dart` |
| Entities | `domain/entities/captain_onboarding_models.dart` (`OnboardingOffice`, `SubmitResult{outcome, phone}`, `CaptainRequestStatusData`) |
| Local state | `core/session/captain_session_store.dart` — SharedPreferences `captain_pending_phone` (while pending) and `captain_local_session` (`{driver_id, name, phone, employee_code}` after approval) |

## Operations

| # | Operation | Today (Supabase) | Auth | Proposed .NET |
|---|---|---|---|---|
| O1 | List offices to join | `GET public_offices?order=name.asc` | **anon** | `GET /api/v1/captain/onboarding/offices` |
| O2 | Submit join request | `POST rpc/submit_captain_request` | **anon** | `POST /api/v1/captain/onboarding/requests` |
| O3 | Poll request status (every 4 s) | `POST rpc/get_captain_request_status` | **anon** | `GET /api/v1/captain/onboarding/requests?phone=` |
| O4 | Activation poll (every 20 s after approval) | the full sign-in chain from `../auth/` (A1→A2→A3) | anon → session | `POST /api/v1/auth/captain/login` |

---

## O1 — Offices: `fetchActiveOffices()` (`captain_onboarding_datasource.dart:9-19`)

Called from `CaptainOnboardingCubit.init(null)` → `_loadOffices()` (:39-44) when the form opens
without a pending phone.

```
GET /rest/v1/public_offices?select=*&order=name.asc
→ 200 [ { "id": "…", "name": "…", "slug": "…", "logo_url": "…", "description": "…",
          "service_areas": [...], "rating": 4.6, "ratings_count": 12 }, … ]
```

**App reads:** `id`, `name`, `logo_url`, `description` (`OnboardingOffice.fromRow`). UI rule
(`OnboardingForm.requiresOfficeChoice`): the office picker + join-code field appear only when
**more than one** office is returned; with exactly one the request is sent with `officeId = null`
and the server picks the single active office. Errors ⇒ `[]` (repo swallows) ⇒ single-office UI.

View definition: `20260721140000_platform_office_onboarding.sql:278-289` — `offices` where
`status='active' AND listing_status='listed'`, 8 columns, **never** `join_code`.

**Proposed .NET:** `GET /api/v1/captain/onboarding/offices` → `[{ id, name, logoUrl, description }]`, public.

---

## O2 — Submit: `submit(...)` (`captain_onboarding_datasource.dart:21-46`)

Call chain: `CaptainOnboardingFlow` form `onSubmit` (:140) → `CaptainOnboardingCubit.submit`
(:46-80) → `SubmitCaptainRequestUseCase` → repo → datasource.

```
POST /rest/v1/rpc/submit_captain_request
{ "p_full_name": "…", "p_phone": "01012345678",
  "p_office_id": "<uuid>|null", "p_office_code": "ABCD2345|null" }

→ 200 { "outcome": "submitted", "request_id": "<uuid>", "phone": "01012345678" }
→ 200 { "outcome": "pending",   "request_id": "<uuid>", "phone": "…" }   ← a pending request already exists (idempotent)
→ 200 { "outcome": "already_active" }                                   ← phone is already an active driver → "just sign in"
→ 400 { "code": "22023", "message": "رقم الهاتف غير صالح" | "الاسم غير صالح" }
→ 400 { "message": "…office_code_required…" | "…invalid_office_code…" | "…office_code_mismatch…" | "…office_inactive…" }
```

**App reads:** `outcome` (`already_active` ⇒ `OnboardingAlreadyActive` screen; `submitted`/`pending`
⇒ save `captain_pending_phone` = response `phone` (falls back to the typed phone) and start polling O3).

**Error copy** (`captain_onboarding_repository_impl.dart:50-67`): SQLSTATE `22023` ⇒ the server message
verbatim; `office_code_required` ⇒ *"أدخل كود المكتب الذي تنضم إليه."*; `invalid_office_code` ⇒
*"كود المكتب غير صحيح. تواصل مع المكتب للحصول على الكود."*; `office_code_mismatch` ⇒ *"الكود لا يخص
المكتب المختار."*; `office_inactive` ⇒ *"هذا المكتب لا يستقبل طلبات حالياً."*; else generic.

`BUSINESS RULE` (`20260721100200_captain_office_join_code.sql:58-144`):
1. Normalized phone length ≥ 10; trimmed name length ≥ 2 (both `22023`).
2. **Office resolution — the code is authoritative:**
   * code given ⇒ `offices WHERE upper(join_code)=upper(code) AND status='active'` else `invalid_office_code`;
     if `p_office_id` is also given and differs ⇒ `office_code_mismatch` (a tampered id cannot ride along);
   * no code and **exactly one** active office ⇒ that office (single-tenant deployments / older builds);
   * no code and more than one active office ⇒ `office_code_required`.
3. Office must be active (`office_inactive`).
4. Phone already an **active driver** ⇒ `{outcome:'already_active'}` (no row written).
5. A `pending` request for the same normalized phone exists ⇒ `{outcome:'pending', request_id, phone}`
   (unique partial index `uq_captain_requests_pending_phone`).
6. Insert `captain_requests (full_name, phone, phone_normalized, office_id, status='pending',
   office_code_verified = code IS NOT NULL)` ⇒ `{outcome:'submitted', request_id, phone}`.

Join codes: 8 chars from `ABCDEFGHJKLMNPQRSTUVWXYZ23456789` (no 0/O/1/I), one per office, rotated by
the office admin (`office_rotate_join_code`); never readable by anon/authenticated column grants.

**Proposed .NET:** `POST /api/v1/captain/onboarding/requests { fullName, phone, officeId?, officeCode? }`
→ `201 { outcome: "submitted"|"pending", requestId, phone }` or `200 { outcome: "already_active" }`;
`422 { code }` with the four office-code codes + validation. Rate-limit per phone/IP (public endpoint).

---

## O3 — Poll status: `getStatus(phone)` (`captain_onboarding_datasource.dart:48-67`)

Polled every **4 s** (`CaptainOnboardingCubit._pollInterval` :17) from `_beginPolling` (:82-87) and
on pull-to-refresh (`refreshNow`). Also the entry path when the app relaunches with a pending phone
(`init(pendingPhone)`).

```
POST /rest/v1/rpc/get_captain_request_status
{ "p_phone": "01012345678" }
→ 200 { "request_id": "…", "status": "pending"|"approved"|"rejected",
        "full_name": "…", "phone": "…", "rejection_reason": null|"…",
        "driver_id": null|"<uuid>", "employee_code": null|"…" }
→ 200 null                           ← no request for that phone
```

**App reads:** `status` (unknown ⇒ `pending`), `full_name`, `phone`, `rejection_reason`, `driver_id`,
`employee_code`. `approved` ⇒ stop polling, `OnboardingApproved` ⇒ on "enter" the cubit writes
`captain_local_session` (`establishSession` :116-125) and the gate shows the welcome-home screen (O4).
`rejected` ⇒ `OnboardingRejected(reason ?? 'لم يتم قبول طلبك.')`. Errors ⇒ `null` ⇒ keep polling.

`BUSINESS RULE` (`20260705120000_captain_access_requests.sql:119-152`): newest `captain_requests` row for
the normalized phone; when `driver_id` is set, `full_name`/`phone`/`employee_code` come from the
**driver** row (so the app greets the captain with the name operations finalised).

⚠ Unauthenticated and phone-keyed: anyone can poll any phone's status. `NEEDS BACKEND DECISION`:
return a one-time `requestToken` from O2 and require it here, or rate-limit.

**Proposed .NET:** `GET /api/v1/captain/onboarding/requests?phone=` (or `/{requestId}` with the token) →
`200 { status, fullName, phone, rejectionReason, driverId, employeeCode }` / `404`.

---

## O4 — Activation after approval (`captain_activation_cubit.dart:21-48`)

The welcome-home screen (`captain_welcome_home_screen.dart:34`) calls `CaptainActivationCubit.start(phone)`:
an immediate `check` then every **20 s**, each attempt being the full sign-in chain
(`SignInCaptainUseCase` → `resolve_captain_login` → token → `link_current_captain_driver`).
`CaptainPhoneNotRegisteredException` (driver not yet `active`, or office not active) ⇒ keep waiting;
any other error ⇒ `CaptainActivationFailed(message)` with a retry; success ⇒ a Supabase session now
exists and `_CaptainAuthGate` switches to the shell on the next auth event.

Why it exists: approval creates the driver row, but the row may be created `inactive`/pending fleet
setup; the captain sees "جارٍ تفعيل حسابك" until `drivers.status = 'active'`. There is no dedicated
backend call — porting `POST /api/v1/auth/captain/login` with the `not_registered` code is sufficient.

**Local session** `captain_local_session` is cleared on sign-out and by the welcome screen's own
sign-out button (`onSignOut` → `_forgetLocalSession`, `main.dart:182-190`).

---

## Data shapes the backend must provide

`captain_requests` row (`20260705120000:10-23` + `office_id` from `20260721090300` + `office_code_verified`
from `20260721100200`): `id, full_name, phone, phone_normalized, office_id, status (pending|approved|rejected),
note, rejection_reason, driver_id, reviewed_by, reviewed_at, office_code_verified, created_at, updated_at`.
The captain app never reads the table directly (RLS: `captain_requests_office`, office-scoped; anon revoked).

## Notes for the .NET team

1. Two public, phone-keyed endpoints (O2, O3) with no proof of phone possession — same trust model as
   login. Add throttling at minimum.
2. The single-office fallback in O2 rule 2 is a compatibility branch; with a multi-office marketplace
   the join code is the real second factor. Keep the code-wins-over-id rule.
3. The approval side (dashboard) is what creates `drivers`; the captain app only ever reads the
   outcome. See `../../dashboard_api_doc/captain_requests/README.md` for `approve_captain_request`.
4. All four polling cadences (4 s status, 20 s activation) are app constants; a push notification on
   approval would let you drop the status poll entirely (the request has no user id to notify yet —
   `NEEDS BACKEND DECISION`).
