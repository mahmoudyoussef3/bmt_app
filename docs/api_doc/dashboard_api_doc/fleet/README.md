# Dashboard · Fleet (إدارة الأسطول — السائقون / المركبات)

Drivers, vehicles, the driver↔vehicle **assignment** (one active pairing per driver and per
vehicle), driver/vehicle documents with expiry tracking, vehicle photos, and the derived
"duty" view (which bus is on which trip). The Assignments and Documents tabs were folded into
the driver/vehicle forms (2026-08-20); the assignment table is still written explicitly by the
datasource. Everything is **direct table access under RLS + triggers** — there are no fleet RPCs.

## Overview

| Layer | Files (relative to `lib/apps/dashboard/features/fleet/`) |
|---|---|
| Screens | `presentation/screens/` (`DashboardRoutes.fleet` = `/fleet`, `/drivers`, `/vehicles` open the same workspace on a tab) |
| Cubits | `presentation/cubit/fleet_cubit.dart` (workspace), `fleet_drivers/…`, `fleet_vehicles/…`, `fleet_documents/presentation/cubit/fleet_documents_cubit.dart` |
| Use cases | `domain/usecases/` (`GetFleetWorkspaceUseCase` — also used by Home/Business Overview), `fleet_documents/domain/usecases/fleet_documents_usecases.dart` (`UploadDocumentFileUseCase`, `DeleteDocumentFileUseCase`) |
| Repos | `data/repositories/fleet_repository_impl.dart`, `fleet_documents/data/repositories/fleet_documents_repository_impl.dart` |
| **Datasource** | `data/datasources/supabase_fleet_datasource.dart` (`SupabaseFleetDatasource implements FleetDatasource`) |
| Models / entities | `data/models/fleet_models.dart` (`FleetDriverModel`, `FleetVehicleModel`, `FleetAssignmentModel`, `FleetDocumentModel`), `shared/domain/entities/` (`fleet_driver.dart`, `fleet_vehicle.dart` (`SeatConfiguration`), `fleet_assignment.dart`, `fleet_document.dart`, `fleet_workspace.dart`) |
| Upload helpers | `shared/core/utils/fleet_upload_helpers.dart`, `fleet_documents/presentation/widgets/fleet_document_manager.dart`, `shared/presentation/utils/fleet_pending_docs_uploader.dart`, `fleet_vehicles/presentation/widgets/fleet_vehicle_form_view.dart` |
| Permission | `DashboardPermission.fleet / drivers / vehicles` (admin only); feature key `drivers`; limits `max_drivers`, `max_vehicles` (stock meters, enforced by trigger on insert) |

## Operations

| # | Operation | Today (Supabase) | Role (server) | Proposed .NET |
|---|---|---|---|---|
| F1 | Fleet workspace (7 reads) | `GET drivers`, `GET vehicles`, `GET assignments`, `GET operation_trips` ×2, `GET driver_documents`, `GET vehicle_documents` | both (read) | `GET /api/v1/dashboard/fleet` |
| F2 | Create driver | `POST drivers` (+ F10 when a vehicle is chosen) | admin | `POST /api/v1/dashboard/drivers` |
| F3 | Update driver | `PATCH drivers` (+ F10) | admin | `PATCH /api/v1/dashboard/drivers/{id}` |
| F4 | Driver status | `PATCH drivers {status}` (+ end active assignment) | admin | `PATCH /api/v1/dashboard/drivers/{id}/status` |
| F5 | Delete driver | `GET operation_trips` guard → `DELETE assignments` → `DELETE driver_documents` → `DELETE drivers` | admin | `DELETE /api/v1/dashboard/drivers/{id}` |
| F6 | Create vehicle | `POST vehicles` (+ F10) | admin | `POST /api/v1/dashboard/vehicles` |
| F7 | Update vehicle | `PATCH vehicles` (+ F10) | admin | `PATCH /api/v1/dashboard/vehicles/{id}` |
| F8 | Vehicle status | `PATCH vehicles {status}` (+ end active assignment) | admin | `PATCH /api/v1/dashboard/vehicles/{id}/status` |
| F9 | Delete vehicle | guard → `DELETE assignments` → `DELETE vehicle_documents` → `DELETE vehicles` | admin | `DELETE /api/v1/dashboard/vehicles/{id}` |
| F10 | Assign driver ↔ vehicle | `GET assignments` (active for driver / vehicle) → `PATCH assignments {status:'ended'}` ×0–2 → `POST assignments` | admin | `POST /api/v1/dashboard/assignments` |
| F11 | Reassign vehicle | `GET assignments` → `PATCH {ended}` → F10 | admin | `PATCH /api/v1/dashboard/assignments/{id}` |
| F12 | End assignment | `GET assignments` → `PATCH {status:'ended', ended_at, history}` | admin | `DELETE /api/v1/dashboard/assignments/{id}` (soft) |
| F12b | Hard-delete assignment | `DELETE assignments?id=eq.` | admin | — (do not port) |
| F13 | Create / update / delete document | `POST|PATCH|DELETE driver_documents \| vehicle_documents` | admin | `POST|PATCH|DELETE /api/v1/dashboard/{drivers\|vehicles}/{ownerId}/documents[/{docId}]` |
| F14 | Upload file | Storage `documents` / `vehicle-images` `uploadBinary(upsert)` → `getPublicUrl` | admin | `POST /api/v1/dashboard/files` |
| F14b | Delete file | Storage `remove([path])` | admin | `DELETE /api/v1/dashboard/files` |

