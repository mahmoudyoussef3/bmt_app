# Dashboard · Auth (تسجيل الدخول / إنشاء مكتب)

Sign-in with **username + password** (no email in the UI), self-service **office registration**
(email + password + office name), session restore on reload, and the **office context** every
other dashboard call depends on. There is no "forgot password" and no OTP on the dashboard.

## Overview

| Layer | Files (relative to `lib/apps/dashboard/features/auth/`) |
|---|---|
| Screens | `presentation/screens/dashboard_login_screen.dart`, `dashboard_sign_up_screen.dart` (mounted by `_DashboardAuthGate` in `lib/apps/dashboard/main.dart` — the gate, not a route, decides login vs shell) |
| Cubit | `presentation/cubit/dashboard_auth_cubit.dart` — `restore()`, `signIn()`, `signUp()`, `refreshContext()`, `signOut()` |
| Repo interface | `domain/repositories/dashboard_auth_repository.dart` |
| **Datasource** | `data/datasources/dashboard_auth_datasource.dart` (`DashboardAuthDatasource implements DashboardAuthRepository`) |
| Entities | `domain/entities/dashboard_auth_failure.dart`; the session object is `lib/apps/dashboard/core/session/office_context.dart` (`OfficeContext.fromRpc`) |
| Session holders | `lib/apps/dashboard/core/session/dashboard_session.dart` (`DashboardSession.officeId` — **throws when read signed-out**), `lib/apps/dashboard/core/entitlements/entitlement_service.dart` (loaded right after sign-in, see `../README.md` §1.2 / §2) |

## Operations

| # | Operation | Today (Supabase) | Auth | Proposed .NET |
|---|---|---|---|---|
| A1 | Resolve login name → email | `POST rpc/resolve_office_user_login` | anon | folded into A2 |
| A2 | Sign in | `POST /auth/v1/token?grant_type=password` | anon | `POST /api/v1/auth/dashboard/login` |
| A3 | Load office context | `POST rpc/current_office_context` | session | `GET /api/v1/dashboard/session` |
| A4 | Register office (sign-up) | `POST /auth/v1/signup` + `POST rpc/register_office` | anon → session | `POST /api/v1/auth/dashboard/register` |
| A5 | Restore cached session | SDK session cache + A3 | session | `GET /api/v1/dashboard/session` (+ `POST /api/v1/auth/refresh`) |
| A6 | Sign out | `POST /auth/v1/logout` | session | `POST /api/v1/auth/logout` |

---

## A1 + A2 — Sign in: `signIn({username, password})` (`dashboard_auth_datasource.dart:30`)

Two round-trips today. The UI field is a *name*; GoTrue only knows emails, so the name is resolved first.

```
POST /rest/v1/rpc/resolve_office_user_login
{ "p_username": "<typed name or email>" }
→ 200 { "outcome": "ready", "login_email": "owner@x.com", "full_name": "…", "role": "dashboard_admin" }
→ 200 { "outcome": "not_found" }                       (unknown, disabled, or < 3 chars — one generic answer)

POST /auth/v1/token?grant_type=password
{ "email": "<login_email>", "password": "<typed>" }
→ 200 { access_token, refresh_token, user{…} }
→ 400 AuthException  → 'اسم المستخدم أو كلمة المرور غير صحيحة.'

POST /rest/v1/rpc/current_office_context     (A3, immediately after)
```

SQL `resolve_office_user_login` (`20260721160000_office_self_signup.sql:290-336`, `SECURITY DEFINER`,
granted to **anon**): lowercases + trims; if the input contains `@` it matches `auth.users.email`,
otherwise `office_users.username`; requires `office_users.status = 'active'`. Returns `not_found` for
*both* unknown and disabled accounts on purpose (no staff directory leak).

Datasource behaviour worth keeping:
* `outcome != 'ready'` ⇒ the same "wrong credentials" message as a bad password.
* If A3 fails with `not_an_office_user` after a successful GoTrue login, the datasource tries
  `POST rpc/register_office` (no params — falls back to `pending_office_name` in user metadata) **once**
  and re-runs A3. This is how a sign-up interrupted by email confirmation completes on first login.
* Any other A3 failure ⇒ `signOut()` then rethrow. A GoTrue session without an office context is never kept.

**Proposed .NET:** `POST /api/v1/auth/dashboard/login { username, password }` → `200 { accessToken, refreshToken, session: <A3 payload> }`.
Do the name→account resolution server-side and return the same generic 401 for unknown/disabled/wrong-password.

---

## A3 — Office context: `loadContext()` (line 175)

```
POST /rest/v1/rpc/current_office_context
{}
→ 200 {
  "office_id": "<uuid>", "office_name": "…", "office_slug": "office-ab12cd34ef", "logo_url": "…|null",
  "role": "dashboard_admin" | "support_agent",
  "username": "…", "full_name": "…",
  "listing_status": "draft" | "listed" | "unlisted",
  "is_platform_admin": false
}
```

SQL (`20260721140000_platform_office_onboarding.sql`, `SECURITY DEFINER`, `authenticated` only):
`office_users` ⋈ `offices` where `user_id = auth.uid()` **and `office_users.status = 'active'`**;
raises `not_authenticated` / `not_an_office_user` / `office_suspended` (when `offices.status <> 'active'`).
`is_platform_admin` = `exists(platform_admins where user_id = auth.uid())`.

Mapped by `OfficeContext.fromRpc` (`office_context.dart`): `role` → `DashboardRole.fromDb`
(`dashboard_admin` → المالك, anything else → خدمة العملاء), `listing_status` default `listed`,
`is_platform_admin` must be literally `true`.

