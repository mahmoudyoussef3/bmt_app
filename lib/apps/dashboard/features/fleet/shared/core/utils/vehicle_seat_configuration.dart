import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_vehicle.dart';
import 'package:bmt_app/core/vehicles/vehicles.dart';

/// Decides a vehicle's capacity and seat configuration from its **type**.
///
/// Extracted from the vehicle form so the rule is testable on its own and so
/// the form never has to reason about seat geometry. The rule the whole feature
/// rests on: a vehicle type with a predefined cabin owns its capacity and its
/// seats outright — the operator picks Hiace or Coaster and everything else
/// follows, which is also what makes it impossible to save a Coaster carrying
/// leftover Hiace seats.
abstract final class VehicleSeatConfigurator {
  /// The Arabic label shown for each type in the vehicle form.
  static const Map<VehicleType, String> typeLabels = {
    VehicleType.coaster: 'Toyota Coaster - كوستر',
    VehicleType.hiace: 'Toyota Hiace - هايس',
    VehicleType.sprinter: 'Sprinter - سبرنتر',
    VehicleType.h1: 'H1 - فان',
    VehicleType.other: 'نوع آخر',
  };

  /// The fixed capacity of [type], or null when the operator enters it.
  static int? fixedCapacityFor(VehicleType type) =>
      VehicleSeatLayouts.capacityFor(type);

  /// The capacity to save: the type's own capacity when it has one, otherwise
  /// whatever the operator typed.
  static int capacityFor(VehicleType type, int enteredCapacity) =>
      fixedCapacityFor(type) ?? enteredCapacity;

  /// The seat configuration to save.
  ///
  /// For a type with a predefined cabin the configuration is regenerated from
  /// the blueprint every time — it is the same layout the Client App draws, and
  /// regenerating (rather than merging) is what guarantees a type switch leaves
  /// no seats behind from the previous type and creates no duplicates.
  ///
  /// For a type without one, the previous configuration is kept while the type
  /// and capacity are unchanged, exactly as before.
  static SeatConfiguration resolve({
    required VehicleType type,
    required int capacity,
    SeatConfiguration? existing,
    VehicleType? existingType,
  }) {
    final blueprint = SeatConfiguration.forVehicleType(type);
    if (blueprint != null) return blueprint;

    final unchanged =
        existing != null &&
        existing.seats.isNotEmpty &&
        existingType == type &&
        existing.seats.where((s) => s.seatType == 'passenger').length ==
            capacity;

    return unchanged ? existing : SeatConfiguration.generateDefault(capacity);
  }
}
