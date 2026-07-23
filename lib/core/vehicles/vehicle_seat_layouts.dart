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
  /// Toyota Hiace — 14 seats, 3 across with a right-hand aisle.
  ///
  /// This reproduces the cabin the Client App has always drawn: the driver
  /// bench with a single seat beside it, three 2+1 rows, then a flush four-seat
  /// back row. Changing it would change every existing Hiace trip's seat map.
  static final SeatLayoutBlueprint hiace = SeatLayoutBlueprint.parse(const [
    'D:A1 D:A2  |  S',
    'S    S     |  S',
    'S    S     |  S',
    'S    S     |  S',
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
  static SeatLayoutBlueprint? blueprintFor(VehicleType type) =>
      switch (type) {
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
  /// A predefined blueprint is used **only when it fits the seat data**. A
  /// vehicle typed `Coaster` that still carries a 14-seat configuration would
  /// otherwise render as a 30-slot Coaster frame with sixteen holes in it — so
  /// in that case the layout is derived from the seat coordinates instead,
  /// which is always truthful even if it is plainer.
  static SeatLayoutBlueprint resolve({
    required VehicleType type,
    required List<({int row, int column})> seats,
  }) {
    final blueprint = blueprintFor(type);
    if (blueprint != null && blueprint.capacity == seats.length) {
      return blueprint;
    }
    return SeatLayoutBlueprint.fromSeatGrid(seats);
  }

  /// [resolve] straight from a raw `vehicles.vehicle_type` string.
  static SeatLayoutBlueprint resolveRaw({
    required String? vehicleType,
    required List<({int row, int column})> seats,
  }) => resolve(
    type: VehicleTypeParser.fromDatabase(vehicleType),
    seats: seats,
  );
}
