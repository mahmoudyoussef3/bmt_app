# Captain · Profile

The driver's own record plus two lifetime counters and the vehicle from their most recent trip.
Read-only — there is no profile edit in the captain app.

## Overview

| Layer | Files (relative to `lib/apps/captain/features/profile/`) |
|---|---|
| Screen | `presentation/pages/driver_profile_page.dart` (Profile tab of `CaptainAppShell`; hosts the sign-out button `presentation/widgets/driver_profile_sign_out_button.dart` → `CaptainAuthCubit.signOut()`, see `../auth/` A5) |
| Cubit | `DriverProfileCubit` (`presentation/cubit/driver_profile_cubit.dart` — `load()` :11-18, `refresh()`) — mounted with `..load()` by the shell (`captain_app_shell.dart:56-57`) |
| Use case | `GetDriverProfileUseCase` |
| Repo | `data/repositories/driver_profile_repository_impl.dart` |
| **Datasource** | `data/datasources/driver_profile_datasource.dart` |
| Entity | `domain/entities/driver_profile.dart` (`DriverProfile`, `DriverAccountStatus {active, suspended, archived}`; derived `isLicenseExpired`, `isLicenseExpiringSoon` (≤ 30 days), `hasVehicle`, `hasRating`) |

## Operations

| # | Operation | Today (Supabase) | Auth | Proposed .NET |
|---|---|---|---|---|
| P0 | Identity (driver id + office name) | `POST rpc/captain_session_context` (cached) | session | part of `GET /api/v1/captain/session` |
| P1 | Driver row | `GET drivers?select=*&id=eq.<driverId>` | session | `GET /api/v1/captain/profile` (one response for P1–P3) |
| P2 | Lifetime counters | `GET operation_trips?select=id,trip_passengers(id)&driver_id=eq.&status=eq.completed` | session | same |
| P3 | Last vehicle | `GET operation_trips?select=vehicles(…)&driver_id=eq.&order=trip_date.desc&limit=1` | session | same |

---

## `getProfile()` (`driver_profile_datasource.dart:13-80`)

Preconditions: a session (`المستخدم غير مسجّل الدخول`) and a resolved identity via
`CaptainIdentityProvider.ensure()` (`لم يتم العثور على ملف السائق، حاول تسجيل الدخول مرة أخرى`) —
this is where `officeName` comes from (:73).

### P1 — driver row (:26-31)
```
GET /rest/v1/drivers?select=*&id=eq.<driverId>     Accept: application/vnd.pgrst.object+json
→ 200 { "id","full_name","phone","license_number","profile_image_url","rating","employee_code",
        "license_expiry_date","hire_date","status", … }
```
**App reads:** `full_name` (fallback `'السائق'`), `phone`, `license_number`, `profile_image_url`,
`rating` (numeric → `averageRating`, 0 when null), `employee_code`, `license_expiry_date` (date →
`DateTime.tryParse`), `hire_date`, `status` (`suspended` / `archived` / else `active`).
`RLS`: `drivers_self_read` (`user_id = auth.uid()`, `20260721090200:319-321`) — the `id=eq.` filter is
just a convenience; a captain can only ever see their own row. Column-level: the base table also
holds `national_id`, `user_id`, `office_id`, … which `select=*` returns and the app ignores
(`SUPABASE-SPECIFIC` over-fetch — do not expose `national_id` in the .NET DTO).

### P2 — completed trips + passengers carried (:33-43)
```
GET /rest/v1/operation_trips?select=id,trip_passengers(id)&driver_id=eq.<driverId>&status=eq.completed
→ 200 [ { "id":"…", "trip_passengers":[ {"id":"…"}, … ] }, … ]
```
`totalTrips` = rows; `totalPassengers` = Σ manifest rows **of any status** (cancelled and no-show
included — a known over-count; `NEEDS BACKEND DECISION`: count `confirmed|completed` only, which is
what `../trip_history/` shows as "boarded"). Unbounded — grows with the driver's career.

### P3 — most recent trip's vehicle (:45-55)
```
GET /rest/v1/operation_trips?select=vehicles(vehicle_code,plate_number,capacity,model)&driver_id=eq.<driverId>&order=trip_date.desc&limit=1   (.maybeSingle())
→ 200 { "vehicles": { "vehicle_code":"V-12","plate_number":"…","capacity":14,"model":"Hiace" } } | null
```
**App reads:** the embedded vehicle → `vehicleCode`, `plateNumber`, `vehicleModel`, `vehicleCapacity`.
"Most recent" is by `trip_date` only (any status). `RLS`: `trips_captain_read` + `vehicles_captain_read`.

`RLS` note: `trips_captain_read` is `office_id = captain_office_id() AND driver_id = current_driver_id()`,
so a driver who moved offices would lose history in P2/P3 — matches the platform's office isolation.

---

**Proposed .NET:** `GET /api/v1/captain/profile` →
```json
{ "id", "name", "phone", "employeeCode", "officeName",
  "licenseNumber", "licenseExpiryDate", "hireDate", "photoUrl",
  "averageRating", "totalTrips", "totalPassengers",
  "vehicle": { "code", "plateNumber", "model", "capacity" } | null,
  "accountStatus": "active|suspended|archived" }
```
`rating` on `drivers` is maintained server-side by `refresh_driver_rating` from `trip_reviews`
(dashboard/reviews doc) — expose the stored value, do not recompute per request.

## Notes for the .NET team

1. Three round-trips collapse into one read-model; the counters should be computed server-side with
   the `confirmed|completed` boarding rule for consistency with the rest of the captain app.
2. `accountStatus` other than `active` can only be seen for a moment: `current_driver_id()` requires
   `status='active'`, so a suspended driver's next `captain_session_context` returns `null` and they
   are logged out of the shell. Keep the field for the banner but do not rely on it for authorization.
3. No profile mutation exists — photo, phone and licence data are edited by the office (fleet module).