Datasource error mapping: `not_an_office_user` → 'هذا الحساب غير مرتبط بأي مكتب…' (code kept so A2 can
self-heal), `office_suspended` → 'تم إيقاف هذا المكتب…', anything else → 'تعذر تحميل بيانات المكتب.'.

Who reads it afterwards: **every** office-scoped datasource reads `DashboardSession.officeId`; the shell
gates the sidebar on `role` (`DashboardPermissions.permissionsFor`) and on `is_platform_admin` (platform
modules); `refreshContext()` is called after the office edits its own profile so name/logo update in the
shell without re-login.

`BUSINESS RULE` `RLS` — the office id is **never** a request parameter anywhere in the dashboard. The .NET
token must carry `office_id`, `role`, `is_platform_admin` (or the `/session` endpoint must be the single
source), and every dashboard endpoint must scope by the token's office, not by a query param.

**Proposed .NET:** `GET /api/v1/dashboard/session` → the same object (camelCase). Return `403 office_suspended`
/ `403 not_an_office_user` as machine codes.

---

## A4 — Register an office: `signUp({email, password, officeName})` (line 73)

```
POST /auth/v1/signup
{ "email": "<lowercased>", "password": "…",
  "data": { "role": "office_user", "pending_office_name": "<office name>" } }
→ 200 { session: {...} | null, user: {...} }

POST /rest/v1/rpc/register_office            (only if a session came back)
{ "p_office_name": "<office name>" }
→ 200 { "office_id","name","slug","status":"active","listing_status":"draft","join_code","username","role":"dashboard_admin" }

POST /rest/v1/rpc/current_office_context     (A3)
```

`BUSINESS RULE` — `register_office(p_office_name, p_full_name)` (`20260721160000_office_self_signup.sql:129-242`,
`SECURITY DEFINER`, `authenticated` only):
* `not_authenticated` when no `auth.uid()`.
* `already_registered` — **one office per account** (`office_users.user_id` is UNIQUE).
* `driver_cannot_register_office` — an account that owns a `drivers` row may not become an office admin.
* Office name: falls back to `raw_user_meta_data.pending_office_name`; `invalid_office_name` (< 3 chars),
  `office_name_too_long` (> 120). `invalid_full_name` (> 120).
* Generates: `slug = 'office-' + 10 hex` (unique loop), `username = derive_office_username(email)`
  (local part sanitised to `^[a-z0-9][a-z0-9._-]*$`, 3..32, uniquified with `2..99` suffix then random),
  `join_code = next_office_join_code()`.
* Inserts `offices { name, slug, description:'', email, service_areas:'{}', status:'active', listing_status:'draft', join_code, join_code_rotated_at:now() }`
  and `office_users { office_id, user_id:auth.uid(), username, full_name, role:'dashboard_admin', status:'active' }`.
* The office is **active + draft**: its dashboard works immediately; passengers cannot see it until the
  platform calls `platform_set_office_listing` (see `platform_admin/`).
* Trigger `handle_new_client_user()` must **skip** `role = 'office_user'` metadata, otherwise the
  auto-created `clients` row (phone `''`, unique) makes the *second* office sign-up fail.

Datasource error mapping — GoTrue: `already registered|user_already_exists` → 'هذا البريد الإلكتروني مسجّل بالفعل…',
`password` → 'كلمة المرور ضعيفة… 8 أحرف', `email` → 'البريد الإلكتروني غير صالح.'. RPC codes:
`already_registered`, `driver_cannot_register_office`, `invalid_office_name`, `office_name_too_long`, `not_authenticated`.
`session == null` (email confirmation on) ⇒ message asking the user to confirm then sign in (A2 self-heals).

**Proposed .NET:** `POST /api/v1/auth/dashboard/register { email, password, officeName, fullName? }` →
`201 { accessToken, refreshToken, session }`. Keep every rule above server-side; keep the machine codes.

---

## A5 — Restore: `DashboardAuthCubit.restore()` (`dashboard_auth_cubit.dart:77`)

`hasCachedSession` (= `auth.currentSession != null`, SDK-persisted) → A3. Any failure ⇒ `signOut()` +
clear session/entitlements/filter memory ⇒ login screen. **All three EWT apps share one session store per
device** (`SUPABASE-SPECIFIC`); a captain/client session restored here fails A3 with `not_an_office_user`
and is signed out. `NEEDS BACKEND DECISION`: audience-scoped tokens.

## A6 — Sign out: `signOut()` (line 206)

`POST /auth/v1/logout` (SDK). Then `DashboardSession.clear()`, `EntitlementService.clear()` (removes the
realtime channel), and both UI stores.

---

## What happens right after sign-in (not in this feature, but triggered by it)

`DashboardAuthCubit._startSession` (line 60) starts the session **and** fires
`EntitlementService.load()` → `POST rpc/office_entitlements` unawaited, plus a realtime channel on
`office_licenses` / `office_feature_overrides` / `platform_plan_features` / `platform_features`.
Documented in `../README.md` §1.2–§1.3 and §2 and `../office_billing/README.md`.

## Notes for the .NET team

1. The dashboard has **no** password reset, no email verification UI, no MFA. Only login, sign-up, logout.
2. Two roles only: `dashboard_admin` and `support_agent` (`lib/apps/dashboard/core/permissions/dashboard_role.dart`). Anything unknown is treated as `support_agent`.
3. The UI permission table (`dashboard_permission.dart`) is a **hint**; every write RPC re-checks the role server-side (`office_role()`, `office_can()`, `is_platform_admin()`).
4. `username` login and `email` login must both work (self-registered owners never learn their derived username).
5. Keep `resolve_office_user_login`'s non-disclosure: unknown and disabled must be indistinguishable.
