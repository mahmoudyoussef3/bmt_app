import '../../domain/entities/booking_option.dart';

class RouteOptionModel {
  const RouteOptionModel({
    required this.id,
    required this.pickup,
    required this.destination,
    required this.duration,
    required this.availableSeats,
    required this.startingPrice,
    this.points = const [],
    this.isFastest = false,
  });

  final String id;
  final String pickup;
  final String destination;
  final String duration;
  final int availableSeats;
  final String startingPrice;
  final List<RoutePointModel> points;
  final bool isFastest;

  RouteOptionData toEntity() {
    return RouteOptionData(
      id: id,
      pickup: pickup,
      destination: destination,
      duration: duration,
      availableSeats: availableSeats,
      startingPrice: startingPrice,
      points: points.map((point) => point.toEntity()).toList(),
      isFastest: isFastest,
    );
  }
}

class RoutePointModel {
  const RoutePointModel({
    required this.name,
    required this.order,
    this.latitude,
    this.longitude,
  });

  final String name;
  final int order;
  final double? latitude;
  final double? longitude;

  RoutePointData toEntity() {
    return RoutePointData(
      name: name,
      order: order,
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
