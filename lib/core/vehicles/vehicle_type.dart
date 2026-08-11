/// The vehicle types the fleet supports, and the one place a raw
/// `vehicles.vehicle_type` string is turned into a domain value.
///
/// Why this exists: the seat map a rider sees must match the physical vehicle
/// on the trip. The Owner Dashboard writes the type, the Client App reads it
/// back through `public_trips.vehicles`, and both must agree on what "Coaster"
/// means. Parsing it in two places is how they drift apart, so both apps parse
/// through [VehicleTypeParser.fromDatabase] and nothing else.
///
/// The column is free text (there is no DB enum), and it already holds
/// capitalised values like `'Hiace'` / `'Coaster'` / `'H1'`. [dbValue] keeps
/// writing exactly those strings so no data migration is needed, and parsing is
/// deliberately tolerant of what a human may have typed instead.
library;

enum VehicleType {
  /// Toyota Hiace — the 14-seat 3-across microbus the fleet started with.
  hiace('Hiace'),

  /// Toyota Coaster — the 28-seat 2+2 minibus.
  coaster('Coaster'),

  /// Mercedes Sprinter. No predefined seat blueprint yet; capacity is entered
  /// by the operator and the layout is derived from the seat data.
  sprinter('Sprinter'),

  /// Hyundai H1 van. Same as [sprinter] — operator-defined capacity.
  h1('H1'),

  /// Anything else, including rows written before this enum existed.
  other('Other');

  const VehicleType(this.dbValue);

  /// The exact string persisted to `vehicles.vehicle_type`.
  final String dbValue;

  /// Whether this type has a predefined seat blueprint (see
  /// `VehicleSeatLayouts`). Types without one keep the legacy behaviour: the
  /// operator types a capacity and a plain grid is generated.
  bool get hasPredefinedLayout =>
      this == VehicleType.hiace || this == VehicleType.coaster;
}

abstract final class VehicleTypeParser {
  /// Maps a raw `vehicle_type` value to a [VehicleType].
  ///
  /// Tolerant on purpose: the column is free text, so `'Hiace'`,
  /// `'hiace'`, `'Toyota Hiace'` and `'toyota-hiace'` all mean the same van.
  /// Anything unrecognised — including null and empty — falls back to
  /// [VehicleType.other] rather than guessing a layout that could be wrong.
  static VehicleType fromDatabase(String? raw) {
    final normalized = _normalize(raw);
    if (normalized.isEmpty) return VehicleType.other;

    for (final type in VehicleType.values) {
      if (normalized == _normalize(type.dbValue)) return type;
    }

    return switch (normalized) {
      'toyotahiace' || 'hiace' || 'هايس' => VehicleType.hiace,
      'toyotacoaster' || 'coaster' || 'كوستر' => VehicleType.coaster,
      'mercedessprinter' || 'sprinter' || 'سبرنتر' => VehicleType.sprinter,
      'hyundaih1' || 'h1' => VehicleType.h1,
      _ => VehicleType.other,
    };
  }

  static String _normalize(String? raw) =>
      (raw ?? '').toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '').trim();
}
