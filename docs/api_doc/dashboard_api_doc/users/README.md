# Dashboard · Users & Permissions (المستخدمون والصلاحيات — office staff)

The office's staff directory. An **owner** (`dashboard_admin`) creates a login for a colleague
(username + role + optional password), resets a password, changes a role, and disables /
re-enables an account. Everything is office-scoped server-side; the office id is never a
parameter. Creating an account and resetting a password need the Auth Admin API (service-role
key), so they go through the **`office-manage-user` Edge Function**; SQL owns membership and
every authorization rule.

## Overview

| Layer | Files (relative to `lib/apps/dashboard/features/users/`) |
|---|---|
| Screen | `presentation/screens/` (`DashboardRoutes.users` = `/users`, `DashboardRoutes.permissions` = `/permissions` → same module) |
| Cubit | `presentation/cubit/users_cubit.dart` |
| Use cases | `domain/usecases/` (`GetUsersUseCase`, `CreateStaffUseCase`, `ResetStaffPasswordUseCase`, `UpdateUserRoleUseCase`, `SetUserStatusUseCase`, `GetCurrentUserRoleUseCase`) |
| Repo interface | `domain/repositories/users_repository.dart` |
| **Datasource** | `data/datasources/users_datasource.dart` (`SupabaseUsersDatasource implements UsersRepository`) |
| Entities | `domain/entities/app_user.dart` (`AppUser { id, userId, username, fullName, status, email, role, createdAt }`), `staff_account.dart` (`StaffAccountRequest.toPayload()`, `StaffCredentials { username, temporaryPassword?, isReset }`) |
| Permission | `DashboardPermission.permissions` / `users` (admin only); limit `max_admin_users` (stock, metered on `office_users` insert) |

## Operations

| # | Operation | Today (Supabase) | Proposed .NET |
|---|---|---|---|
| U1 | Staff list | `POST rpc/get_dashboard_users` | `GET /api/v1/dashboard/staff` |
| U2 | Create staff login | Edge `POST /functions/v1/office-manage-user { action:'create', … }` | `POST /api/v1/dashboard/staff` |
| U3 | Reset password | Edge `POST /functions/v1/office-manage-user { action:'reset_password', … }` | `POST /api/v1/dashboard/staff/{id}/password-reset` |
| U4 | Change role | `POST rpc/office_update_staff_role` | `PATCH /api/v1/dashboard/staff/{id}/role` |
| U5 | Enable / disable | `POST rpc/office_set_staff_status` | `PATCH /api/v1/dashboard/staff/{id}/status` |
| U6 | My role | `GET office_users?select=role&user_id=eq.<uid>&status=eq.active&limit=1` | `GET /api/v1/dashboard/staff/me/role` (or from the token) |

Error codes (mapped in `_messageForCode`, line 187; **keep them**): `dashboard_admin_required`,
`not_an_office_user`, `not_authenticated`, `username_taken`, `invalid_username`, `invalid_full_name`,
`weak_password`, `invalid_role`, `cannot_change_own_role`, `cannot_disable_self`, `last_admin_required`,
`staff_user_already_assigned`, `staff_not_found` / `staff_user_not_found` / `staff_user_required`,
`auth_user_creation_failed`, `password_reset_failed`, `staff_action_failed` (500), `staff_action_rejected`,
`invalid_payload` / `invalid_action` / `method_not_allowed`. Unmapped codes matching `^[a-z0-9_]{1,48}$`
are shown verbatim. `LicensingGuard.check` runs first on every path (the Edge Function forwards Postgres'
`detail` so a `max_admin_users` refusal keeps its verdict).

---

## U1 — `getUsers()` (`users_datasource.dart:45`)

```
POST /rest/v1/rpc/get_dashboard_users {}
→ 200 [ { id (office_users.id), user_id, username, full_name, email, role: dashboard_admin|support_agent, status: active|disabled, created_at } ]
```
SQL (`20260721090300_multi_office_rpcs.sql:680`): `office_users ⋈ auth.users` for `current_office_id()`,
newest first; `not_an_office_user` otherwise. Both roles may call it (the UI hides the module from agents).
`email` is the synthetic `<username>@office.ewt.internal` for provisioned staff or the real address for a
self-registered owner.

