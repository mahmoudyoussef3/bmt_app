import 'package:bmt_app/core/pricing/trip_stop_pair_price.dart';
import '../../domain/entities/transport_office.dart';

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
    this.office = TransportOffice.unknown,
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
  final TransportOffice office;

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
      office: office,
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
    this.stopPricing = const [],
    this.vehicle = const TripVehicleProfileModel(),
  });

  final String id;
  final String tripDate;
  final String departureTime;
  final String arrivalTime;
  final int availableSeats;
  final String vehicleType;
  final String price;
  final List<TripStopPairPrice> stopPricing;
  final TripVehicleProfileModel vehicle;

  RouteTripOptionData toEntity() {
    return RouteTripOptionData(
      id: id,
      tripDate: tripDate,
      departureTime: departureTime,
      arrivalTime: arrivalTime,
      availableSeats: availableSeats,
      vehicleType: vehicleType,
      price: price,
      stopPricing: stopPricing,
      vehicle: vehicle.toEntity(),
    );
  }
}

/// The joined `vehicles` / `drivers` rows for a trip.
class TripVehicleProfileModel {
  const TripVehicleProfileModel({
    this.brand = '',
    this.model = '',
    this.plateNumber = '',
    this.vehicleType = '',
    this.color = '',
    this.manufactureYear = 0,
    this.capacity = 0,
    this.seatLayoutType = '',
    this.features = const [],
    this.imageUrls = const [],
    this.vehicleRating = 0,
    this.vehicleRatingCount = 0,
    this.driverName = '',
    this.driverImageUrl = '',
    this.driverRating = 0,
    this.driverRatingCount = 0,
  });

  final String brand;
  final String model;
  final String plateNumber;
  final String vehicleType;
  final String color;
  final int manufactureYear;
  final int capacity;
  final String seatLayoutType;
  final List<String> features;
  final List<String> imageUrls;
  final double vehicleRating;
  final int vehicleRatingCount;
  final String driverName;
  final String driverImageUrl;
  final double driverRating;
  final int driverRatingCount;

  /// Reads the `vehicles` and `drivers` rows embedded in a trip select.
  ///
  /// `vehicles.image_url` holds the gallery as one comma-joined string — the
  /// shape the Dashboard's fleet form writes — so it is split back apart here.
  factory TripVehicleProfileModel.fromJson({
    Map<String, dynamic>? vehicle,
    Map<String, dynamic>? driver,
  }) {
    final vehicleJson = vehicle ?? const <String, dynamic>{};
    final driverJson = driver ?? const <String, dynamic>{};

    return TripVehicleProfileModel(
      brand: vehicleJson['brand']?.toString().trim() ?? '',
      model: vehicleJson['model']?.toString().trim() ?? '',
      plateNumber: vehicleJson['plate_number']?.toString().trim() ?? '',
      vehicleType: vehicleJson['vehicle_type']?.toString().trim() ?? '',
      color: vehicleJson['color']?.toString().trim() ?? '',
      manufactureYear: _toInt(vehicleJson['manufacture_year']),
      capacity: _toInt(vehicleJson['capacity']),
      seatLayoutType: vehicleJson['seat_layout_type']?.toString().trim() ?? '',
      features: _toStringList(vehicleJson['features']),
      imageUrls: _splitImageUrls(vehicleJson['image_url']),
      vehicleRating: _toDouble(vehicleJson['rating']),
      vehicleRatingCount: _toInt(vehicleJson['rating_count']),
      driverName: driverJson['full_name']?.toString().trim() ?? '',
      driverImageUrl: driverJson['profile_image_url']?.toString().trim() ?? '',
      driverRating: _toDouble(driverJson['rating']),
      driverRatingCount: _toInt(driverJson['rating_count']),
    );
  }

  static List<String> _splitImageUrls(Object? value) {
    final raw = value?.toString() ?? '';
    if (raw.trim().isEmpty) return const [];
    return raw
        .split(',')
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList();
  }

  static List<String> _toStringList(Object? value) {
    if (value is! List) return const [];
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static int _toInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  TripVehicleProfile toEntity() {
    return TripVehicleProfile(
      brand: brand,
      model: model,
      plateNumber: plateNumber,
      vehicleType: vehicleType,
      color: color,
      manufactureYear: manufactureYear,
      capacity: capacity,
      seatLayoutType: seatLayoutType,
      features: features,
      imageUrls: imageUrls,
      vehicleRating: vehicleRating,
      vehicleRatingCount: vehicleRatingCount,
      driverName: driverName,
      driverImageUrl: driverImageUrl,
      driverRating: driverRating,
      driverRatingCount: driverRatingCount,
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
    this.arrivalOffset = '',
    this.departureOffset = '',
  });

  final String id;
  final String name;
  final int order;
  final bool pickupAllowed;
  final bool dropoffAllowed;
  final double? latitude;
  final double? longitude;

  /// `route_stations.arrival_offset` / `departure_offset` — see
  /// [RoutePointData.arrivalOffset].
  final String arrivalOffset;
  final String departureOffset;

  RoutePointData toEntity() {
    return RoutePointData(
      id: id,
      name: name,
      order: order,
      pickupAllowed: pickupAllowed,
      dropoffAllowed: dropoffAllowed,
      latitude: latitude,
      longitude: longitude,
      arrivalOffset: arrivalOffset,
      departureOffset: departureOffset,
    );
  }
}

class PopularRouteListModel {
  const PopularRouteListModel({
    this.office = TransportOffice.unknown,
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
  final TransportOffice office;

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
      office: office,
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
