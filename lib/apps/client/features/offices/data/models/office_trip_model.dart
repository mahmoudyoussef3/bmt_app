import 'package:bmt_app/apps/client/core/utils/bookable_trip.dart';
import 'package:bmt_app/apps/client/core/utils/client_money.dart';

import '../../domain/entities/office_trip.dart';

class OfficeTripModel extends OfficeTrip {
  const OfficeTripModel({
    required super.id,
    required super.routeId,
    required super.routeName,
    required super.pickup,
    required super.destination,
    required super.tripDate,
    required super.departureTime,
    required super.duration,
    required super.price,
    required super.seatsLeft,
  });

  /// Reads a `public_trips` row with its `route` and `trip_seats` embeds.
  factory OfficeTripModel.fromJson(Map<String, dynamic> json) {
    final route = json['route'] as Map<String, dynamic>? ?? const {};
    final startCity = route['start_city']?.toString() ?? '';
    final endCity = route['end_city']?.toString() ?? '';
    final routeName = route['name']?.toString().trim() ?? '';

    return OfficeTripModel(
      id: json['id']?.toString() ?? '',
      routeId: json['route_id']?.toString() ?? route['id']?.toString() ?? '',
      // `origin - destination`, the naming this system already uses for a
      // route. See `UpcomingTripMapper` for why the arrow form cannot live in
      // the data layer.
      routeName: routeName.isNotEmpty ? routeName : '$startCity - $endCity',
      pickup: startCity,
      destination: endCity,
      tripDate: json['trip_date']?.toString() ?? '',
      departureTime: json['departure_time']?.toString() ?? '',
      duration: route['duration']?.toString() ?? '',
      price: tripFareLabel(json),
      seatsLeft: BookableTrip.seatsLeft(json),
    );
  }
}
