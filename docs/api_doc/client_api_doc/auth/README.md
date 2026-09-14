# Client · Auth

Sign-up, sign-in, sign-out, password reset, session vetting, "Remember Me", and the (unimplemented)
phone-OTP / social seams.

## Overview

| Layer | Files |
|---|---|
| Screens | `presentation/screens/` — `welcome_screen.dart`, `sign_in_screen.dart`, `sign_up_screen.dart`, `forgot_password_screen.dart`, `reset_password_screen.dart`, `auth_success_screen.dart`, `phone_login_screen.dart`, `otp_verification_screen.dart` |
| Cubits | `AuthCubit` (`presentation/cubit/auth_cubit.dart` — `signIn`, `signUp`, `signOut`), `ForgotPasswordCubit`, `ResetPasswordCubit`, `SocialAuthCubit` |
| Use cases | `domain/usecases/` — `SignInWithEmailUseCase`, `SignUpWithEmailUseCase`, `SignOutUseCase`, `SendPasswordResetEmailUseCase`, `UpdatePasswordUseCase`, `EnsureClientSessionUseCase`, `Save/Get/ClearRememberedCredentialsUseCase`, `SignInWithGoogle/AppleUseCase`, `SendPhoneOtp/VerifyPhoneOtpUseCase` |
| Repos | `data/repositories/client_auth_repository_impl.dart`, `client_session_repository_impl.dart`, `remember_me_repository_impl.dart`, `phone_auth_repository_impl.dart`, `social_auth_repository_impl.dart` |
| **Datasources (the calls)** | `data/datasources/supabase_client_auth_datasource.dart` (GoTrue), `data/datasources/client_account_guard.dart` (`clients` table + `check_phone_exists` RPC), `pending_phone_auth_datasource.dart` / `pending_social_auth_datasource.dart` (`NOT IMPLEMENTED` stubs) |
| DI | `lib/apps/client/core/di/client_di.dart` → `_registerAuthDependencies()` / `_registerAlternativeAuthDependencies()` |

All paths below are relative to `lib/apps/client/features/auth/`.

## Operations

| # | Operation | Today (Supabase) | Auth | Proposed .NET |
|---|---|---|---|---|
| A1 | Sign up (email + password + profile) | `POST /auth/v1/signup` → trigger creates `clients` row → app `upsert clients` | anon | `POST /api/v1/auth/client/register` |
| A2 | Phone uniqueness pre-check | `POST /rest/v1/rpc/check_phone_exists` | anon | `GET /api/v1/auth/client/phone-available?phone=` |
| A3 | Sign in | `POST /auth/v1/token?grant_type=password` → `GET /rest/v1/clients?id=eq.<uid>` guard | anon → session | `POST /api/v1/auth/client/login` |
| A4 | Vet a restored session | `GET /rest/v1/clients?select=id&id=eq.<uid>` | session | `GET /api/v1/auth/me` (must 401/403 a non-client token) |
| A5 | Sign out | `POST /auth/v1/logout` | session | `POST /api/v1/auth/logout` |
| A6 | Send password-reset email | `POST /auth/v1/recover` | anon | `POST /api/v1/auth/client/password-reset` |
| A7 | Set new password (from recovery link) | `PUT /auth/v1/user` `{password}` | recovery session | `PUT /api/v1/auth/client/password` |
| A8 | Token refresh | `POST /auth/v1/token?grant_type=refresh_token` (SDK, implicit) | refresh token | `POST /api/v1/auth/refresh` |
| — | Remember Me | **local only** (secure storage) | — | none |
| — | Phone OTP / Google / Apple | `NOT IMPLEMENTED` | — | see §Seams |

---

## A1 — Sign up

**Call chain:** `SignUpScreen` → `AuthCubit.signUp()` → `SignUpWithEmailUseCase` →
`ClientAuthRepositoryImpl.signUpWithEmail` → `SupabaseClientAuthDatasource.signUpWithEmail`
(`data/datasources/supabase_client_auth_datasource.dart:35-77`).

