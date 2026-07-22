# platform-create-office

Onboards a transportation office and its first Dashboard administrator.

## Why an Edge Function at all

Only one step of onboarding needs a privilege the Dashboard must never hold: creating the
`auth.users` row, which requires the Supabase Auth Admin API and therefore the
service-role key. Everything else — the office row, its marketplace identity, its join
code, its `office_users` row — is written by `platform_create_office()` in a single
transaction.

That RPC is called **with the caller's own JWT**, not with the service-role key, and it
re-checks `is_platform_admin()` itself. So this function grants no authority: a caller who
is not a platform admin is refused by Postgres even if they somehow reached the function.
The service key is used for exactly two calls, `POST /auth/v1/admin/users` and
`DELETE /auth/v1/admin/users/{id}`.

## Contract

`POST` with the operator's `Authorization: Bearer <jwt>`.

```jsonc
{
  "name": "مكتب الإسكندرية",          // required, 3–120 chars
  "admin_username": "ops.alex",        // required, ^[a-z0-9][a-z0-9._-]*$, 3–32
  "slug": "alex-office",               // optional; server mints one when absent
  "description": "…",                  // optional, ≤500
  "logo_url": "https://…",             // optional, https only
  "phone": "01000000000",              // optional
  "email": "ops@example.com",          // optional — the office's PUBLIC contact,
                                       //   not a login address
  "service_areas": ["القاهرة"],        // optional, ≤30
  "admin_full_name": "…",              // optional
  "admin_password": "…"                // optional, ≥10; omit to have one generated
}
```

Success is `201`:

```jsonc
{
  "office": {
    "office_id": "…", "name": "…", "slug": "…",
    "status": "active",           // its own dashboard works immediately
    "listing_status": "draft",    // invisible to clients until published
    "join_code": "KRPT7F2M",
    "username": "ops.alex", "role": "dashboard_admin"
  },
  "login_username": "ops.alex",
  "temporary_password": "…"       // ONLY when the server generated it
}
```

Failure is a machine code the Dashboard maps to Arabic:

`platform_admin_required` · `not_authenticated` · `slug_taken` · `username_taken` ·
`admin_user_already_assigned` · `invalid_username` · `invalid_slug` ·
`invalid_office_name` · `invalid_logo_url` · `invalid_email` · `invalid_phone` ·
`description_too_long` · `too_many_service_areas` · `weak_password` ·
`auth_user_creation_failed` · `onboarding_failed`

## Secrets

The generated password is returned once, in the response body. It is **not** logged, **not**
stored, and **not** recoverable — a lost password is reset, never looked up. Neither the
password nor the request body is ever passed to `console.log`; only status codes and ids
are. The join code has the same one-time character for the platform admin: after this
response only the office itself can read it, through `office_join_code()`.

## Atomicity

`auth.users` cannot join the SQL transaction, so the order is: pre-check the two collidable
names → create the auth user → run the RPC. If the RPC fails, the auth user is deleted
(compensating write). If that delete also fails, the user id is logged with
`orphaned auth user, delete manually` — an orphan can sign in to nothing, since
`resolve_office_user_login` finds no username for it, but it does hold the login address.

## Deploy

```bash
supabase functions deploy platform-create-office
```

`SUPABASE_URL`, `SUPABASE_ANON_KEY` and `SUPABASE_SERVICE_ROLE_KEY` are injected
automatically. Keep JWT verification on (the default) — it is a second gate in front of the
function's own `is_platform_admin` check.

Requires migration `20260721140000_platform_office_onboarding.sql`.
