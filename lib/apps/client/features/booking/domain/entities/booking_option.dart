import 'package:bmt_app/core/pricing/trip_stop_pair_price.dart';
import 'transport_office.dart';

/// How closely a route matches the user's pickup/destination search.
enum RouteMatchQuality {
  /// Route serves both the requested pickup and destination, in order.
  exact,

  /// Route serves the pickup or destination, but not a perfect pairing.
  partial,

  /// Closest available route; does not directly match the search.
  suggested,
}

class RouteOptionData {
  const RouteOptionData({
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
  final List<RouteTripOptionData> availableTrips;
  final List<RoutePointData> points;
  final bool isFastest;
  final RouteMatchQuality matchQuality;

  /// Who operates this route. Carried on the route rather than looked up later so it
  /// travels with the object into the booking wizard, which seeds its whole session
  /// from this instance — the office context then survives the entire flow for free.
  final TransportOffice office;

  bool get isExactMatch => matchQuality == RouteMatchQuality.exact;
}

class RoutePointData {
  const RoutePointData({
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
}

class RouteTripOptionData {
  const RouteTripOptionData({
    required this.id,
    required this.departureTime,
    required this.arrivalTime,
    required this.availableSeats,
    required this.vehicleType,
    required this.price,
    this.tripDate = '',
    this.stopPricing = const [],
    this.vehicle = const TripVehicleProfile(),
  });

  final String id;
  final String tripDate;
  final String departureTime;
  final String arrivalTime;
  final int availableSeats;
  final String vehicleType;
  final String price;

  /// This trip's `trip_pricing` rows, one per stop pair — the source of
  /// truth for resolving the fare/package price for the rider's exact
  /// pickup -> dropoff selection (see [TripPricingResolver]).
  final List<TripStopPairPrice> stopPricing;

  /// The bus and captain this trip actually runs with. It travels with the
  /// trip so the rider can inspect it before committing, and so the ticket
  /// they pay on names the same vehicle and captain they were shown.
  final TripVehicleProfile vehicle;
}

/// The vehicle and captain assigned to a trip.
///
/// Riders decide with their eyes: a photo of the bus and the captain's name
/// does more to make a booking feel safe than any list of specs. Every field
/// is optional because the operator fills the fleet record in over time — a
/// missing photo must degrade to a placeholder, never to a blocked booking.
class TripVehicleProfile {
  const TripVehicleProfile({
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

  /// Photos of this exact bus, in the order the operator uploaded them.
  final List<String> imageUrls;

  final double vehicleRating;
  final int vehicleRatingCount;
  final String driverName;
  final String driverImageUrl;
  final double driverRating;
  final int driverRatingCount;

  bool get hasImages => imageUrls.isNotEmpty;

  /// A count of zero means nobody has reviewed this bus/captain yet — which is
  /// not the same as being rated badly, and must not render as zero stars.
  bool get hasVehicleRating => vehicleRatingCount > 0 && vehicleRating > 0;

  bool get hasDriverRating => driverRatingCount > 0 && driverRating > 0;

  /// What to call the bus on screen: brand and model when the fleet record has
  /// them, falling back through the plate to the generic type, so the label is
  /// never blank.
  String get displayName {
    final named = [brand.trim(), model.trim()].where((p) => p.isNotEmpty);
    if (named.isNotEmpty) return named.join(' ');
    if (plateNumber.trim().isNotEmpty) return plateNumber.trim();
    return vehicleType.trim();
  }

  bool get hasAirConditioning => features.any((feature) {
    final normalized = feature.toLowerCase();
    return normalized == 'ac' || normalized.contains('air condition');
  });

  /// Whether there is anything worth opening a details sheet for.
  bool get hasDetails =>
      hasImages ||
      displayName.isNotEmpty ||
      driverName.trim().isNotEmpty ||
      features.isNotEmpty;
}

class PopularRouteListData {
  const PopularRouteListData({
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

  /// The office operating this route — see [RouteOptionData.office].
  final TransportOffice office;
}

class MapPinOption {
  const MapPinOption({
    required this.label,
    required this.subtitle,
    required this.x,
    required this.y,
  });

  final String label;
  final String subtitle;
  final double x;
  final double y;
}