**Client-side validation before any request** (throws `FormatException('Please complete all fields correctly.')`):
`fullName.trim().length >= 2`, `ContactValidation.isValidEmail(email)`, `phone.trim()` non-empty.
`referralCode` is trimmed and upper-cased.

**Step 1 — phone pre-check (A2).** If the phone is already registered the flow stops with
`Exception('This phone number is already registered.\nPlease sign in instead, or use a different number.')`.
The pre-check *fails open*: any error ⇒ treated as "not registered".

**Step 2 — GoTrue sign-up**

```
POST /auth/v1/signup
Content-Type: application/json
apikey: <publishable key>

{
  "email": "<email.trim()>",
  "password": "<password>",
  "data": {
    "full_name": "<fullName.trim()>",
    "phone": "<phone.trim()>",
    "referral_code": "<CODE>"        // only when non-empty
  }
}
```

Response used: `response.user` (non-null ⇒ proceed; `user.id` is the new client id). If email
confirmation is enabled the session may be null — the app does not depend on it.

**Step 3 — best-effort profile upsert** (`client_account_guard.dart:81-97`, errors swallowed):

```
POST /rest/v1/clients
Prefer: resolution=merge-duplicates
{ "id": "<user.id>", "full_name": "...", "phone": "...", "email": "...", "updated_at": "<ISO now>" }
```

**Server-side rules (`BUSINESS RULE`) — trigger `handle_new_client_user()` on `auth.users` insert**
(`supabase/migrations/20260721140000_platform_office_onboarding.sql:425`):

* Skips the row when `raw_user_meta_data.role IN ('driver','office_user')` (captain/dashboard accounts). The client app sends **no** `role` key.
* Inserts `clients(id, full_name, phone, email)` with `full_name = coalesce(meta.full_name, meta.name, 'Unknown User')`, `phone = coalesce(meta.phone, auth.phone, '')`, `ON CONFLICT (id) DO NOTHING`.
* `clients.phone` is **unique** — a duplicate phone makes the whole sign-up fail with an opaque GoTrue 500. That is why A2 exists.

**Referral trigger `handle_new_user_referral()`** (`20260620090000_referral_system.sql:259`): on
every new auth user, issues a unique `referral_codes` row; if `meta.referral_code` matches an
existing code (and is not self), inserts `referrals(referrer_id, referred_id, referral_code,
referred_name, status='registered', registered_at=now())`.

Also: `handle_new_user_notification_prefs()` seeds notification preferences.

**Errors the app maps:** any `AuthException` ⇒ `Exception(e.message)` shown verbatim.

**Proposed .NET:** `POST /api/v1/auth/client/register`
`{ email, password, fullName, phone, referralCode? }` → `201 { user:{id,email,fullName,phone}, session:{accessToken,refreshToken,expiresIn} }`.
Must: reject duplicate phone with a machine code (`phone_already_registered`) and duplicate email
(`email_already_registered`); create the client profile + referral code atomically; record the
pending referral when `referralCode` is valid.

---

## A2 — Phone uniqueness pre-check

**Where:** `ClientAccountGuard.phoneRegistered()` (`client_account_guard.dart:66-78`).

```
POST /rest/v1/rpc/check_phone_exists
{ "p_phone": "<phone.trim()>" }
→ 200  true | false
```

SQL (`20260704214500_check_phone_rpc.sql`): `SELECT EXISTS (SELECT 1 FROM clients WHERE phone = p_phone)`.
`SECURITY DEFINER`, `GRANT EXECUTE … TO public` (callable anonymously). Exact-string match, no
normalisation.

**Proposed .NET:** `GET /api/v1/auth/client/phone-available?phone=E164` → `{ available: bool }`.
`NEEDS BACKEND DECISION`: normalise phone (E.164) on both write and check — today `0101…` and
`+20101…` are different strings.

---

## A3 — Sign in

**Call chain:** `SignInScreen` → `AuthCubit.signIn()` → `SignInWithEmailUseCase` → repo →
`SupabaseClientAuthDatasource.signInWithEmail` (`supabase_client_auth_datasource.dart:18-31`).

