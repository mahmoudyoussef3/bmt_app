import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/assigned_trip.dart';
import '../models/assigned_trip_model.dart';

class CaptainTripRemoteDataSource {
  CaptainTripRemoteDataSource(this._supabase);

  final SupabaseClient _supabase;
  String? _cachedDriverId;

  Stream<void> watchTripUpdates() {
    final driverId = _cachedDriverId;
    if (driverId == null) return const Stream.empty();
    return _supabase
        .from('operation_trips')
        .stream(primaryKey: ['id'])
        .eq('driver_id', driverId)
        .map((_) {});
  }

  Future<List<AssignedTripModel>> getAssignedTrips() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return const [];

    _cachedDriverId = await _resolveDriverId(user);
    final driverId = _cachedDriverId;
    if (driverId == null) return const [];

    final response = await _supabase
        .from('operation_trips')
        .select('''
          *,
          operation_routes(name, start_city, end_city),
          vehicles(vehicle_code, plate_number),
          trip_route_points(point_name, point_order),
          trip_passengers(id, status)
        ''')
        .eq('driver_id', driverId)
        .inFilter('status', [
          'scheduled',
          'open_for_booking',
          'boarding',
          'in_progress',
        ])
        .order('trip_date')
        .order('departure_time');

    return response.map<AssignedTripModel>(_mapTrip).toList();
  }

  Future<String?> _resolveDriverId(User user) async {
    final direct = await _supabase
        .from('drivers')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();
    if (direct != null) return direct['id'] as String?;

    final phone = user.phone;
    if (phone == null || phone.isEmpty) return null;
    final byPhone = await _supabase
        .from('drivers')
        .select('id')
        .eq('phone', phone)
        .maybeSingle();
    return byPhone?['id'] as String?;
  }

  AssignedTripModel _mapTrip(Map<String, dynamic> json) {
    final route = json['operation_routes'] as Map<String, dynamic>? ?? {};
    final vehicle = json['vehicles'] as Map<String, dynamic>? ?? {};
    final points =
        ((json['trip_route_points'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
          ..sort(
            (a, b) => ((a['point_order'] as int?) ?? 0).compareTo(
              (b['point_order'] as int?) ?? 0,
            ),
          );
    final passengers = (json['trip_passengers'] as List?) ?? const [];
    final boarded = passengers.where((p) {
      final status = (p as Map<String, dynamic>)['status']?.toString();
      return status == 'boarded' || status == 'completed';
    }).length;
    final tripDate = json['trip_date']?.toString() ?? '';

    return AssignedTripModel(
      id: json['id']?.toString() ?? '',
      route:
          route['name']?.toString() ??
          '${route['start_city'] ?? ''} → ${route['end_city'] ?? ''}',
      vehicleNumber: vehicle['vehicle_code']?.toString() ?? '',
      plateNumber: vehicle['plate_number']?.toString() ?? '',
      departureTime: _dateTime(tripDate, json['departure_time']),
      expectedArrivalTime: _dateTime(tripDate, json['arrival_time']),
      stops: points.map((p) => p['point_name']?.toString() ?? '').toList(),
      passengerCount: passengers.length,
      boardedCount: boarded,
      status: _status(json['status']?.toString()),
    );
  }

  DateTime _dateTime(String date, Object? time) {
    final parsedDate = DateTime.tryParse(date) ?? DateTime.now();
    final parts = time?.toString().split(':') ?? const [];
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(
      parsedDate.year,
      parsedDate.month,
      parsedDate.day,
      hour,
      minute,
    );
  }

  AssignedTripStatus _status(String? value) {
    return switch (value) {
      'boarding' => AssignedTripStatus.boarding,
      'in_progress' => AssignedTripStatus.inProgress,
      'completed' => AssignedTripStatus.completed,
      _ => AssignedTripStatus.scheduled,
    };
  }
}
