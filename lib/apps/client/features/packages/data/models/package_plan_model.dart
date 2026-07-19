/// Wire shape of a row in the `transport_packages` table.
///
/// Every field is defensive: the Dashboard can publish a partially filled
/// package, and a rider-facing catalogue must not crash on one bad row.
class PackagePlanModel {
  const PackagePlanModel({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.packageType,
    required this.durationDays,
    required this.rideCount,
    required this.price,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final String packageType;
  final int durationDays;
  final int rideCount;
  final double price;

  factory PackagePlanModel.fromJson(Map<String, dynamic> json) {
    return PackagePlanModel(
      id: json['id'] as String? ?? '',
      nameAr: json['name_ar'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      packageType: json['package_type'] as String? ?? '',
      durationDays: (json['duration_days'] as num?)?.toInt() ?? 1,
      rideCount: (json['ride_count'] as num?)?.toInt() ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
