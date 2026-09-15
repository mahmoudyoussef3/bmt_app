# Captain · Auth (phone-only sign-in, driver binding, session restore, sign-out)

The captain types **only a phone number**. There is no password the captain knows, no OTP, no SMS.
The server checks the phone against active `drivers`, hands back a **derived** email + secret, the app
signs in (or signs up the first time) with that pair, then binds the resulting `auth.uid()` to the
driver row. On every later launch the identity is restored from the session with one RPC that also
returns the office's licensing verdict.

## Overview

| Layer | Files (relative to `lib/apps/captain/`) |
|---|---|
| Screens | `features/auth/presentation/screens/captain_login_screen.dart` (phone + Remember-Me + "request access" link), `captain_request_access_screen.dart` (hosts the onboarding flow — see `../onboarding/`) |
| Gate | `main.dart` `_CaptainAuthGate` (:105-209) — decides login / welcome-home / onboarding / shell; `core/session/captain_licensing_gate.dart` — wraps the shell |
| Cubit | `CaptainAuthCubit` (`features/auth/presentation/cubit/captain_auth_cubit.dart` — `signIn({phone, rememberMe})` :60-83, `signOut()` :85-92, `loadRememberedPhone()` :52-58) |
| Use cases | `SignInCaptainUseCase`, `SignOutCaptainUseCase`, `SaveRememberedPhoneUseCase`, `GetRememberedPhoneUseCase`, `ClearRememberedPhoneUseCase` |
| Repos | `features/auth/data/repositories/captain_auth_repository_impl.dart` (pass-through), `captain_remember_me_repository_impl.dart` (local) |
| **Datasources** | `features/auth/data/datasources/captain_auth_datasource.dart` (all network calls), `core/storage/remember_me_store.dart` (SharedPreferences key `captain_remember_me_phone`) |
| Identity (core) | `core/session/captain_identity_provider.dart` (`ensure()`, `refresh()`, `driverId()`), `core/session/captain_office_session.dart` (`CaptainIdentity`, `CaptainLicensing`, `CaptainOfficeSession`) |
| Sign-out trigger | `features/profile/presentation/widgets/driver_profile_sign_out_button.dart:18` → `captainGetIt<CaptainAuthCubit>().signOut()`; also the licensing-blocked screen calls `Supabase.instance.client.auth.signOut()` directly (`captain_licensing_gate.dart:103`) |

## Operations

| # | Operation | Today (Supabase) | Auth | Proposed .NET |
|---|---|---|---|---|
| A1 | Resolve phone → credentials | `POST rpc/resolve_captain_login` | **anon** | folded into A2 |
| A2 | Sign in (or first-time sign-up) | `POST /auth/v1/token?grant_type=password`; on `invalid login credentials` ⇒ `POST /auth/v1/signup` | anon | `POST /api/v1/auth/captain/login { phone }` |
| A3 | Bind auth user ↔ driver row | `POST rpc/link_current_captain_driver` | session | part of A2 (server-side) |
| A4 | Restore identity + licensing on launch | `POST rpc/captain_session_context` | session | `GET /api/v1/captain/session` |
| A5 | Sign out | `POST /auth/v1/logout` | session | `POST /api/v1/auth/logout` |
| A6 | Remember-Me phone | SharedPreferences | — | **local only** |

Call chain for sign-in: `CaptainLoginScreen._submit` (:67-78) → `CaptainAuthCubit.signIn` →
`SignInCaptainUseCase` → `CaptainAuthRepositoryImpl.signInWithPhone` →
`CaptainAuthDatasource.signInWithPhone` (`captain_auth_datasource.dart:12-52`) which performs **A1 → A2 → A3
in sequence** inside one method. The same method is also called every 20 s by
`CaptainActivationCubit` while a newly-approved captain waits on the welcome screen (see `../onboarding/`).

---

## A1 — Resolve the phone: `resolve_captain_login` (`captain_auth_datasource.dart:13-22`)

```
POST /rest/v1/rpc/resolve_captain_login
{ "p_phone": "01012345678" }               ← raw digits as typed (formatter strips non-digits)

→ 200 { "outcome": "ready",
        "login_email":   "201012345678@captain.bmt-app.internal",
        "login_secret":  "<hex hmac-sha256(normalized_phone, 'bmt-captain-login-v1')>",
        "full_name":     "…", "employee_code": "…",
        "office_id":     "<uuid>", "office_name": "…" }
→ 200 { "outcome": "not_registered" }      ← no ACTIVE driver with that phone
→ 200 { "outcome": "office_inactive" }     ← driver found but office.status <> 'active'
→ 400 { "code": "22023", "message": "رقم الهاتف غير صالح" }   ← normalized length < 10
```

