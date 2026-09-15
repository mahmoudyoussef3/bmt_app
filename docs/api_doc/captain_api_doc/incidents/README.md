# Captain · Incidents (SOS / incident report)

The captain raises the alarm; operations owns the record. One insert into `driver_trip_reports`,
always as `pending`; the dashboard's Live Ops queue acknowledges / resolves / dismisses it
(`../../dashboard_api_doc/live_ops/README.md` L4–L5). The captain can never edit or delete a filed report.

## Overview

| Layer | Files (relative to `lib/apps/captain/features/incidents/`) |
|---|---|
| Screen | `presentation/pages/report_incident_page.dart` (route `CaptainRoutes.reportIncident = /captain/trip/incident`, argument `ReportIncidentArgs {tripId, initialType}`); opened from Home quick actions (`home_quick_actions.dart:32`), the trip screen tools (`trip_execution_tools.dart:45`) and the SOS button (`trip_execution_sos_button.dart:57`, preselects `emergency`) |
| Cubit | `IncidentCubit` (`presentation/cubit/incident_cubit.dart` — `submit(report)` :12-20) |
| Use case | `ReportIncidentUseCase` |
| Repo | `data/repositories/incident_repository_impl.dart` |
| **Datasource** | `data/datasources/supabase_incident_datasource.dart` (interface `incident_datasource.dart`) |
| Model / entity | `data/models/incident_report_model.dart` → `domain/entities/incident_report.dart` (`IncidentReport {tripId, type, description}`, `IncidentType`) |

## Operations

| # | Operation | Today (Supabase) | Auth | Proposed .NET |
|---|---|---|---|---|
| I1 | Resolve own driver id | `GET drivers?select=id&user_id=eq.<uid>` | session (captain) | dropped — from the token |
| I2 | File the report | `POST driver_trip_reports` | session | `POST /api/v1/captain/trips/{tripId}/incidents` |

---

## I1 — `reportIncident()` first half (`supabase_incident_datasource.dart:14-23`)

```
GET /rest/v1/drivers?select=id&user_id=eq.<auth uid>      (.maybeSingle())
→ 200 { "id": "<driverId>" } | null
```
Null uid ⇒ *"المستخدم غير مسجّل الدخول"*; null row ⇒ *"لم يتم العثور على ملف السائق"*.
`RLS`: `drivers_self_read` (`user_id = auth.uid()`). Note this feature does **not** use
`CaptainIdentityProvider` like the others — it re-reads the driver row. Same answer, redundant call.

---

## I2 — Insert (`supabase_incident_datasource.dart:25-31`)

```
POST /rest/v1/driver_trip_reports
{ "trip_id":     "<uuid>",
  "driver_id":   "<driverId from I1>",
  "report_type": "passenger_issue" | "vehicle_issue" | "delay" | "emergency" | "route_blockage" | "other",
  "description": "<free text from the form>",
  "status":      "pending" }
→ 201 (no representation)
→ 4xx PostgrestException (raw message)   ← RLS refusal
```

Type mapping (`_typeToDb` :39-46): `IncidentType.passengerIssue → passenger_issue`, `vehicleIssue →
vehicle_issue`, `delay → delay`, `emergency → emergency`, `routeBlockage → route_blockage`, `other → other`.

**App reads:** nothing; success ⇒ `IncidentReady(submitted: true)` ⇒ confirmation + pop.

`RLS` `driver_trip_reports_captain_file` (`20260728120000_captain_authority.sql:59-72`): INSERT only when
`driver_id = current_driver_id()` **and** the trip's `driver_id = current_driver_id()` (a captain cannot
attach a report to someone else's trip) **and** `status = 'pending'`. Read: `driver_trip_reports_captain_read`
(own reports — the app never reads them today). **No captain UPDATE/DELETE policy** — a filed SOS
cannot be closed or erased by the person who filed it.

`BUSINESS RULE` — lifecycle (`20260727090000_live_ops_incident_lifecycle.sql:55-66`): `status ∈ {pending,
acknowledged, resolved, dismissed}` (check constraint); operators set `acknowledged_at/by`,
`resolved_at/by`, `resolution_note`. **No trigger** fires a notification or operational alert on insert —
the dashboard discovers new reports through its realtime subscription on the table
(`dashboard_live_ops_<officeId>` channel) and its poll. `NEEDS BACKEND DECISION`: push an
`operational_alerts` row / dashboard event on insert so an SOS is never missed.

Not gated on trip status: a captain may file against a completed trip (the UI only offers it from live
contexts and Home).

**Proposed .NET:** `POST /api/v1/captain/trips/{tripId}/incidents { reportType, description }` →
`201 { id, status: "pending", createdAt }`; `403 { code: not_your_trip }`; `422` on an unknown type.
Derive `driverId` from the token; consider `GET /api/v1/captain/incidents` (own reports) if the app
ever gains a history view.

## Data shape (`driver_trip_reports`)

`id, trip_id, driver_id, report_type, description, status, created_at, resolved_at, acknowledged_at,
acknowledged_by, resolved_by, resolution_note` (+ `updated_at`). Only the first five are written by the captain.

## Notes for the .NET team

1. Append-only for the captain; full lifecycle for the office — keep that asymmetry.
2. `emergency` is the SOS. Nothing on the server distinguishes it today (same table, same `pending`);
   if the port adds paging/on-call routing, key it on `report_type`.
3. The description is free text with no length limit server-side; the form enforces its own.
