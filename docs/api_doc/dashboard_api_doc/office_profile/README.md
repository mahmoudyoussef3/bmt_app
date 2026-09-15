# Dashboard · Office Profile (ملف المكتب)

The office's own row in `offices`: marketplace profile (name, description, logo, phone, email,
service areas), read-only status/listing/rating, and the **captain join code** credential card
(read + rotate). Rebuilt 2026-08-30 on the form kit. Writes are RLS-gated to the owner; the join
code is readable only through definer RPCs because its columns are revoked from the API role.

## Overview

| Layer | Files (relative to `lib/apps/dashboard/features/office_profile/`) |
|---|---|
| Screen | `presentation/screens/` (`DashboardRoutes.officeProfile` = `/office-profile`) |
| Cubit | `presentation/cubit/office_profile_cubit.dart` (after a save it calls `DashboardAuthCubit.refreshContext()` so the shell name/logo update) |
| Use cases | `domain/usecases/` (`GetOfficeProfileUseCase`, `UpdateOfficeProfileUseCase`, `UploadOfficeLogoUseCase`, `RotateJoinCodeUseCase`) |
| Repo | `data/repositories/office_profile_repository_impl.dart` |
| **Datasource** | `data/datasources/supabase_office_profile_datasource.dart` (`SupabaseOfficeProfileDatasource implements OfficeProfileDatasource`) |
| Entity | `domain/entities/office_profile.dart` (`OfficeProfile`, `OfficeProfileEdit`) |
| Permission | `DashboardPermission.officeProfile` (admin only); limit feature `logo_max_kb` (per-file ceiling on upload) |

## Operations

| # | Operation | Today (Supabase) | Role (server) | Proposed .NET |
|---|---|---|---|---|
| O1 | Read profile | `GET offices?select=<14 cols>&id=eq.<office>` (`.maybeSingle()`) + O2 | both | `GET /api/v1/dashboard/office` |
| O2 | Read join code | `POST rpc/office_join_code_info` (fallback `rpc/office_join_code`) | both | `GET /api/v1/dashboard/office/join-code` |
| O3 | Update profile | `PATCH offices?id=eq.<office>` (`.select().maybeSingle()`) | admin | `PATCH /api/v1/dashboard/office` |
| O4 | Upload logo | Storage `office-logos/<officeId>/<epoch>-<slug>.<ext>` → public URL | admin | `POST /api/v1/dashboard/office/logo` |
| O5 | Rotate join code | `POST rpc/office_rotate_join_code` → O1 | admin | `POST /api/v1/dashboard/office/join-code/rotate` |

---

## O1 — `getProfile()` (`supabase_office_profile_datasource.dart:43`)

```
GET /rest/v1/offices?select=id,name,slug,logo_url,description,phone,email,service_areas,status,listing_status,rating,ratings_count,created_at,updated_at
    &id=eq.<session office>
```
`RLS` `offices_operator_read` (`id = current_office_id()`), plus **column privileges**
(`20260721100200`, `20260721140000`): `join_code` / `join_code_rotated_at` are revoked from
`authenticated` — selecting them fails the whole statement — and `listing_status` is readable but not
updatable (an office cannot publish itself). `status` ∈ `active | suspended`, `listing_status` ∈
`draft | listed | unlisted`, `service_areas` is `text[]`. A null row ⇒ 'تعذر قراءة بيانات المكتب…'.

## O2 — Join code (`_fetchJoinCode` line 78)

```
POST /rest/v1/rpc/office_join_code_info {}   → 200 { "code": "ABCD2345", "rotated_at": "<ts>|null" }
POST /rest/v1/rpc/office_join_code {}        → 200 "ABCD2345"          (older fallback, no date)
```
Both resolve the office from `current_office_id()`; a failure of both is reported as "could not read", not
as "no code". The code is what a captain types in the Captain app's join screen to bind their request to
this office (`submit_captain_request`); alphabet `ABCDEFGHJKLMNPQRSTUVWXYZ23456789`, unique platform-wide.
The migration `20260830090000_office_join_code_info.sql` may not be applied yet on prod — the fallback exists for that.

## O3 — `updateProfile(edit)` (line 132)

```
PATCH /rest/v1/offices?id=eq.<office>&select=<14 cols>
{ "name": "…", "description": "…", "logo_url": "<url>|null", "phone": "…|null", "email": "…|null", "service_areas": ["…"] }
```
`RLS` `offices_operator_update`: `id = current_office_id() and office_role() = 'dashboard_admin'`. A
support agent's update returns **no row** (mapped to 'لا تملك صلاحية تعديل بيانات المكتب.'). `slug`,
`status`, `listing_status`, `rating` are never written here (slug/listing are platform-admin operations,
see `platform_admin/`).

## O4 — `uploadLogo({bytes, fileName})` (line 167)

```
POST /storage/v1/object/office-logos/<officeId>/<epoch ms>-<slugified name>.<png|jpg|webp>
Content-Type: image/png | image/webp | image/jpeg
→ public URL <base>/storage/v1/object/public/office-logos/<path>
```
Bucket (`20260801090000_office_logo_storage.sql`): public read; write policy `office_logos_owner_write`
(owner of the office, folder `[1]` must equal the office id, or platform admin); `allowed_mime_types`
= the three image types; `logo_max_kb` per-file limit enforced by `trg_quota_storage` → `quota_exceeded`
(without the numbers — Storage drops `DETAIL`). The URL is then saved through O3.

## O5 — `rotateJoinCode()` (line 108)

`POST rpc/office_rotate_join_code {}` → `"<new code>"`; loops until unique, stamps `join_code_rotated_at`.
`dashboard_admin_required` / `not_an_office_user`. The screen re-reads O1 afterwards. Rotation does **not**
invalidate captains already bound (the code is only used at request time).

## Notes for the .NET team

1. The office row is the tenant record; keep the two axes separate: `status` (operational, platform-set)
   and `listing_status` (marketplace visibility, platform-set). The office edits neither.
2. The join code is a credential: treat `GET /office/join-code` as sensitive (owner + agent can read it today).
3. Public marketplace reads of offices go through the `public_offices` view (client app) — the 8 public
   columns must stay in sync with what O3 lets the office edit.
