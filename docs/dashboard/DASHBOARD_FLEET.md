# Dashboard — Fleet

`/fleet` — «إدارة الأسطول». Owner only. Licensed on `drivers`. ~14.7k lines, the second
largest module.

---

## 1. Shape

A tab host over four sub-features, each with its own three layers and its own cubit:

| Tab | Sub-feature | Route (drill-in) |
|---|---|---|
| السائقون | `fleet_drivers` | `/drivers` |
| المركبات | `fleet_vehicles` | `/vehicles` |
| التعيينات | `fleet_assignments` | `/assignments` |
| الوثائق | `fleet_documents` | — |

`FleetOverviewCubit` loads one `FleetWorkspace` — drivers, vehicles, assignments,
documents and current duties — which is also what Home and نظرة تنفيذية read for their
capacity tiles. One source, so the counts agree.

---

## 2. The invariants the database owns

Fleet is the part of the schema where the DB, not the UI, is the authority
(`20260728090000_fleet_authority`, `20260731090000_driver_vehicle_authority`):

1. **One active vehicle per driver.** Enforced by trigger, not by a UI check.
2. **A trip takes a driver; the vehicle is derived** from that driver's active assignment
   and snapshotted onto the trip. Setting a mismatched pair directly is refused.
   The snapshot is why an August trip still shows the bus it actually ran with, even after
   the driver was reassigned in September.
3. **Seat layout is capacity.** A vehicle's capacity is the count of its persisted
   passenger seats — not a number typed alongside them. Switching vehicle type replaces
   the cabin rather than merging it.
4. **Creating a driver or vehicle is quota-gated** by `max_drivers` / `max_vehicles`.

The trigger scope is deliberately narrow: INSERT always, UPDATE only when `driver_id` or
`vehicle_id` actually changes. Without the is-distinct-from test, editing a departure time
would re-validate the pairing and fail on rows that were already fine.

---

## 3. Operational status vs record status

Every row carries two chips, and they answer different questions:

- **What is this bus *doing*?** — derived from `operation_trips`: idle, on a trip, or
  committed to an upcoming one.
- **What state is its *record* in?** — `vehicles.status`: active, maintenance, archived.

The filter bar splits along the same line. Conflating them is the most common bug in this
module's history.

---

## 4. Documents

Licences, permits and insurance with expiry dates, attachable to a driver or a vehicle.
Expiring documents are one of the inputs to the Home attention panel — which is the only
reason anybody looks at this tab before something has already expired.

---

## 5. Captain onboarding

Separate module, `/captain-requests`, licensed on `driver_app`:

```
Captain installs the app, enters the office join code (from ملف المكتب)
        │
        ▼
captain_requests row
        │
        ├─ owner approves ──▶ becomes a drivers row, captain gets a session
        └─ owner rejects
```

There is no SMS/OTP step. The join code plus the owner's approval *is* the authentication
model.

---

## 6. UI notes

- Cabin/seat grids stay **LTR** even in the RTL console: a bus's seat map is a physical
  object, and mirroring it would put row 1A on the wrong side of the aisle.
- Plate numbers and other digits normalise Arabic-Indic input — a plate typed as ٢٣٤ and a
  plate typed as 234 are the same bus.
- The seat renderer is shared (`core/widgets/vehicle_seats`) across dashboard, client and
  captain. It draws layout and state; it holds **no business rules**.
- Each tab uses `MasterDetailLayout`: list on one side, readiness inspector on the other.

---

## 7. Known gaps

- **Fleet RLS is role-agnostic.** `drivers`, `vehicles`, `assignments` and the document
  tables use `for all to authenticated using (office_id = current_office_id())` with no
  `office_role()` term, unlike wallet and office-profile policies. The client-side
  permission is currently the only thing keeping a support agent out of driver national
  IDs and licence numbers. Highest-priority open issue — see `DASHBOARD_SECURITY.md` §3.
- **No maintenance scheduling or service history.** Only document expiry.
- **No driver availability calendar.** Shifts, leave and rest periods are invisible, so
  the planner can assign a driver who is not actually working.
- **No utilisation trend.** How busy a bus was *this month vs last* is not answerable —
  `vehicles_efficiency_view` is a lifetime roll-up with no date dimension.
