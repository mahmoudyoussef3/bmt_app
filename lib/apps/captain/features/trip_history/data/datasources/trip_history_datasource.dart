import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/trip_history_item.dart';

class TripHistoryDataSource {
  const TripHistoryDataSource(this._supabase);

  final SupabaseClient _supabase;

  Future<List<TripHistoryItem>> getTripHistory() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return const [];

    final driverId = await _resolveDriverId(user);
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

  Future<String?> _resolveDriverId(User user) async {
    final direct = await _supabase
        .from('drivers')
        .select('id')
        .eq('user_id', user.id)
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

  TripHistoryItem _mapRow(dynamic json) {
    final row = json as Map<String, dynamic>;
    final route = row['operation_routes'] as Map<String, dynamic>? ?? {};
    final vehicle = row['vehicles'] as Map<String, dynamic>? ?? {};
    final passengers = (row['trip_passengers'] as List?) ?? [];
    final boarded = passengers.where((p) {
      final s = (p as Map<String, dynamic>)['status']?.toString();
      return s == 'boarded' || s == 'completed';
    }).length;

    final dateStr = row['trip_date']?.toString() ?? '';
    final date = DateTime.tryParse(dateStr) ?? DateTime.now();

    return TripHistoryItem(
      id: row['id']?.toString() ?? '',
      route: route['name']?.toString() ??
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
