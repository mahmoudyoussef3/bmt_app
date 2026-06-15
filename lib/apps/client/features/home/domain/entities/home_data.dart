class HomeData {
  const HomeData({
    required this.popularRoutes,
    required this.nearbyTrips,
    required this.packagePlans,
    required this.pickupSuggestions,
    required this.destinationSuggestions,
    required this.timeSuggestions,
    this.userName,
    this.currentTrip,
    this.activePackage,
  });

  final List<PopularRouteData> popularRoutes;
  final List<NearbyTripData> nearbyTrips;
  final List<PackagePlanData> packagePlans;
  final List<String> pickupSuggestions;
  final List<String> destinationSuggestions;
  final List<String> timeSuggestions;
  final String? userName;
  final HomeCurrentTripData? currentTrip;
  final HomeActivePackageData? activePackage;
}

class PopularRouteData {
  const PopularRouteData({
    required this.pickup,
    required this.destination,
    required this.duration,
    required this.startingPrice,
  });

  final String pickup;
  final String destination;
  final String duration;
  final String startingPrice;
}

class NearbyTripData {
  const NearbyTripData({
    required this.pickup,
    required this.destination,
    required this.departureTime,
    required this.seatsLeft,
    required this.isLive,
  });

  final String pickup;
  final String destination;
  final String departureTime;
  final int seatsLeft;
  final bool isLive;
}

class PackagePlanData {
  const PackagePlanData({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.badge,
    required this.iconKey,
  });

  final String title;
  final String subtitle;
  final String price;
  final String badge;
  final String iconKey;
}

class HomeCurrentTripData {
  const HomeCurrentTripData({
    required this.id,
    required this.pickup,
    required this.destination,
    required this.schedule,
    required this.statusLabel,
    this.driverLine,
  });

  final String id;
  final String pickup;
  final String destination;
  final String schedule;
  final String statusLabel;
  final String? driverLine;

  String get routeLabel => '$pickup → $destination';
}

class HomeActivePackageData {
  const HomeActivePackageData({
    required this.title,
    required this.expiryText,
    required this.remainingTrips,
    required this.totalTrips,
  });

  final String title;
  final String expiryText;
  final int remainingTrips;
  final int totalTrips;
}
