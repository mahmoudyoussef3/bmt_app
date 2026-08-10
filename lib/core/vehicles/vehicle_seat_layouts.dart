/// The registry that turns a [VehicleType] into a cabin [SeatLayoutBlueprint].
///
/// This is the single source of truth the requirement hangs on: the Owner
/// Dashboard generates a vehicle's seat configuration from here, and the Client
/// App draws a trip's seat map from here. Adding a vehicle type means adding one
/// blueprint below — no branching in any widget, in either app.
library;

import 'seat_layout_blueprint.dart';
import 'vehicle_type.dart';

abstract final class VehicleSeatLayouts {
  /// Toyota Hiace — the physical cabin, not a grid of fourteen seats.
  ///
  /// ```
  ///                     FRONT
  ///        ┌─────────────────────────┐
  ///        │  [D] [D]    ·     [S]   │  front cabin
  ///        ├─────────────────────────┤  ← bulkhead
  ///        │  [S] [S]    ┊     [S]   │  row 1   2 + aisle + 1
  ///        │  [S] [S]    ┊     [S]   │  row 2   2 + aisle + 1
  ///        │  [S] [S]    ┊     [S]   │  row 3   2 + aisle + 1
  ///        │  [S][S][S][S]           │  row 4   a bench of 4, wall to wall
  ///        └─────────────────────────┘
  ///                      REAR
  /// ```
  ///
  /// Four columns in a fixed left-hand-drive coordinate system. Column 1 is the
  /// driver's side, **column 3 is the aisle** and column 4 is the right-hand
  /// window. One aisle column for the whole cabin is what makes the walkway a
  /// single continuous channel instead of a gap re-invented per row.
  ///
  /// The two things that make this a Hiace rather than a van-shaped table:
  ///
  /// * **The front cabin is a separate compartment.** Driver at column 1, the
  ///   crew position beside them at column 2, and one *bookable* passenger seat
  ///   by the right-hand door at column 4 — with the walk-through between them.
  ///   The renderer divides the vehicle here.
  /// * **The rear row is a bench, not a row of the grid.** Rows 1–3 seat three
  ///   across with a walkway; behind them the cabin runs out of aisle and fits
  ///   a fourth seat, so seats 11–14 sit flush against each other, wall to
  ///   wall, and are a little narrower than the seats in front of them. Every
  ///   slot in that row is a seat, which is how [SeatLayoutBlueprint.benchRows]
  ///   knows to spread it across the cabin rather than drop the last seat into
  ///   the aisle column as a stray single.
  ///
  /// Capacity is **14 passenger seats** — 1 up front, 3 + 3 + 3 in the body,
  /// 4 across the back — numbered 1..14 in reading order, at exactly the
  /// `(row, column)` coordinates every `Hiace`-typed row in production already
  /// carries. Nothing about this cabin asks the database to change.
  ///
  /// NOTE ON CAPACITY: an early seat-layout brief described the Hiace as "15
  /// total seats, 2 of them the driver area", i.e. 13 passenger seats. It is
  /// left at 14 deliberately, because 14 is what the system runs on. If the
  /// operator's Hiaces really are 13-seaters, this list is the single line to
  /// change (plus a data migration for the vehicles already saved), and nothing
  /// in the renderer moves.
  static final SeatLayoutBlueprint hiace = SeatLayoutBlueprint.parse(const [
    // Front cabin: driver, crew position, walk-through, front passenger.
    'D:A1 D:A2  .  S',
    'S    S     |  S',
    'S    S     |  S',
    'S    S     |  S',
    // The rear bench: four across, no walkway through it.
    'S    S     S  S',
  ]);

  /// Toyota Coaster — 30 seats, 2+2 across a centre aisle.
  ///
  /// ASSUMPTION (no Coaster spec exists in this repo or in the database — the
  /// one `Coaster`-typed row in production carries a placeholder 14-seat Hiace
  /// configuration): the standard 30-passenger intercity Coaster — one seat
  /// beside the front entrance, six 2+2 rows, and a flush five-seat rear bench.
  /// If the operator's Coasters are a different trim, this list is the only
  /// thing that has to change.
  static final SeatLayoutBlueprint coaster = SeatLayoutBlueprint.parse(const [
    'D:A1 .  |  ^  S',
    'S    S  |  S  S',
    'S    S  |  S  S',
    'S    S  |  S  S',
    'S    S  |  S  S',
    'S    S  |  S  S',
    'S    S  |  S  S',
    'S    S  S  S  S',
  ]);

  /// The blueprint for [type], or null when the type has no predefined cabin
  /// and its capacity is whatever the operator entered.
  static SeatLayoutBlueprint? blueprintFor(VehicleType type) => switch (type) {
    VehicleType.hiace => hiace,
    VehicleType.coaster => coaster,
    VehicleType.sprinter || VehicleType.h1 || VehicleType.other => null,
  };

  /// The fixed passenger capacity of [type], or null when the operator sets it.
  static int? capacityFor(VehicleType type) => blueprintFor(type)?.capacity;

  /// The seat rows to persist for a vehicle of [type], or null when the type
  /// has no predefined cabin.
  static List<SeatDefinition>? seatDefinitionsFor(VehicleType type) =>
      blueprintFor(type)?.seatDefinitions();

  /// Picks the blueprint to draw a real trip with.
  ///
  /// **A modelled vehicle keeps its cabin.** A Hiace is a Hiace whatever its
  /// seat configuration says; the physical layout of a vehicle is not something
  /// a row count gets a vote on. This used to fall back to a grid derived from
  /// the seat coordinates whenever the counts disagreed, which meant one stale
  /// `seat_configuration` could erase a vehicle's visual identity in every app
  /// at once — the rider saw a spreadsheet instead of the van they were about
  /// to board. A count mismatch is a data problem and is surfaced as one: the
  /// renderer leaves unfilled slots as bare cabin floor and lists any seats
  /// past the cabin's capacity below the vehicle, so the operator can see
  /// precisely what does not line up.
  ///
  /// The one case that still derives: **no seat data at all**. With nothing to
  /// place, drawing a full cabin would claim seats the trip does not have.
  static SeatLayoutBlueprint resolve({
    required VehicleType type,
    required List<({int row, int column})> seats,
  }) {
    final blueprint = blueprintFor(type);
    if (blueprint != null && seats.isNotEmpty) return blueprint;
    return SeatLayoutBlueprint.fromSeatGrid(seats);
  }

  /// [resolve] straight from a raw `vehicles.vehicle_type` string.
  static SeatLayoutBlueprint resolveRaw({
    required String? vehicleType,
    required List<({int row, int column})> seats,
  }) =>
      resolve(type: VehicleTypeParser.fromDatabase(vehicleType), seats: seats);
}
