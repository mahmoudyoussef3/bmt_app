# office-manage-user

Creates a Dashboard login for a colleague inside an existing office, and resets that
colleague's password. Called by the office **owner** (`dashboard_admin`) from
المستخدمون والصلاحيات.

## Why an Edge Function at all

Only one step needs a privilege the Dashboard must never hold: writing `auth.users`,
which requires the Supabase Auth Admin API and therefore the service-role key.
Everything about *membership* — which office, which role, which username, and every rule
that stops an office locking itself out — is decided by
`20260815100000_office_staff_provisioning.sql`.

Those RPCs are called **with the caller's own JWT**, not with the service-role key, and
each re-checks `assert_office_staff_admin()` itself. So this function grants no
authority: a support agent who reached it is refused by Postgres, and a caller who names
another office's staff row is refused by `office_staff_reset_target`. The service key is
used for exactly three calls: `POST /auth/v1/admin/users`,
`PUT /auth/v1/admin/users/{id}` and `DELETE /auth/v1/admin/users/{id}`.

## Contract

`POST` with the owner's `Authorization: Bearer <jwt>`.

### `action: "create"` (the default when `action` is absent)

```jsonc
{
  "action": "create",
  "username": "ops.sara",      // required, ^[a-z0-9][a-z0-9._-]*$, 3–32, unique platform-wide
  "full_name": "سارة محمد",     // optional, ≤120 — shown inside the dashboard
  "role": "support_agent",     // optional; support_agent when absent, never owner by default
  "password": "…"              // optional, ≥10; omit to have one generated
}
```

Success is `201`:

```jsonc
{
  "staff": {
    "id": "…",                 // office_users.id — what every later action names
    "user_id": "…", "username": "ops.sara", "full_name": "سارة محمد",
    "email": "ops.sara@office.ewt.internal",
    "role": "support_agent", "status": "active", "created_at": "…"
  },
  "login_username": "ops.sara",
  "temporary_password": "…"    // ONLY when the server generated it
}
```

### `action: "reset_password"`

```jsonc
{
  "action": "reset_password",
  "office_user_id": "…",       // required — office_users.id, NOT an auth user id
  "password": "…"              // optional, ≥10; omit to have one generated
}
```

Success is `200` with `login_username` and, when generated, `temporary_password`.

The target is named by its `office_users.id` on purpose. The RPC maps that to an auth
user id and refuses any row outside the caller's office, so the only ids this function
hands to the Admin API are ids Postgres just authorized.

### Failure

A machine code the Dashboard maps to Arabic:

`not_authenticated` · `dashboard_admin_required` · `not_an_office_user` ·
`username_taken` · `invalid_username` · `invalid_full_name` · `invalid_role` ·
`weak_password` · `staff_not_found` · `staff_user_already_assigned` ·
`staff_user_not_found` · `invalid_action` · `auth_user_creation_failed` ·
`password_reset_failed` · `staff_action_failed`

Licensing refusals (`quota_exceeded` on `max_admin_users`, `license_read_only`) come
through `office_create_staff` with the full verdict attached, and the Dashboard's
`LicensingGuard` turns them into the upgrade card rather than an error string.

## Secrets

A generated password is returned once, in the response body. It is **not** logged,
**not** stored and **not** recoverable — a lost password is reset, never looked up.
Neither the password nor the request body is ever passed to `console.log`; only status
codes and ids are.

## Atomicity

`auth.users` cannot join the SQL transaction, so `create` runs: pre-check the username →
create the auth user → run `office_create_staff`. If the RPC fails (a race on the
username, a licensing quota, a revoked role), the auth user is deleted. If that delete
also fails, the id is logged with `orphaned auth user, delete manually` — an orphan can
sign in to nothing, since `resolve_office_user_login` finds no username for it, but it
does hold the login address.

`reset_password` has nothing to compensate: the Admin API call is the whole operation.

## Deploy

```bash
supabase functions deploy office-manage-user
```

`SUPABASE_URL`, `SUPABASE_ANON_KEY` and `SUPABASE_SERVICE_ROLE_KEY` are injected
automatically. Keep JWT verification on (the default) — it is a second gate in front of
the function's own Postgres checks.

Requires migration `20260815100000_office_staff_provisioning.sql`.
