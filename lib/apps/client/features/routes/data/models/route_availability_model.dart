import 'package:bmt_app/apps/client/core/utils/bookable_trip.dart';

import '../../domain/entities/route_availability.dart';

/// Turns raw `public_trips` rows into the catalog's per-route booking outlook.
///
/// Lives in the data layer rather than the datasource so the rule — which
/// departure a card names, and when a corridor counts as sold out rather than
/// dead — can be tested without a Supabase client in the room.
class RouteAvailabilityModel extends RouteAvailability {
  const RouteAvailabilityModel({
    required super.status,
    super.nextDepartureDate,
    super.nextDepartureTime,
    super.seatsLeft,
    super.tripCount,
  });

  /// Every corridor's outlook, keyed by `route_id`.
  ///
  /// [rows] must arrive soonest-first — the query orders by `trip_date` then
  /// `departure_time`, and [fromTrips] reads that order as meaning "next".
  /// Rows that are not actually on sale are dropped through [BookableTrip], the
  /// app's single definition of a sellable departure, so this can never surface
  /// a trip the booking RPC would refuse.
  ///
  /// A route with no sellable row is simply absent: the caller distinguishes
  /// "nothing on sale" from "could not be read", and only it knows which
  /// happened.
  static Map<String, RouteAvailability> byRouteId(
    List<Map<String, dynamic>> rows,
  ) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final row in rows) {
      if (!BookableTrip.isOffered(row)) continue;
      final routeId = row['route_id']?.toString() ?? '';
      if (routeId.isEmpty) continue;
      grouped.putIfAbsent(routeId, () => []).add(row);
    }

    return {
      for (final entry in grouped.entries)
        entry.key: RouteAvailabilityModel.fromTrips(entry.value),
    };
  }

  /// One corridor's outlook from its sellable departures, soonest first.
  ///
  /// The departure named is the first one the rider could actually take, which
  /// is not always the first row: a full 6am bus followed by an open 9am bus is
  /// a corridor that departs at 9 as far as the card is concerned. Only when
  /// nothing has a seat does it name the soonest sold-out one instead — "fully
  /// booked" is more useful when it also says when the buses run.
  factory RouteAvailabilityModel.fromTrips(List<Map<String, dynamic>> trips) {
    if (trips.isEmpty) {
      return const RouteAvailabilityModel(status: RouteAvailabilityStatus.none);
    }

    final bookable = trips
        .where(BookableTrip.isBookable)
        .toList(growable: false);
    final soonest = bookable.isNotEmpty ? bookable.first : trips.first;

    return RouteAvailabilityModel(
      status: bookable.isEmpty
          ? RouteAvailabilityStatus.soldOut
          : RouteAvailabilityStatus.bookable,
      nextDepartureDate: soonest['trip_date']?.toString() ?? '',
      nextDepartureTime: soonest['departure_time']?.toString() ?? '',
      seatsLeft: bookable.isEmpty ? 0 : BookableTrip.seatsLeft(soonest),
      tripCount: bookable.length,
    );
  }
}