**App reads:** `outcome` (anything but `ready` ⇒ `CaptainPhoneNotRegisteredException` ⇒ copy
*"هذا الرقم غير مسجّل كسائق نشط. تحقّق من الرقم أو اطلب الانضمام."* — note the app does **not**
distinguish `office_inactive` from `not_registered`), then `login_email`, `login_secret`,
`full_name`, `employee_code` (the last two only for the sign-up metadata). `office_id/office_name`
are returned but not read here — they arrive again from A3.

`BUSINESS RULE` (`20260721090100_multi_office_identity.sql:271-313`): match on
`normalize_egyptian_phone(drivers.phone) = normalize_egyptian_phone(p_phone) AND status='active'`,
oldest `created_at` wins on collision; office must be `active`.

⚠ **Security note the .NET team must not port**: this RPC is callable by `anon` and **returns a
password**. Anyone who knows a captain's phone can obtain their credentials (accepted trade-off,
documented in `20260708120000_captain_phone_login.sql:18-22`). In .NET, `POST /api/v1/auth/captain/login`
should take the phone, perform the same driver/office checks server-side, and **issue the token
directly** — no credential ever leaves the server. `NEEDS BACKEND DECISION`: whether to add a
proof-of-possession step (OTP) — the current product explicitly has none.

---

## A2 — Sign in / first-time sign-up (`captain_auth_datasource.dart:25-42`)

```
POST /auth/v1/token?grant_type=password
{ "email": "<login_email>", "password": "<login_secret>" }
→ 200 session
→ 400 "Invalid login credentials"  ⇒ the app treats this as "first sign-in" and falls through to:

POST /auth/v1/signup
{ "email": "<login_email>", "password": "<login_secret>",
  "data": { "full_name": "<from A1>", "employee_code": "<from A1>", "role": "driver" } }
→ 200 session (email auto-confirm is enabled on the project)
```

Error mapping (`_authMessage` :65-71): message containing `rate` or `seconds` ⇒
*"محاولات كثيرة، حاول مرة أخرى بعد قليل."*; anything else ⇒ *"تعذّر تسجيل الدخول، حاول مرة أخرى."*.

`SUPABASE-SPECIFIC`: the `role: 'driver'` metadata is what stops `handle_new_client_user` from creating a
`clients` row for this auth user (`20260708120100_captain_signup_skips_client_row.sql`). In .NET there is
no synthetic user at all — the driver row is the principal.

---

## A3 — Bind the driver: `link_current_captain_driver` (`captain_auth_datasource.dart:44-51`)

```
POST /rest/v1/rpc/link_current_captain_driver
{ "p_phone": "01012345678" }
→ 200 { "driver_id": "<uuid>", "full_name": "…", "phone": "…", "employee_code": "…",
        "office_id": "<uuid>", "office_name": "…" }
```

**App reads:** the whole object → `CaptainIdentity.fromRpc` (`captain_office_session.dart:24-34`) →
`CaptainOfficeSession.start(identity)`. No `licensing` block on this path (defaults: everything
licensed) — the licensing gate re-resolves via A4 immediately after, because `_CaptainAuthGate`
rebuilds on the new session and mounts `CaptainLicensingGate`.

`BUSINESS RULE` (`20260721090100_multi_office_identity.sql:320-370`):
1. `Authentication is required` when no uid.
2. Same active-driver-by-phone lookup as A1 (`رقم الهاتف غير مسجل كسائق نشط` when none).
3. **`driver_already_linked`** when `drivers.user_id` is set to a *different* uid — a phone collision
   may not hijack another captain's row.
4. `office_inactive` when the office is not active.
5. `UPDATE drivers SET user_id = auth.uid()`.

Errors here surface as the raw Postgres message (the datasource does not map them).

**Proposed .NET:** all of A1–A3 become one `POST /api/v1/auth/captain/login { phone }` →
`200 { accessToken, refreshToken, captain: { driverId, officeId, officeName, fullName, phone, employeeCode }, licensing: {…} }`;
`404 { code: "not_registered" }`, `403 { code: "office_inactive" | "driver_already_linked" }`, `429` on rate limit.

---

## A4 — Restore on launch: `captain_session_context` (`captain_identity_provider.dart:34-45`)

