// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_data_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeDataModel _$HomeDataModelFromJson(Map<String, dynamic> json) =>
    HomeDataModel(
      popularRoutes: (json['popular_routes'] as List<dynamic>)
          .map((e) => PopularRouteModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      nearbyTrips: (json['nearby_trips'] as List<dynamic>)
          .map((e) => NearbyTripModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      packagePlans: (json['package_plans'] as List<dynamic>)
          .map((e) => PackagePlanModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      pickupSuggestions: (json['pickup_suggestions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      destinationSuggestions: (json['destination_suggestions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      timeSuggestions: (json['time_suggestions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      userName: json['user_name'] as String?,
      currentTrip: json['current_trip'] == null
          ? null
          : HomeCurrentTripModel.fromJson(
              json['current_trip'] as Map<String, dynamic>,
            ),
      activePackage: json['active_package'] == null
          ? null
          : HomeActivePackageModel.fromJson(
              json['active_package'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$HomeDataModelToJson(HomeDataModel instance) =>
    <String, dynamic>{
      'popular_routes': instance.popularRoutes,
      'nearby_trips': instance.nearbyTrips,
      'package_plans': instance.packagePlans,
      'pickup_suggestions': instance.pickupSuggestions,
      'destination_suggestions': instance.destinationSuggestions,
      'time_suggestions': instance.timeSuggestions,
      'user_name': instance.userName,
      'current_trip': instance.currentTrip,
      'active_package': instance.activePackage,
    };

PopularRouteModel _$PopularRouteModelFromJson(Map<String, dynamic> json) =>
    PopularRouteModel(
      pickup: json['pickup'] as String,
      destination: json['destination'] as String,
      duration: json['duration'] as String,
      startingPrice: json['starting_price'] as String,
    );

Map<String, dynamic> _$PopularRouteModelToJson(PopularRouteModel instance) =>
    <String, dynamic>{
      'pickup': instance.pickup,
      'destination': instance.destination,
      'duration': instance.duration,
      'starting_price': instance.startingPrice,
    };

NearbyTripModel _$NearbyTripModelFromJson(Map<String, dynamic> json) =>
    NearbyTripModel(
      pickup: json['pickup'] as String,
      destination: json['destination'] as String,
      departureTime: json['departure_time'] as String,
      seatsLeft: (json['seats_left'] as num).toInt(),
      isLive: json['is_live'] as bool,
    );

Map<String, dynamic> _$NearbyTripModelToJson(NearbyTripModel instance) =>
    <String, dynamic>{
      'pickup': instance.pickup,
      'destination': instance.destination,
      'departure_time': instance.departureTime,
      'seats_left': instance.seatsLeft,
      'is_live': instance.isLive,
    };

PackagePlanModel _$PackagePlanModelFromJson(Map<String, dynamic> json) =>
    PackagePlanModel(
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      price: json['price'] as String,
      badge: json['badge'] as String,
      iconKey: json['icon_key'] as String,
    );

Map<String, dynamic> _$PackagePlanModelToJson(PackagePlanModel instance) =>
    <String, dynamic>{
      'title': instance.title,
      'subtitle': instance.subtitle,
      'price': instance.price,
      'badge': instance.badge,
      'icon_key': instance.iconKey,
    };

HomeCurrentTripModel _$HomeCurrentTripModelFromJson(
  Map<String, dynamic> json,
) => HomeCurrentTripModel(
  id: json['id'] as String,
  pickup: json['pickup'] as String,
  destination: json['destination'] as String,
  schedule: json['schedule'] as String,
  statusLabel: json['status_label'] as String,
  driverLine: json['driver_line'] as String?,
);

Map<String, dynamic> _$HomeCurrentTripModelToJson(
  HomeCurrentTripModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'pickup': instance.pickup,
  'destination': instance.destination,
  'schedule': instance.schedule,
  'status_label': instance.statusLabel,
  'driver_line': instance.driverLine,
};

HomeActivePackageModel _$HomeActivePackageModelFromJson(
  Map<String, dynamic> json,
) => HomeActivePackageModel(
  title: json['title'] as String,
  expiryText: json['expiryText'] as String,
  remainingTrips: (json['remainingTrips'] as num).toInt(),
  totalTrips: (json['totalTrips'] as num).toInt(),
);

Map<String, dynamic> _$HomeActivePackageModelToJson(
  HomeActivePackageModel instance,
) => <String, dynamic>{
  'title': instance.title,
  'expiryText': instance.expiryText,
  'remainingTrips': instance.remainingTrips,
  'totalTrips': instance.totalTrips,
};
