import 'package:supabase_flutter/supabase_flutter.dart';
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

  Future<void> updatePassengerStatus({
    required String tripPassengerId,
    required PassengerBoardingStatus status,
  }) async {
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
