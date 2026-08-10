/// The EWT vehicle seat system: one cabin renderer, one seat tile, one palette,
/// used by the Client App, the Owner Dashboard and anything added later.
///
/// ```
/// VehicleSeatLayout          the renderer — cabin, aisle, driver area, rows
///   ├── SeatLayoutBlueprint  WHERE seats sit      (core/vehicles, pure Dart)
///   ├── VehicleSeatData      WHAT each seat is    (id, label, SeatViewState)
///   ├── VehicleSeatPalette   HOW states look      (EWT blue, light + dark)
///   ├── VehicleSeat          one seat tile
///   └── VehicleSeatLegend    the key, when the parent asks for it
/// ```
///
/// Layout and state are separate on purpose: the same Hiace cabin renders a
/// rider's booking map and an operator's manifest without either side knowing
/// the other exists.
library;

export 'vehicle_seat.dart'
    show VehicleFixtureKind, VehicleSeat, VehicleSeatFixture;
export 'vehicle_seat_data.dart' show VehicleSeatData, VehicleSeatLabels;
export 'vehicle_seat_layout.dart'
    show SeatLayoutDensity, SeatLayoutMode, VehicleSeatLayout;
export 'vehicle_seat_legend.dart' show VehicleSeatLegend;
export 'vehicle_seat_palette.dart' show SeatTones, VehicleSeatPalette;
