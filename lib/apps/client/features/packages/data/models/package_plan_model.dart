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
    this.officeId = '',
    this.officeName = '',
    this.officeLogoUrl,
    this.officeRating = 0,
    this.officeRatingsCount = 0,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final String packageType;
  final int durationDays;
  final int rideCount;
  final double price;

  /// Provider identity, embedded from the anon-safe `public_offices` view via
  /// the `office_id` foreign key. Absent when the seller is unlisted/paused —
  /// the view drops those — which the repository treats as "not for sale".
  final String officeId;
  final String officeName;
  final String? officeLogoUrl;
  final double officeRating;
  final int officeRatingsCount;

  factory PackagePlanModel.fromJson(Map<String, dynamic> json) {
    final office = json['office'] as Map<String, dynamic>?;
    return PackagePlanModel(
      id: json['id'] as String? ?? '',
      nameAr: json['name_ar'] as String? ?? '',
      nameEn: json['name_en'] as String? ?? '',
      packageType: json['package_type'] as String? ?? '',
      durationDays: (json['duration_days'] as num?)?.toInt() ?? 1,
      rideCount: (json['ride_count'] as num?)?.toInt() ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      officeId: office?['id']?.toString() ?? '',
      officeName: office?['name']?.toString() ?? '',
      officeLogoUrl: office?['logo_url'] as String?,
      officeRating: (office?['rating'] as num?)?.toDouble() ?? 0,
      officeRatingsCount: (office?['ratings_count'] as num?)?.toInt() ?? 0,
    );
  }
}
