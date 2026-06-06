class PackagePlan {
  const PackagePlan({
    required this.name,
    required this.durationLabel,
    required this.days,
    required this.tripsCount,
    required this.discountPercent,
    required this.startingPrice,
    required this.savingsAmount,
    required this.description,
  });

  final String name;
  final String durationLabel;
  final int days;
  final int tripsCount;
  final int discountPercent;
  final int startingPrice;
  final int savingsAmount;
  final String description;

  int get basePrice => startingPrice + savingsAmount;
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
