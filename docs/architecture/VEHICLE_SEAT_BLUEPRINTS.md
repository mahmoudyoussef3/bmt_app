# Vehicle seat blueprints — the physical cabins

The seat system is split in two, and the split is the whole design:

```
SeatLayoutBlueprint   WHERE a seat sits   — the physical vehicle   (core/vehicles)
VehicleSeatData       WHICH seat it is    — id, label, state       (core/widgets/vehicle_seats)
VehicleSeatLayout     the one renderer    — cabin, aisle, rows      (core/widgets/vehicle_seats)
```

A blueprint never carries a seat number that came from the database, and seat data never
carries a position. `VehicleSeatLayout` pours the seat list into the blueprint's seat slots
**in cabin reading order**: the seat at index `i` is drawn in the slot whose `seatNumber` is
`i + 1`. Every seat source in the codebase already sorts by `(row, column)`, and the database
snapshots `trip_seats` in that same order (`public.vehicle_trip_seats`), so the two agree
without either side knowing about the other.

---

## Toyota Hiace

```
                     FRONT
        ┌─────────────────────────┐
        │  [D] [D]    ·     [S]   │  front cabin
        ├─────────────────────────┤  ← bulkhead
        │  [S] [S]    ┊     [S]   │  row 1   2 + aisle + 1
        │  [S] [S]    ┊     [S]   │  row 2   2 + aisle + 1
        │  [S] [S]    ┊     [S]   │  row 3   2 + aisle + 1
        │  [S][S][S][S]           │  row 4   a bench of 4, wall to wall
        └─────────────────────────┘
                      REAR
```

Four columns in a fixed left-hand-drive coordinate system:

| column | what it is |
|---|---|
| 1 | driver's side wall — driver up front, kerbside window seats behind |
| 2 | inboard seat of the kerbside pair |
| 3 | **the aisle**, from the bulkhead to the rear bench |
| 4 | right-hand window — the front passenger, then a window seat each row |

Three facts define this cabin:

1. **The front cabin is a compartment.** Driver (column 1), crew position (column 2), and one
   *bookable* front passenger seat by the right-hand door (column 4), with the walk-through
   between them. `SeatLayoutBlueprint.frontCabinRows` reports it and the renderer draws it as
   its own floor, closed by a bulkhead.
2. **The aisle is one column, not a per-row gap.** `SeatLayoutBlueprint.aisleColumns` returns
   `{3}`, the renderer narrows that column to 0.58 of a seat width and draws a single lane from
   the bulkhead down to the bench.
3. **The rear row is a bench, not a row of the grid.** Behind row 3 the cabin runs out of aisle
   and fits a fourth seat across, so seats 11–14 sit flush against each other, wall to wall, and
   a little narrower than the seats in front of them. `SeatLayoutBlueprint.benchRows` derives
   this — a row with nothing but seats in it has nowhere to walk, and that is what a bench is —
   and the renderer spreads it across the floor width instead of dropping the fourth seat into
   the aisle column, where it would read as a stray single.

**Capacity: 14 passenger seats** (1 + 3 + 3 + 3 + 4), numbered 1..14 in reading order. This is
what every `Hiace`-typed row in production already carries.

## Toyota Coaster

30 seats, 2 + 2 across a centre aisle, one seat beside the front entrance and a flush five-seat
rear bench. The blueprint is unchanged. It gets the same treatment from the shared renderer for
free: its rear row is all seats, so it is a bench too and spans the cabin, and because bench
rows are excluded when deriving `aisleColumns` its centre column narrows into a proper walkway
as well.

---

## The renderer never falls back to a generic grid for a modelled vehicle

`VehicleSeatLayouts.resolve` used to derive a plain grid from the seat coordinates whenever a
blueprint's capacity did not equal the trip's seat count. That meant a single stale
`seat_configuration` erased a vehicle's visual identity in every app at once — the rider saw a
spreadsheet instead of the van they were about to board.

It no longer does. **A modelled vehicle keeps its cabin**, and a count mismatch is surfaced as
the data problem it is:

* fewer seats than slots → the unfilled slots stay bare cabin floor;
* more seats than slots → the extras are listed under the vehicle in the overflow section,
  never dropped.

The one case that still derives a grid is **no seat data at all**: with nothing to place,
drawing a full cabin would claim seats the trip does not have.

---

## Database: is a migration required?

**No — nothing at all.** This is a rendering change end to end.

`SeatConfiguration.forVehicleType(hiace)` emits exactly the same `(row, column)` coordinates it
always has, pinned by a test (`stores the coordinates production already carries`):

| seat label | row, column |
|---|---|
| 1 | (1, 4) |
| 2, 3, 4 | (2,1) (2,2) (2,4) |
| 5, 6, 7 | (3,1) (3,2) (3,4) |
| 8, 9, 10 | (4,1) (4,2) (4,4) |
| 11, 12, 13, 14 | (5,1) (5,2) (5,3) (5,4) |

Capacity (14), seat labels (`'1'`..`'14'`), `columns` (4) and `rows` (5) are all unchanged too.
Vehicles saved before and after this change are byte-identical, so there is nothing to
reconcile and nothing to back-fill.

The one thing that *would* demand a migration is a change to this table. If a future cabin
edit moves a seat's coordinate, it owes the operator a `public.vehicles.seat_configuration`
update — and **must still leave `trip_seats` alone**: a trip's seats are a snapshot taken when
it was created, and moving them would move seats under riders who already booked one.

---

## Visual verification

`test/core/widgets/vehicle_seats/hiace_visual_capture.dart` renders the cabin in each seat-state
case. It is deliberately not a `_test.dart`, so `flutter test` does not collect it:

```bash
flutter test test/core/widgets/vehicle_seats/hiace_visual_capture.dart --update-goldens
# then look at test/core/widgets/vehicle_seats/_captures/*.png
```

The PNGs are throwaway — regenerate and inspect them, don't commit them as goldens. Engine
version differences make committed pixel goldens a maintenance tax that buys nothing here; the
structural assertions in `vehicle_seat_layout_test.dart` are what guard the geometry.
