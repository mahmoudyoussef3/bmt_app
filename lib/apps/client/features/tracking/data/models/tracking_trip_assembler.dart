import 'package:bmt_app/core/tracking/progress/arrival_events.dart';

import '../../domain/entities/tracking_trip.dart';
import 'tracking_crew_model.dart';
import 'tracking_point_model.dart';
import 'tracking_rider_model.dart';
import 'tracking_state_model.dart';
import 'tracking_stops_model.dart';

/// Composes the six reads behind one tracking session into a single
/// [TrackingTripData]. Every field is mapped from a row; nothing is invented.
abstract final class TrackingTripAssembler {
  static TrackingTripData assemble({
    required String tripId,
    required String bookingId,
    required List<Map<String, dynamic>> pointRows,
    required Map<String, dynamic>? tripRow,
    required Map<String, dynamic>? locationRow,
    required List<Map<String, dynamic>> eventRows,
    required Map<String, dynamic>? passengerRow,
    required bool hasReview,
  }) {
    final tripDate = tripRow?['trip_date']?.toString();
    final departureAt = TrackingStopsModel.combineDateAndTime(
      tripDate,
      tripRow?['departure_time']?.toString(),
    );
    final vehicleFix = TrackingPointModel.fromNullableRow(locationRow);

    // Sorted once, here: the stops and the rider's resolved indices must be
    // built against the same ordering or the rider's badges land on the
    // wrong stops.
    final ordered = [...pointRows]..sort(
      (a, b) => _order(a).compareTo(_order(b)),
    );

    return TrackingTripData(
      tripId: tripId,
      bookingId: bookingId,
      tripCode: tripRow?['trip_code']?.toString(),
      routeName: (tripRow?['route'] as Map<String, dynamic>?)?['name']
          ?.toString(),
      stops: TrackingStopsModel.fromRows(
        ordered,
        tripDate: tripDate,
        departureAt: departureAt,
      ),
      tripState: TrackingStateModel.resolve(
        tripStatus: tripRow?['status']?.toString(),
        latestEventTitle: eventRows.isEmpty
            ? null
            : eventRows.first['title']?.toString(),
        hasLiveLocation: vehicleFix != null,
      ),
      departureAt: departureAt,
      arrivalAt: TrackingStopsModel.combineDateAndTime(
        tripDate,
        tripRow?['arrival_time']?.toString(),
      ),
      arrivalEventCount: countStationArrivalEvents(
        eventRows.map((e) => e['title'] as String?),
      ),
      captain: TrackingCrewModel.captain(
        tripRow?['driver'] as Map<String, dynamic>?,
      ),
      vehicle: TrackingCrewModel.vehicle(
        tripRow?['vehicle'] as Map<String, dynamic>?,
      ),
      rider: TrackingRiderModel.fromRows(
        passengerRow: passengerRow,
        pointRows: ordered,
      ),
      vehicleFix: vehicleFix,
      hasReview: hasReview,
    );
  }

  static int _order(Map<String, dynamic> row) =>
      (row['point_order'] as num?)?.toInt() ?? 0;
}
