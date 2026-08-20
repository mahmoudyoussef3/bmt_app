/// One package a trip actually sells: its identity, its price on this trip,
/// and the operator's optional note about it.
///
/// This is the unit the trip planner's fare panel edits. An office is not
/// limited to its saved catalog — [packageId] is empty for a package the
/// operator invented for this trip, which is created in `transport_packages`
/// with `trip_id` set the moment the trip exists (see
/// `20260820100000_trip_scoped_packages.sql`) and is sold on that trip only.
/// A non-empty [packageId] is one of the office's catalog packages, added to
/// this trip as a template and priced for it.
///
/// [price] is the package **total**, never a per-ride figure — the same value
/// `trip_package_prices.price` holds and `confirm_seat_booking_v2` charges.
class TripPackageOffer {
  /// `transport_packages.id`, or empty for a package this trip must create.
  final String packageId;

  /// Arabic name, the one riders see. Editable only for a package created
  /// here; a catalog package keeps the name the catalog gave it.
  final String name;

  final int rideCount;
  final int durationDays;
  final double price;

  /// The operator's optional note for this package on this trip, shown to
  /// the rider under the package in the booking wizard. Stored on
  /// `trip_package_prices.note`, so it belongs to the trip, not to the
  /// package — the same catalog package can carry a different note on
  /// another trip.
  final String note;

  /// True when this package exists only for this trip (already created, or
  /// still to be created). Distinguishes it from a catalog package the
  /// operator merely priced here.
  final bool isTripScoped;

  const TripPackageOffer({
    required this.packageId,
    required this.name,
    required this.rideCount,
    required this.durationDays,
    required this.price,
    this.note = '',
    this.isTripScoped = false,
  });

  /// True once this offer is worth saving: it names something and prices it.
  bool get isSellable =>
      name.trim().isNotEmpty && price > 0 && rideCount > 0 && durationDays > 0;

  /// True when the package still has to be created before it can be priced.
  bool get needsCreating => packageId.trim().isEmpty;

  TripPackageOffer copyWith({String? packageId}) {
    return TripPackageOffer(
      packageId: packageId ?? this.packageId,
      name: name,
      rideCount: rideCount,
      durationDays: durationDays,
      price: price,
      note: note,
      isTripScoped: isTripScoped,
    );
  }
}