`RLS` (`20260815110000_fleet_role_authority.sql`): every fleet table has `*_office_read` for both roles and
`*_office_insert/update/delete` requiring **`office_role() = 'dashboard_admin'`** (documents resolve the office
through the parent driver/vehicle row). Reads are deliberately not role-restricted: Home, Live Ops, Bookings
and Reports embed driver/vehicle names for support agents. Errors funnel through `_formatPostgrestError`
(line 1059): `LicensingGuard.check` first, then `_translateFleetError` (line 1018) for:
`assignment_cross_office`, `assignment_driver_unavailable`, `assignment_vehicle_unavailable`,
`uniq_active_assignment_per_driver`, `uniq_active_assignment_per_vehicle`, `driver_vehicle_mismatch`,
`driver_has_no_vehicle`, `vehicle_delete_forbidden`, `driver_delete_forbidden`. **Keep these codes.**

---

## F1 — Workspace: `fetchWorkspace()` (`supabase_fleet_datasource.dart:61`)

Seven sequential reads, then everything is joined in Dart:

```
GET /rest/v1/drivers?select=*&office_id=eq.<office>&status=neq.archived&order=full_name.asc
GET /rest/v1/vehicles?select=*&office_id=eq.<office>&status=neq.archived&order=vehicle_code.asc
GET /rest/v1/assignments?select=*&office_id=eq.<office>&order=assigned_at.desc
GET /rest/v1/operation_trips?select=id,trip_code,status,trip_date,departure_time,vehicle_id,driver_id,operation_routes(name)
    &office_id=eq.&vehicle_id=not.is.null&status=in.(scheduled,open_for_booking,boarding,in_progress)
    &trip_date=gte.<today−1>&order=trip_date.asc,departure_time.asc                                   ← "duties"
GET /rest/v1/operation_trips?select=trip_code,status,trip_date,departure_time,driver_id,vehicle_id,operation_routes(name)
    &office_id=eq.&status=in.(completed,cancelled)&trip_date=gte.<today−365>&order=trip_date.desc,…   ← 12-month history
GET /rest/v1/driver_documents?select=*&driver_id=in.(<ids>)
GET /rest/v1/vehicle_documents?select=*&vehicle_id=in.(<ids>)
```

Dart derivations (`FleetWorkspace { drivers, vehicles, assignments, documents, duties }`):
* `currentVehicleId` / `currentDriverId` from the **active** assignment (`status='active'`).
* Per driver/vehicle: `tripHistory` (last 15 of the 12-month history), `completedTripsCount`,
  `cancelledTripsCount`; `vehicleHistory` / `previousDrivers` from **ended** assignments
  (`'من <assigned_at> إلى <ended_at>'`).
* Vehicle `licenseExpiry / insuranceExpiry / inspectionExpiry` = expiry of the first document of type
  `vehicle_license / insurance / inspection`.
* `duties` = active trips with a vehicle (window starts **yesterday** so an overnight `in_progress` bus still reads busy).

