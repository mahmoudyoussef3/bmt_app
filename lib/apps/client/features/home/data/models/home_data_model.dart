import '../../domain/entities/home_data.dart';

class HomeDataModel {
  const HomeDataModel({
    required this.popularRoutes,
    required this.nearbyTrips,
    required this.packagePlans,
    required this.pickupSuggestions,
    required this.destinationSuggestions,
    required this.timeSuggestions,
    this.currentTrip,
  });

  final List<PopularRouteModel> popularRoutes;
  final List<NearbyTripModel> nearbyTrips;
  final List<PackagePlanModel> packagePlans;
  final List<String> pickupSuggestions;
  final List<String> destinationSuggestions;
  final List<String> timeSuggestions;
  final HomeCurrentTripModel? currentTrip;

  HomeData toEntity() {
    return HomeData(
      popularRoutes: popularRoutes.map((route) => route.toEntity()).toList(),
      nearbyTrips: nearbyTrips.map((trip) => trip.toEntity()).toList(),
      packagePlans: packagePlans.map((plan) => plan.toEntity()).toList(),
      pickupSuggestions: pickupSuggestions,
      destinationSuggestions: destinationSuggestions,
      timeSuggestions: timeSuggestions,
      currentTrip: currentTrip?.toEntity(),
    );
  }
}

class PopularRouteModel {
  const PopularRouteModel({
    required this.pickup,
    required this.destination,
    required this.duration,
    required this.startingPrice,
  });

  final String pickup;
  final String destination;
  final String duration;
  final String startingPrice;

  PopularRouteData toEntity() {
    return PopularRouteData(
      pickup: pickup,
      destination: destination,
      duration: duration,
      startingPrice: startingPrice,
    );
  }
}

class NearbyTripModel {
  const NearbyTripModel({
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

  NearbyTripData toEntity() {
    return NearbyTripData(
      pickup: pickup,
      destination: destination,
      departureTime: departureTime,
      seatsLeft: seatsLeft,
      isLive: isLive,
    );
  }
}

class PackagePlanModel {
  const PackagePlanModel({
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

  PackagePlanData toEntity() {
    return PackagePlanData(
      title: title,
      subtitle: subtitle,
      price: price,
      badge: badge,
      iconKey: iconKey,
    );
  }
}

class HomeCurrentTripModel {
  const HomeCurrentTripModel({
    required this.pickup,
    required this.destination,
    required this.schedule,
    required this.statusLabel,
    this.driverLine,
  });

  final String pickup;
  final String destination;
  final String schedule;
  final String statusLabel;
  final String? driverLine;

  HomeCurrentTripData toEntity() {
    return HomeCurrentTripData(
      pickup: pickup,
      destination: destination,
      schedule: schedule,
      statusLabel: statusLabel,
      driverLine: driverLine,
    );
  }
}
