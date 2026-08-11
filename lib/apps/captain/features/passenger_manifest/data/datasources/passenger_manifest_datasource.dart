import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bmt_app/apps/captain/features/station_progress/domain/entities/station_action_failure.dart';
import 'package:bmt_app/apps/captain/features/station_progress/domain/entities/station_passenger.dart';

import '../../domain/entities/passenger.dart';
import '../models/passenger_model.dart';

class PassengerManifestDataSource {
  const PassengerManifestDataSource(this._supabase);

  final SupabaseClient _supabase;

  Stream<void> watchPassengerUpdates(String tripId) {
    return _supabase
        .from('trip_passengers')
        .stream(primaryKey: ['id'])
        .eq('trip_id', tripId)
        .map((_) {});
  }

  Future<List<PassengerModel>> getTripPassengers(String tripId) async {
    final response = await _supabase
        .from('trip_passengers')
        .select()
        .eq('trip_id', tripId)
        .order('created_at', ascending: true);

    final pointsResponse = await _supabase
        .from('trip_route_points')
        .select('route_point_id, point_name, arrival_offset, departure_offset')
        .eq('trip_id', tripId);
    final pickupTimesByName = {
      for (final point in pointsResponse)
        (point['point_name']?.toString() ??
            ''): point['departure_offset']?.toString().isNotEmpty == true
            ? point['departure_offset'].toString()
            : point['arrival_offset']?.toString() ?? '',
    };

    return (response as List).map((e) {
      final statusString = e['status'] as String? ?? 'pending';
      PassengerBoardingStatus status;
      switch (statusString.toLowerCase()) {
        case 'confirmed':
        case 'boarded':
          status = PassengerBoardingStatus.boarded;
          break;
        case 'no_show':
        case 'absent':
          status = PassengerBoardingStatus.absent;
          break;
        case 'cancelled':
          status = PassengerBoardingStatus.cancelled;
          break;
        case 'reserved':
        default:
          status = PassengerBoardingStatus.pending;
      }

      return PassengerModel(
        id: e['id'] as String? ?? '',
        name: e['passenger_name'] as String? ?? 'Unknown',
        seat: e['seat_label'] as String? ?? '',
        pickupPoint: e['pickup_point_name'] as String? ?? '',
        destination: e['dropoff_point_name'] as String? ?? '',
        pickupTime:
            pickupTimesByName[e['pickup_point_name']?.toString() ?? ''] ?? '',
        phone: e['phone'] as String? ?? '',
        status: status,
      );
    }).toList();
  }

  /// Marking a rider boarded (or putting them back on the waiting list) is the
  /// captain's own observation and is a direct write.
  ///
  /// Marking them absent is not: it removes them from a station's boarding
  /// requirement, which is the one thing standing between a captain and driving
  /// off without a passenger who paid. It goes through
  /// `captain_resolve_no_show`, which demands a reason and stamps it with the
  /// captain's id — and the RLS policy on `trip_passengers` no longer admits
  /// `no_show` as a value the captain may write, so this is not a convention
  /// that could be sidestepped by an older build.
  Future<void> updatePassengerStatus({
    required String tripPassengerId,
    required PassengerBoardingStatus status,
    NoShowReason? noShowReason,
    String? note,
  }) async {
    if (status == PassengerBoardingStatus.absent) {
      final reason = noShowReason;
      if (reason == null) {
        throw const StationActionException(
          StationActionFailure.noShowNoteRequired,
        );
      }
      try {
        await _supabase.rpc(
          'captain_resolve_no_show',
          params: {
            'p_trip_passenger_id': tripPassengerId,
            'p_reason': reason.wireValue,
            'p_note': note,
          },
        );
      } on PostgrestException catch (error) {
        throw stationFailureFrom(error.message);
      }
      return;
    }

    await _supabase
        .from('trip_passengers')
        .update({'status': _statusToString(status)})
        .eq('id', tripPassengerId);
  }

  String _statusToString(PassengerBoardingStatus status) => switch (status) {
    PassengerBoardingStatus.boarded => 'confirmed',
    PassengerBoardingStatus.absent => 'no_show',
    PassengerBoardingStatus.pending => 'reserved',
    PassengerBoardingStatus.cancelled => 'cancelled',
  };
}
