import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bmt_app/apps/captain/core/session/captain_driver_id_resolver.dart';

import '../../domain/entities/trip_history_item.dart';

class TripHistoryDataSource {
  const TripHistoryDataSource(this._supabase);

  final SupabaseClient _supabase;

  Future<List<TripHistoryItem>> getTripHistory() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return const [];

    final driverId = await resolveCaptainDriverId(_supabase, user);
    if (driverId == null) return const [];

    final response = await _supabase
        .from('operation_trips')
        .select('''
          id, trip_date, departure_time, arrival_time,
          operation_routes(name, start_city, end_city),
          vehicles(vehicle_code, plate_number),
          trip_passengers(id, status)
        ''')
        .eq('driver_id', driverId)
        .eq('status', 'completed')
        .order('trip_date', ascending: false)
        .order('departure_time', ascending: false);

    return (response as List).map(_mapRow).toList();
  }

  TripHistoryItem _mapRow(dynamic json) {
    final row = json as Map<String, dynamic>;
    final route = row['operation_routes'] as Map<String, dynamic>? ?? {};
    final vehicle = row['vehicles'] as Map<String, dynamic>? ?? {};
    final passengers = (row['trip_passengers'] as List?) ?? [];
    // scan_passenger_ticket writes 'confirmed' on check-in (see migration_07)
    // — trip_passengers.status has no 'boarded' value in its check
    // constraint. 'completed' is kept defensively; nothing currently writes
    // it, but it would mean the same thing if something one day did.
    final boarded = passengers.where((p) {
      final s = (p as Map<String, dynamic>)['status']?.toString();
      return s == 'confirmed' || s == 'completed';
    }).length;

    final dateStr = row['trip_date']?.toString() ?? '';
    final date = DateTime.tryParse(dateStr) ?? DateTime.now();

    return TripHistoryItem(
      id: row['id']?.toString() ?? '',
      route:
          route['name']?.toString() ??
          '${route['start_city'] ?? ''} → ${route['end_city'] ?? ''}',
      tripDate: date,
      departureTime: _parseTime(date, row['departure_time']),
      arrivalTime: _parseTime(date, row['arrival_time']),
      passengerCount: passengers.length,
      boardedCount: boarded,
      vehicleNumber: vehicle['vehicle_code']?.toString() ?? '',
      plateNumber: vehicle['plate_number']?.toString() ?? '',
    );
  }

  DateTime _parseTime(DateTime date, Object? time) {
    final parts = time?.toString().split(':') ?? [];
    final h = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
    final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(date.year, date.month, date.day, h, m);
  }
}
