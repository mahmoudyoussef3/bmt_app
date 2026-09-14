# Client · Profile

The profile hub (name/email/phone, member-since, completed/upcoming trip counts, active package),
editing the profile, and the Terms/Privacy screens (bundled text, no backend).

## Overview

| Layer | Files (relative to `lib/apps/client/features/profile/`) |
|---|---|
| Screens | `presentation/screens/profile_screen.dart` (`ProfileRoutes.profile`, shell tab), `legal_document_screen.dart` (`ClientRoutes.terms` / `ClientRoutes.privacy`) |
| Cubit | `ProfileCubit` (`presentation/cubit/profile_cubit.dart` — `load()`, `updateProfile({name,email,phone})`) |
| Use cases | `GetProfileDataUseCase`, `UpdateProfileUseCase` (`domain/usecases/`) |
| Repo | `data/repositories/profile_repository_impl.dart` (`ProfileUnauthenticatedException`) |
| **Datasources** | `data/datasources/supabase_profile_datasource.dart` (orchestration), `profile_queries.dart` (the reads/writes), `legal_content.dart` (static Terms/Privacy, `lastUpdated = 2026-06-03`) |
| Model / entity | `data/models/client_profile_model.dart` (`ClientProfileModel`, `ActivePackageModel`), `domain/entities/client_profile.dart`, `legal_document_data.dart` |

## Operations

| # | Operation | Today (Supabase) | Auth | Proposed .NET |
|---|---|---|---|---|
| F1 | Load profile hub (4 parallel reads) | `GET clients`, `GET subscriptions`, `GET operation_bookings` ×2 (counts) | session | `GET /api/v1/me/profile` |
| F2 | Update profile | `PATCH clients` + `PUT /auth/v1/user` (metadata) | session | `PATCH /api/v1/me/profile` |
| — | Terms / Privacy | local constants | — | optional `GET /api/v1/legal/{terms|privacy}` |

Both throw `ProfileUnauthenticatedException` without a session.

---

## F1 — `getProfile()` (`supabase_profile_datasource.dart:16-40`)

```
GET /rest/v1/clients?select=full_name,email,phone,created_at&id=eq.<uid>                                   (maybeSingle)

GET /rest/v1/subscriptions?select=package_name,route_name,end_date&client_id=eq.<uid>&status=eq.active
    &order=created_at.desc&limit=1                                                                           (maybeSingle)

GET /rest/v1/operation_bookings?select=id,operation_trips:public_trips!inner(status)
    &client_id=eq.<uid>&status=neq.cancelled&operation_trips.status=in.(completed)
Prefer: count=exact                                                                                          → completedTrips

GET /rest/v1/operation_bookings?select=id,operation_trips:public_trips!inner(status)
    &client_id=eq.<uid>&status=neq.cancelled&operation_trips.status=in.(scheduled,open_for_booking,boarding,in_progress)
Prefer: count=exact                                                                                          → upcomingTrips
```

**Counting rule (`ProfileQueries`, lines 12-30):** counts are by the **trip's** status (`public_trips`,
inner join), never the booking's, because `operation_bookings.status` does not reliably reach
`completed`. A cancelled booking never counts. "Upcoming" = every trip status short of
completed/cancelled (a boarding or in-progress trip still counts as upcoming for the rider).
Note `scheduled` is listed but `public_trips` never exposes it, so it contributes nothing.

Result (`ClientProfileModel.fromRow`): `id = uid`, `name = full_name`, `email = clients.email ?? session email`,
`phone`, `memberSince = created_at`, `completedTrips`, `upcomingTrips`,
`activePackage { name=package_name, routeName=route_name, endDate }` or null.

**Proposed .NET:** `GET /api/v1/me/profile` → `{ id, name, email, phone, memberSince, completedTrips, upcomingTrips, activePackage? }`.

---

## F2 — `updateProfile({name, email, phone})` (line 43-74)

```
PATCH /rest/v1/clients?id=eq.<uid>
{ "full_name": "<name>", "email": "<email>", "phone": "<phone>", "updated_at": "<ISO now>" }

PUT /auth/v1/user                      // best-effort, errors swallowed
{ "data": { "full_name": "<name>", "phone": "<phone>" } }
```

Then re-runs F1 and returns the fresh profile.

**Errors mapped:** Postgres `23505` (unique violation on `clients.phone`/`email`) ⇒
`'That phone number or email is already used by another account.'`; any other `PostgrestException` ⇒
`'We could not save your details. Please try again.'`.

`RLS`: `clients_self_write` (`id = auth.uid()`). Changing the email here does **not** change the login
email (GoTrue `email` is untouched) — only `clients.email` and the metadata.

**Proposed .NET:** `PATCH /api/v1/me/profile { name, email, phone }` → `200 Profile`;
`409 { code: "phone_already_registered" | "email_already_registered" }`. `NEEDS BACKEND DECISION`:
whether editing email/phone must go through a verification flow.

---

## Notes for the .NET team

1. The identity's `full_name`/`phone` metadata is duplicated into `clients`; the booking RPC reads the **metadata**, the profile screen reads the **table**. Keep them in sync or have one source.
2. The trip-count queries use PostgREST's `!inner` embed + `count=exact` header — replace with two `COUNT` queries joined on trips.
3. Terms/Privacy are shipped in the binary (`legal_content.dart`); a `GET /legal/{doc}` endpoint is optional and would let Legal publish without a release.