Called lazily by `CaptainIdentityProvider.ensure()` the first time any datasource needs the driver id,
and eagerly by `CaptainLicensingGate` on every shell mount (`captain_licensing_gate.dart:19`).
In-flight de-duplicated (`_inFlight`), cached in `CaptainOfficeSession` until `refresh()` / sign-out.

```
POST /rest/v1/rpc/captain_session_context
{}
→ 200 { "driver_id": "…", "full_name": "…", "phone": "…", "employee_code": "…",
        "office_id": "…", "office_name": "…",
        "licensing": { "driver_app": true, "live_tracking": true, "in_flight": false,
                       "blocked": false, "message_ar": null } }
→ 200 null      ← not a captain (no driver row), or office not active
```

**App reads:** everything; `driver_id` or `office_id` empty ⇒ treated as null (:41).
`CaptainLicensing.fromRpc` (`captain_office_session.dart:57-67`) is absent-tolerant: a missing block
⇒ all licensed.

`BUSINESS RULE` (`20260807140000_licensing_marketplace.sql:262-368`):
1. `auth.uid()` null ⇒ `null`.
2. Driver by `user_id = uid AND status='active'`; **if none, fall back to `auth.users.phone`** matched
   by normalized phone against an unbound (`user_id IS NULL`) active driver and **bind it inline**
   (`UPDATE drivers SET user_id = uid`). This is the second binding door (the first is A3) and the reason
   a captain quota trigger meters this RPC (`20260808090000:1045-1060`).
3. Office must exist and be `active`, else `null` (the captain is kept off the shell).
4. `driver_app` / `live_tracking` from `platform_resolve_feature(office_id, null, key)`;
   `in_flight` = this driver has a trip in `boarding|in_progress`;
   `blocked = NOT driver_app AND NOT in_flight AND platform_enforcement_mode() = 'enforcing'`;
   `message_ar` set only when blocked.

**Proposed .NET:** `GET /api/v1/captain/session` → same document; `401` when the token is not a
captain's. The licensing block must be computed server-side every call (the app calls it on every
cold start and on "retry" from the blocked screen).

---

## A5 — Sign out (`captain_auth_datasource.dart:54-60`)

```
POST /auth/v1/logout
```
Always followed by `CaptainOfficeSession.clear()` (in `finally`). `_CaptainAuthGate` listens for
`AuthChangeEvent.signedOut` (`main.dart:125-132`) and additionally stops the GPS publisher
(`LiveLocationCubit.stopAutoSharing()`) and wipes the local post-approval session
(`CaptainSessionStore.clearSession()`). `CaptainApp._listenAuth` (`main.dart:59-71`) deactivates the
FCM token on any null session (see `../notifications/`). **Remember-Me is never cleared by sign-out.**

---

## A6 — Remember-Me (local only)

`CaptainRememberMeStore` (`core/storage/remember_me_store.dart`): key `captain_remember_me_phone`.
Saved after a successful sign-in when the toggle is on, cleared when off (`captain_auth_cubit.dart:94-105`);
read on login-screen mount to prefill the field. Nothing reaches the backend.

---

## Identity document the backend must provide (`CaptainIdentity`)

| Field | Type | Source column |
|---|---|---|
| `driver_id` | uuid | `drivers.id` |
| `office_id`, `office_name` | uuid, text | `drivers.office_id` → `offices.id/name` |
| `full_name`, `phone`, `employee_code` | text | `drivers.*` (phone as stored, not normalized) |
| `licensing.driver_app`, `.live_tracking` | bool | entitlement resolution for the office |
| `licensing.in_flight`, `.blocked` | bool | see A4 rule 4 |
| `licensing.message_ar` | text? | Arabic copy when blocked |

## Notes for the .NET team

1. **Three RPCs collapse into one login endpoint + one session endpoint.** Keep the `outcome`
   vocabulary (`not_registered`, `office_inactive`) as error codes because the login screen copy keys
   off "not registered".
2. The derived-credential trick exists only because Supabase Auth needs an email/password. Do not
   reproduce it; the phone lookup + office check + token issue is the whole contract.
3. `captain_session_context` is also the **licensing gate** and the **in-flight exemption** lives there —
   port §1.4 of the app README exactly, including the phone-fallback binding in rule 2 if you keep a
   "drivers created by the office before the captain ever signed in" model (you will: onboarding
   approval creates the driver row first).
4. The shared-session trap (`README.md` §1.3): today a rider's token calling A4 just gets `null`. In .NET,
   reject it with `401`/`403` explicitly and issue audience-scoped tokens.
5. Rate limiting: the app's only defence is the GoTrue rate-limit message. A phone-keyed login endpoint
   needs server-side throttling per phone and per IP.