Columns read — `drivers`: `id, employee_code, full_name, phone, emergency_phone, address, national_id,
profile_image_url, license_number, license_expiry_date, hire_date, notes, status (active|suspended|archived),
rating, rating_count, created_at, updated_at`. `vehicles`: `id, vehicle_code, plate_number, vehicle_type,
brand, model, manufacture_year, color, capacity, seat_layout_type, image_url (comma-joined list!), notes,
status (active|maintenance|suspended|archived), seat_configuration (jsonb), rating, rating_count, created_at,
updated_at`. `assignments`: `id, driver_id, vehicle_id, office_id, status (active|ended), assigned_at,
ended_at, history (jsonb[])`. `*_documents`: `id, driver_id|vehicle_id, type, file_url, expiry_date,
status (valid|expiring_soon|expired)`.

**Proposed .NET:** `GET /api/v1/dashboard/fleet` returning the derived workspace (or four endpoints:
`/drivers`, `/vehicles`, `/assignments`, `/fleet/duties`) with the history counts computed server-side.

---

## F2 / F3 — Driver create/update (lines 383 / 411)

```
POST  /rest/v1/drivers            Prefer: return=representation
{ office_id, employee_code, full_name, phone, emergency_phone, address, national_id, profile_image_url,
  license_number, license_expiry_date, hire_date, notes, status, updated_at }
PATCH /rest/v1/drivers?id=eq.<id>  { same minus office_id }
```
Payload = `_onlyAllowed` whitelist (`_driverColumns`, line 27); **empty strings are dropped** except for
the clearable columns `image_url`, `profile_image_url`, `notes` (so clearing a note really clears it).
Then `_handleVehicleAssignmentChange(driverId, currentVehicleId)` (F10) if the form's vehicle differs from the
active assignment. Licensing: `max_drivers` (stock) trigger on insert → `quota_exceeded`.

## F4 — Driver status (line 435)

`PATCH drivers?id=eq. { status, updated_at }`; if `archived|suspended`, the datasource ends the active
assignment (F12). Server does the same anyway: trigger `end_assignments_on_fleet_status_change`
(`20260731090000_driver_vehicle_authority.sql:165`) ends every active assignment when a driver/vehicle leaves
`active`.

## F5 / F9 — Delete driver / vehicle (lines 467 / 572)

Client pre-check `GET operation_trips?select=id&<driver_id|vehicle_id>=eq.&office_id=eq.` → Arabic message
naming the count; then deletes `assignments`, `*_documents`, and the row. `BUSINESS RULE` trigger
`enforce_fleet_delete_guard` (`20260728090000_fleet_authority.sql:373`): `driver_delete_forbidden` /
`vehicle_delete_forbidden` when any `operation_trips` row references it — **archive, never erase**.
Storage files of the documents are **not** removed on delete.

## F6 / F7 — Vehicle create/update (lines 488 / 517)

```
POST /rest/v1/vehicles
{ office_id, vehicle_code, plate_number, vehicle_type, brand, model, manufacture_year, color, capacity,
  seat_layout_type, image_url: "<url1>,<url2>", notes, status,
  seat_configuration: { "rows": n, "columns": m,
                        "seats": [ { "seat_number": "1A", "seat_type": "passenger|driver|empty", "row": 1, "column": 1 } … ] },
  updated_at }
```
`BUSINESS RULE` CHECK constraints (`20260728090000_fleet_authority.sql:96-175`):
`vehicles_seat_configuration_wellformed` (non-empty, every slot has `seat_number` + numeric `row/column ≥ 1`,
passenger labels unique) and `vehicles_capacity_matches_seat_configuration`
(`capacity = count(seat_type='passenger')`). `vehicle_trip_seats(vehicle)` derives a trip's seat inventory
from this JSON (see `trips/` T3). `max_vehicles` stock meter on insert.

## F8 — Vehicle status (line 541)

`PATCH vehicles?id=eq. { status, updated_at }`; any non-`active` status ends the active assignment (client +
server trigger).

---

## F10 / F11 / F12 — Assignments (lines 619 / 652 / 692 / 886 / 912)

