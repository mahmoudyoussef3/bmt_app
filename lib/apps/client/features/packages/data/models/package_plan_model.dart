import '../../domain/entities/package_plan.dart';

class PackagePlanModel {
  const PackagePlanModel({
    required this.id,
    required this.name,
    required this.durationLabel,
    required this.days,
    required this.tripsCount,
    required this.discountPercent,
    required this.startingPrice,
    required this.savingsAmount,
    required this.description,
  });

  final String id;
  final String name;
  final String durationLabel;
  final int days;
  final int tripsCount;
  final int discountPercent;
  final int startingPrice;
  final int savingsAmount;
  final String description;

  PackagePlan toEntity() {
    return PackagePlan(
      id: id,
      name: name,
      durationLabel: durationLabel,
      days: days,
      tripsCount: tripsCount,
      discountPercent: discountPercent,
      startingPrice: startingPrice,
      savingsAmount: savingsAmount,
      description: description,
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
