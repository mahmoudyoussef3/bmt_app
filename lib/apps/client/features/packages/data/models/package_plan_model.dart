import '../../domain/entities/package_plan.dart';

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
      durationDays: json['duration_days'] as int? ?? 1,
      rideCount: json['ride_count'] as int? ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  PackagePlan toEntity() {
    return PackagePlan(
      id: id,
      nameAr: nameAr,
      nameEn: nameEn,
      packageType: packageType,
      durationDays: durationDays,
      rideCount: rideCount,
      price: price,
    );
  }
}

class PackageVehicleTypeModel {
  const PackageVehicleTypeModel({
    required this.name,
    required this.iconKey,
    required this.extraFee,
    required this.description,
  });

  final String name;
  final String iconKey;
  final int extraFee;
  final String description;

  PackageVehicleType toEntity() {
    return PackageVehicleType(
      name: name,
      iconKey: iconKey,
      extraFee: extraFee,
      description: description,
    );
  }
}

class PackageSelectionDataModel {
  const PackageSelectionDataModel({
    required this.packages,
    required this.routes,
    required this.pickupPoints,
    required this.destinations,
    required this.vehicles,
    required this.occupiedSeats,
  });

  final List<PackagePlanModel> packages;
  final List<String> routes;
  final List<String> pickupPoints;
  final List<String> destinations;
  final List<PackageVehicleTypeModel> vehicles;
  final Set<int> occupiedSeats;

  PackageSelectionData toEntity() {
    return PackageSelectionData(
      packages: packages.map((package) => package.toEntity()).toList(),
      routes: routes,
      pickupPoints: pickupPoints,
      destinations: destinations,
      vehicles: vehicles.map((vehicle) => vehicle.toEntity()).toList(),
      occupiedSeats: occupiedSeats,
    );
  }
}
