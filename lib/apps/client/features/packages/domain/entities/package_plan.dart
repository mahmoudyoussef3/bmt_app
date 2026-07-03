class PackagePlan {
  const PackagePlan({
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

  // Helper getters for compatibility
  String get name => nameAr;
  String get durationLabel => '$durationDays يوم';
  int get days => durationDays;
  int get tripsCount => rideCount;
  int get discountPercent => 0; 
  int get startingPrice => price.toInt();
  int get savingsAmount => 0;
  int get basePrice => price.toInt();
  String get description => '';
}

class PackageVehicleType {
  const PackageVehicleType({
    required this.name,
    required this.iconKey,
    required this.extraFee,
    required this.description,
  });

  final String name;
  final String iconKey;
  final int extraFee;
  final String description;
}

class PackageSelectionData {
  const PackageSelectionData({
    required this.packages,
    required this.routes,
    required this.pickupPoints,
    required this.destinations,
    required this.vehicles,
    required this.occupiedSeats,
  });

  final List<PackagePlan> packages;
  final List<String> routes;
  final List<String> pickupPoints;
  final List<String> destinations;
  final List<PackageVehicleType> vehicles;
  final Set<int> occupiedSeats;
}

class PackagePricing {
  const PackagePricing({
    required this.rawSubtotal,
    required this.discountValue,
    required this.finalPrice,
    required this.totalSavings,
  });

  final int rawSubtotal;
  final int discountValue;
  final int finalPrice;
  final int totalSavings;
}