```
POST /auth/v1/token?grant_type=password
{ "email": "<email>", "password": "<password>" }
→ 200 { access_token, refresh_token, expires_in, token_type, user:{ id, email, user_metadata:{full_name, phone, ...} } }
```

Then **`assertRegistered()`** (`client_account_guard.dart:15-30`):

```
GET /rest/v1/clients?select=id&id=eq.<uid>
Accept: application/vnd.pgrst.object+json          (maybeSingle)
```

If no row ⇒ `POST /auth/v1/logout` and `Exception('This account is not registered as a client.\nUse the correct app for your account type.')`.
This is the wrong-app guard: captain/dashboard users share the same Auth pool but have no `clients` row.

**Errors:** `AuthException.message` verbatim (e.g. `Invalid login credentials`). Mapping to copy happens in `presentation/cubit/auth_error_message.dart`.

**After success:** `client_app.dart` → `FcmService.initialize(userId, appType:'client')` (see `notifications/`), and the shell is shown.

**Proposed .NET:** `POST /api/v1/auth/client/login` `{ email, password }` → `200 { session, user }`.
Must return `403 { code: "not_a_client" }` for a non-client identity instead of relying on a second call.

---

## A4 — Vet a restored session (app launch)

**Where:** `ClientApp._vetRestoredSession()` (`lib/apps/client/client_app.dart`) → `EnsureClientSessionUseCase` → `ClientAccountGuard.ensureClientSession()` (`client_account_guard.dart:43-63`).

Runs at launch while the splash is up, only if `auth.currentSession != null`:

```
GET /rest/v1/clients?select=id&id=eq.<uid>     (maybeSingle)
```

* row ⇒ keep session.
* no row ⇒ `signOut()`, return false (Welcome screen).
* **lookup error ⇒ keep session** (fails open so a flaky network never evicts a real rider).

**Why:** all three EWT apps share one Supabase session store per device; a captain session restored
inside the client app looked normal until the booking insert failed on `operation_bookings_client_id_fkey`.

**Proposed .NET:** issue audience-scoped tokens (`aud: client`) and have every client endpoint reject
others; then this call becomes `GET /api/v1/auth/me` returning the profile, or is unnecessary.

---

## A5 — Sign out

`SupabaseClientAuthDatasource.signOut` (`supabase_client_auth_datasource.dart:79-87`):

```
POST /auth/v1/logout            (global scope; on failure retried with scope=local)
```

`client_app.dart` reacts to the resulting `signedOut` event with `FcmService.deactivateToken`
(`PATCH /rest/v1/notification_tokens?user_id=eq.<uid>&token=eq.<fcm>` `{is_active:false}`).
Remember-Me credentials are **not** cleared on logout (by design).

**Proposed .NET:** `POST /api/v1/auth/logout` (revoke refresh token) — and deactivate the device token server-side in the same call if the token is sent.

---

## A6 — Password reset email

`SupabaseClientAuthDatasource.sendPasswordResetEmail` (`supabase_client_auth_datasource.dart:89-110`):

Client-side: `ContactValidation.isValidEmail` else `FormatException('Please provide a valid email address.')`.

```
POST /auth/v1/recover
{ "email": "<email.trim()>", "gotrue_meta_security": {}, ... }   redirect_to = easyway://reset-password/
```

**Errors mapped:** message containing `rate limit` or `security purposes` ⇒ `Exception('RateLimit')`
(the screen shows a cooldown); other `AuthException` ⇒ message verbatim; anything else ⇒
`'Unable to send reset link. Please try again later.'`.

**Deep link:** the email opens `easyway://reset-password/…`. `supabase_flutter` exchanges the code for
a **recovery session** and fires `AuthChangeEvent.passwordRecovery`; `client_app.dart` separately
listens to the same link (`app_links`) and pushes `AuthRoutes.resetPassword`.

**Proposed .NET:** `POST /api/v1/auth/client/password-reset { email }` → always `202`; email a link
`easyway://reset-password/?token=…`. Return `429 { code: "RateLimit" }` when throttled.

---

## A7 — Set the new password

