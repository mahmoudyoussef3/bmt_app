/// A commute package a rider can subscribe to, as published by the Dashboard.
class PackagePlan {
  const PackagePlan({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.packageType,
    required this.durationDays,
    required this.rideCount,
    required this.price,
    this.officeName = '',
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final String packageType;
  final int durationDays;
  final int rideCount;
  final double price;

  /// The office selling this package. Packages are per-office (offices compete
  /// on price), so a mixed catalogue must say whose offer each card is.
  final String officeName;

  /// The name to show riders: English when the Dashboard has set one, and the
  /// Arabic name otherwise — never a blank plan on a checkout screen.
  String get displayName => nameEn.trim().isEmpty ? nameAr : nameEn;

  /// Whole-pound price. The Dashboard publishes packages at pound precision,
  /// so the fractional part is always zero in practice.
  int get priceInPounds => price.round();

  /// What one ride inside the package costs — the figure that actually shows a
  /// rider the package is worth buying. Guards a malformed zero-ride package.
  int get pricePerRide =>
      rideCount <= 0 ? priceInPounds : priceInPounds ~/ rideCount;
}
