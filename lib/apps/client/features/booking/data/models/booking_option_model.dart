import '../../domain/entities/booking_option.dart';

class RouteOptionModel {
  const RouteOptionModel({
    required this.id,
    required this.routeName,
    required this.pickup,
    required this.destination,
    required this.distance,
    required this.duration,
    required this.availableSeats,
    required this.startingPrice,
    required this.priceRange,
    required this.availableTrips,
    this.points = const [],
    this.isFastest = false,
    this.matchQuality = RouteMatchQuality.exact,
  });

  final String id;
  final String routeName;
  final String pickup;
  final String destination;
  final String distance;
  final String duration;
  final int availableSeats;
  final String startingPrice;
  final String priceRange;
  final List<RouteTripOptionModel> availableTrips;
  final List<RoutePointModel> points;
  final bool isFastest;
  final RouteMatchQuality matchQuality;

  RouteOptionData toEntity() {
    return RouteOptionData(
      id: id,
      routeName: routeName,
      pickup: pickup,
      destination: destination,
      distance: distance,
      duration: duration,
      availableSeats: availableSeats,
      startingPrice: startingPrice,
      priceRange: priceRange,
      availableTrips: availableTrips.map((trip) => trip.toEntity()).toList(),
      points: points.map((point) => point.toEntity()).toList(),
      isFastest: isFastest,
      matchQuality: matchQuality,
    );
  }
}

class RouteTripOptionModel {
  const RouteTripOptionModel({
    required this.id,
    required this.departureTime,
    required this.arrivalTime,
    required this.availableSeats,
    required this.vehicleType,
    required this.price,
    this.tripDate = '',
  });

  final String id;
  final String tripDate;
  final String departureTime;
  final String arrivalTime;
  final int availableSeats;
  final String vehicleType;
  final String price;

  RouteTripOptionData toEntity() {
    return RouteTripOptionData(
      id: id,
      tripDate: tripDate,
      departureTime: departureTime,
      arrivalTime: arrivalTime,
      availableSeats: availableSeats,
      vehicleType: vehicleType,
      price: price,
    );
  }
}

class RoutePointModel {
  const RoutePointModel({
    required this.name,
    required this.order,
    this.id = '',
    this.pickupAllowed = true,
    this.dropoffAllowed = true,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final int order;
  final bool pickupAllowed;
  final bool dropoffAllowed;
  final double? latitude;
  final double? longitude;

  RoutePointData toEntity() {
    return RoutePointData(
      id: id,
      name: name,
      order: order,
      pickupAllowed: pickupAllowed,
      dropoffAllowed: dropoffAllowed,
      latitude: latitude,
      longitude: longitude,
    );
  }
}

class PopularRouteListModel {
  const PopularRouteListModel({
    required this.id,
    required this.routeName,
    required this.dailyTrips,
    required this.averageDuration,
    required this.startingPrice,
    required this.pickup,
    required this.destination,
    required this.distance,
  });

  final String id;
  final String routeName;
  final int dailyTrips;
  final String averageDuration;
  final String startingPrice;
  final String pickup;
  final String destination;
  final String distance;

  PopularRouteListData toEntity() {
    return PopularRouteListData(
      id: id,
      routeName: routeName,
      dailyTrips: dailyTrips,
      averageDuration: averageDuration,
      startingPrice: startingPrice,
      pickup: pickup,
      destination: destination,
      distance: distance,
    );
  }
}

class AvailableTripModel {
  const AvailableTripModel({
    required this.vehicleType,
    required this.driverName,
    required this.estimatedArrival,
    required this.routeDuration,
    required this.availableSeats,
    required this.startingPrice,
    required this.vehicleId,
  });

  final String vehicleType;
  final String driverName;
  final String estimatedArrival;
  final String routeDuration;
  final int availableSeats;
  final String startingPrice;
  final String vehicleId;

  AvailableTripData toEntity() {
    return AvailableTripData(
      vehicleType: vehicleType,
      driverName: driverName,
      estimatedArrival: estimatedArrival,
      routeDuration: routeDuration,
      availableSeats: availableSeats,
      startingPrice: startingPrice,
      vehicleId: vehicleId,
    );
  }
}

class MapPinOptionModel {
  const MapPinOptionModel({
    required this.label,
    required this.subtitle,
    required this.x,
    required this.y,
  });

  final String label;
  final String subtitle;
  final double x;
  final double y;

  MapPinOption toEntity() {
    return MapPinOption(label: label, subtitle: subtitle, x: x, y: y);
  }
}
