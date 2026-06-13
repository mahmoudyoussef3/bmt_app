import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/home_data.dart';

part 'home_data_model.g.dart';

@JsonSerializable()
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

  factory HomeDataModel.fromJson(Map<String, dynamic> json) => _$HomeDataModelFromJson(json);
  Map<String, dynamic> toJson() => _$HomeDataModelToJson(this);

  @JsonKey(name: 'popular_routes')
  final List<PopularRouteModel> popularRoutes;
  
  @JsonKey(name: 'nearby_trips')
  final List<NearbyTripModel> nearbyTrips;
  
  @JsonKey(name: 'package_plans')
  final List<PackagePlanModel> packagePlans;
  
  @JsonKey(name: 'pickup_suggestions')
  final List<String> pickupSuggestions;
  
  @JsonKey(name: 'destination_suggestions')
  final List<String> destinationSuggestions;
  
  @JsonKey(name: 'time_suggestions')
  final List<String> timeSuggestions;
  
  @JsonKey(name: 'current_trip')
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

@JsonSerializable()
class PopularRouteModel {
  const PopularRouteModel({
    required this.pickup,
    required this.destination,
    required this.duration,
    required this.startingPrice,
  });

  factory PopularRouteModel.fromJson(Map<String, dynamic> json) => _$PopularRouteModelFromJson(json);
  Map<String, dynamic> toJson() => _$PopularRouteModelToJson(this);

  final String pickup;
  final String destination;
  final String duration;
  @JsonKey(name: 'starting_price')
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

@JsonSerializable()
class NearbyTripModel {
  const NearbyTripModel({
    required this.pickup,
    required this.destination,
    required this.departureTime,
    required this.seatsLeft,
    required this.isLive,
  });

  factory NearbyTripModel.fromJson(Map<String, dynamic> json) => _$NearbyTripModelFromJson(json);
  Map<String, dynamic> toJson() => _$NearbyTripModelToJson(this);

  final String pickup;
  final String destination;
  @JsonKey(name: 'departure_time')
  final String departureTime;
  @JsonKey(name: 'seats_left')
  final int seatsLeft;
  @JsonKey(name: 'is_live')
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

@JsonSerializable()
class PackagePlanModel {
  const PackagePlanModel({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.badge,
    required this.iconKey,
  });

  factory PackagePlanModel.fromJson(Map<String, dynamic> json) => _$PackagePlanModelFromJson(json);
  Map<String, dynamic> toJson() => _$PackagePlanModelToJson(this);

  final String title;
  final String subtitle;
  final String price;
  final String badge;
  @JsonKey(name: 'icon_key')
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

@JsonSerializable()
class HomeCurrentTripModel {
  const HomeCurrentTripModel({
    required this.pickup,
    required this.destination,
    required this.schedule,
    required this.statusLabel,
    this.driverLine,
  });

  factory HomeCurrentTripModel.fromJson(Map<String, dynamic> json) => _$HomeCurrentTripModelFromJson(json);
  Map<String, dynamic> toJson() => _$HomeCurrentTripModelToJson(this);

  final String pickup;
  final String destination;
  final String schedule;
  @JsonKey(name: 'status_label')
  final String statusLabel;
  @JsonKey(name: 'driver_line')
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