```
GET   /rest/v1/assignments?select=*&driver_id=eq.<d>&status=eq.active         (or vehicle_id=eq.)
PATCH /rest/v1/assignments?id=eq.<old>
{ "status":"ended", "ended_at":<iso>, "history": [...old, {title:'فك التعيين'|'تغيير المركبة', date:<yyyy-MM-dd>, description:'…'}], "updated_at" }
POST  /rest/v1/assignments      Prefer: return=representation
{ office_id, driver_id, vehicle_id, assigned_at:<iso>, status:'active',
  history: [ { title:'تم إنشاء التعيين', date:<today>, description:'تم ربط السائق بالمركبة بعد مراجعة الوثائق.' } ] }
```

`_handleVehicleAssignmentChange` (driver form) / `_handleDriverAssignmentChange` (vehicle form): no-op if
unchanged; ends the driver's active assignment; ends the target's active assignment (the other party);
inserts the new one. Up to 5 requests, **not transactional**.

`BUSINESS RULE` — trigger `enforce_assignment_integrity` (`20260731090000…:99`, before insert/update):
`driver_not_found`, `vehicle_not_found`, `assignment_cross_office` (driver, vehicle and assignment office
must match), `assignment_driver_unavailable` / `assignment_vehicle_unavailable` (an **active** assignment
needs both `active`). Partial unique indexes `uniq_active_assignment_per_driver` /
`uniq_active_assignment_per_vehicle` (`status='active'`). `driver_active_vehicle(driver)` (`SECURITY DEFINER`)
is the single resolver used by trip creation.

**Proposed .NET:** `POST /api/v1/dashboard/assignments { driverId, vehicleId }` doing end-old + insert in one
transaction; `DELETE /assignments/{id}` = end (soft). `history` becomes a proper event table or stays a JSON log.

---

## F13 — Documents (lines 740 / 777 / 817)

```
POST  /rest/v1/driver_documents | vehicle_documents
{ driver_id | vehicle_id, type, file_url, expiry_date:"yyyy-MM-dd", status:"valid|expiring_soon|expired" }
PATCH …?id=eq. { file_url, expiry_date, status, updated_at }
DELETE …?id=eq.
```
`type` wire names: `driver_license, national_id_front, national_id_back, criminal_record, employment_contract,
vehicle_license, insurance, inspection, other`. `status` is **computed client-side** from `expiry_date`
(expired / within 30 days / valid) and stored — a backend should derive it instead. After create/update the
datasource re-reads the owner's name (`GET drivers?select=full_name` / `GET vehicles?select=vehicle_code`).

## F14 — Storage (lines 831 / 850)

```
POST /storage/v1/object/documents/<drivers|vehicles>/<ownerId>/<type wireName>/<epoch ms>_<safe name>     (upsert)
POST /storage/v1/object/vehicle-images/vehicles/<vehicleId|new>/<epoch ms>_<i>_<safe name>               (upsert)
→ public URL  <base>/storage/v1/object/public/<bucket>/<path>
DELETE /storage/v1/object/<bucket>   { prefixes: [<path>] }
```
Buckets are **public-read**. `BUSINESS RULE` trigger `trg_quota_storage` on `storage.objects`
(`20260808090000_licensing_enforcement_completion.sql:722`): `max_storage_mb` stock quota per office prefix
→ `quota_exceeded` (the Storage API drops the `DETAIL`, so the code arrives without the numbers).
`profile_image_url` on drivers is written from the form but the current driver form does not upload photos.

**Proposed .NET:** `POST /api/v1/dashboard/files` (multipart; returns a backend-served URL, enforces size/type,
meters storage) and `DELETE /api/v1/dashboard/files?path=`. Private buckets + signed URLs is the recommendation.

---

## Notes for the .NET team

1. **One active assignment per driver and per vehicle** is the fleet invariant; trip creation depends on it.
   Enforce it with DB uniqueness, not application checks.
2. Status transitions of a driver/vehicle away from `active` **must** end the active assignment (trigger today).
3. Delete is allowed only for rows never referenced by a trip; the UI's "archive" is the normal retirement path.
4. `vehicles.seat_configuration` is the source of truth for a trip's seat map; `capacity` must equal the
   passenger-seat count (CHECK constraint). Hiace stays at 14 seats by product rule (`lib/core/vehicles`).
5. `image_url` is a comma-joined list of URLs in one text column — normalise it.
6. Writes are admin-only by RLS; reads are both roles (support agents see driver phone/national id today —
   a documented gap; the fix is a sanitised read model).