`ResetPasswordCubit.submit` waits for the recovery session, then `UpdatePasswordUseCase` →
`SupabaseClientAuthDatasource.updatePassword` (`supabase_client_auth_datasource.dart:113-128`).

Client-side: `newPassword.length >= 6` else `FormatException('Password must be at least 6 characters.')`.

```
PUT /auth/v1/user
Authorization: Bearer <recovery session access token>
{ "password": "<newPassword>" }
```

After success the cubit **signs out** (`POST /auth/v1/logout`) so the rider signs in fresh.

**Proposed .NET:** `PUT /api/v1/auth/client/password { token, newPassword }` (token from the link)
— no session needed; return `400 { code: "token_expired" }` / `{ code: "weak_password" }`.

---

## A8 — Token refresh

Implicit in the SDK (`POST /auth/v1/token?grant_type=refresh_token`). `UNKNOWN`: access-token lifetime
(Supabase default 1 h was never configured). `NEEDS BACKEND DECISION`: rotation and revocation policy.

---

## Remember Me (local only)

`RememberMeStore` (`lib/apps/client/core/storage/remember_me_store.dart`) stores the email/password pair
in Keychain/Keystore (`SecureStorage`) under `client_remember_me_email` / `client_remember_me_password`.
No backend involvement. Coordinated by `presentation/cubit/remember_me_coordinator.dart`.

---

## Seams that are NOT implemented

`PendingPhoneAuthDatasource` and `PendingSocialAuthDatasource` throw
`AuthMethodException(AuthMethodFailure.unavailable)` for every call. The screens exist
(`phone_login_screen.dart`, `otp_verification_screen.dart`) and the buttons are inert while
`AuthMethod.isAvailable` is false.

Contracts the seams already assume, if the backend ever provides them:

| Method | Request | Response model (`data/models/`) |
|---|---|---|
| `sendOtp(phone E.164)` | — | `OtpChallengeModel.fromJson { phone, expires_in (s, default 300), resend_after (s, default 30), code_length (default 6) }` |
| `verifyOtp(phone, code)` | — | `SocialAuthResultModel.fromAuthUser(userMap)` — reads `id`, `email`, `user_metadata.full_name|name|display_name`, `phone|phone_number`, `avatar_url|picture` |
| `signInWithGoogle()` / `signInWithApple()` | — | same `SocialAuthResultModel` |

Failure enum the UI already handles: `AuthMethodFailure.{unavailable, cancelled, invalidCode, expiredCode, unknown}`.
A wrong vs expired OTP must be distinguishable (Supabase returns the same generic error for both).

---

## Data: `clients` table (what the client reads/writes)

| Column | Type | Written by | Read by |
|---|---|---|---|
| `id` | uuid = `auth.users.id` | trigger / upsert | guard, profile |
| `full_name` | text | trigger / upsert / profile update | profile |
| `phone` | text **unique** | trigger / upsert / profile update | profile, `check_phone_exists` |
| `email` | text | trigger / upsert / profile update | profile |
| `created_at`, `updated_at` | timestamptz | server / app | profile ("member since") |

`RLS` today (`20260721100000_multi_office_security_hardening.sql:443-454`): `clients_self_read`,
`clients_self_write`, `clients_self_insert` — all `id = auth.uid()`; offices may read customers who
transacted with them.

---

## Notes for the .NET team

1. **Single identity pool, three audiences.** Today one Auth user can be a client, captain or office
   user, distinguished only by which profile table has a row. Replace with explicit audience claims.
2. **Duplicate phone** is currently a 500 from the trigger unless A2 catches it first — make it a
   validation error on register.
3. **User metadata is load-bearing:** `full_name` and `phone` in the token/user object are read by the
   booking wizard, Paymob checkout and Home. Keep them on the identity or expose `/me`.
4. **Password reset uses a custom URL scheme** (`easyway://reset-password/`) — the email template
   must keep that link shape.
5. Error strings today are GoTrue's English messages shown verbatim; the app's own mapping lives in
   `presentation/cubit/auth_error_message.dart`. Prefer machine codes.