## U2 — Create: `createUser(request)` (line 51)

```
POST /functions/v1/office-manage-user        Authorization: Bearer <caller JWT>
{ "action": "create", "username": "<lowercase>", "role": "dashboard_admin|support_agent", "full_name"?: "…", "password"?: "≥10 chars" }
→ 200 { "staff": { …office_users row… }, "login_username": "<username>", "temporary_password"?: "<16 chars, only when generated>" }
→ 4xx/500 { "error": "<code>", "detail"?: "<postgres DETAIL>" }
```
Edge Function flow (`supabase/functions/office-manage-user/index.ts`): validate (`invalid_username`
`^[a-z0-9][a-z0-9._-]*$` 3..32, `weak_password` < 10) → `rpc office_staff_username_available` with the
caller's JWT (`username_taken` 409) → Auth Admin `createUser({ email: '<username>@office.ewt.internal',
password, email_confirm: true })` → `rpc office_create_staff(p_user_id, p_username, p_role, p_full_name)`
with the caller's JWT → on failure the auth user is deleted again (compensation). The generated password is
returned **once** and stored nowhere.

`BUSINESS RULE` — `office_create_staff` (`20260815100000_office_staff_provisioning.sql:202`):
`assert_office_staff_admin()` (`not_an_office_user`, `dashboard_admin_required`), `staff_user_required`,
`staff_user_not_found` (auth user must exist), `staff_user_already_assigned` (one office per account),
`invalid_username`, `username_taken` (platform-wide unique), `invalid_full_name`, `invalid_role`; inserts
`office_users { office_id: current_office_id(), user_id, username, full_name, role, status:'active' }`.
`max_admin_users` stock quota (trigger on insert) → `quota_exceeded`.

**Proposed .NET:** `POST /api/v1/dashboard/staff { username, role, fullName?, password? }` → `201 { staff, loginUsername, temporaryPassword? }`
— the identity provider call and the membership insert in one unit of work with compensation.

## U3 — Reset password: `resetPassword({officeUserId, password})` (line 62)

```
POST /functions/v1/office-manage-user
{ "action": "reset_password", "office_user_id": "<office_users.id>", "password"?: "≥10" }
→ 200 { "login_username", "temporary_password"? }
```
Function: `rpc office_staff_reset_target(p_office_user_id)` (owner-only, same office, `staff_not_found`)
→ Auth Admin `PUT /auth/v1/admin/users/{id} { password }` (`password_reset_failed` 502).
**Proposed .NET:** `POST /api/v1/dashboard/staff/{id}/password-reset { password? }`.

## U4 — Role: `updateUserRole(officeUserId, role)` (line 79)

`POST rpc/office_update_staff_role { p_office_user_id, p_role }` → `{ …staff row… }`.
`BUSINESS RULE`: owner only; `invalid_role`; `staff_not_found`; **`cannot_change_own_role`**;
**`last_admin_required`** (an office must keep ≥ 1 active `dashboard_admin`).

## U5 — Status: `setUserStatus(officeUserId, {active})` (line 87)

`POST rpc/office_set_staff_status { p_office_user_id, p_status: 'active'|'disabled' }` → row.
`invalid_status`, `staff_not_found`, **`cannot_disable_self`**, **`last_admin_required`**. Removal is a
**disable, never a delete** (the `auth.users` row and the globally-unique username stay).

## U6 — My role (line 98)

`GET office_users?select=role&user_id=eq.<uid>&status=eq.active&limit=1` (RLS: own office). Redundant with
A3 (`current_office_context`); a .NET token claim replaces it.

## Notes for the .NET team

1. Three lockout rules (no self role change, no self disable, last active owner cannot be stripped) are the
   product's guarantee that an office can always be administered from inside the product. Port them verbatim.
2. Usernames are platform-unique (`uq_office_users_username`); the login email is synthetic and internal.
3. Never return a password the caller supplied; return a generated one exactly once.
4. The Edge Function pattern (identity call with a privileged key + business write with the caller's
   credentials) maps naturally to a .NET service that talks to the identity provider's admin API.
