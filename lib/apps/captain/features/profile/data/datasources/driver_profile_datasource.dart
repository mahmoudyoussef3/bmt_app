import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/driver_profile.dart';

class DriverProfileDataSource {
  const DriverProfileDataSource(this._supabase);

  final SupabaseClient _supabase;

  Future<DriverProfile> getProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('المستخدم غير مسجّل الدخول');

    // Resolve driver record
    final driverRow = await _supabase
        .from('drivers')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    final String driverId;
    Map<String, dynamic> driver;

    if (driverRow != null) {
      driver = Map<String, dynamic>.from(driverRow);
      driverId = driver['id'] as String;
    } else {
      final phone = user.phone ?? '';
      final byPhone = await _supabase
          .from('drivers')
          .select()
          .eq('phone', phone)
          .maybeSingle();
      if (byPhone == null) throw Exception('لم يتم العثور على ملف السائق');
      driver = Map<String, dynamic>.from(byPhone);
      driverId = driver['id'] as String;
    }

    // Completed trips count + total passengers
    final completedTrips = await _supabase
        .from('operation_trips')
        .select('id, trip_passengers(id)')
        .eq('driver_id', driverId)
        .eq('status', 'completed');

    final totalTrips = (completedTrips as List).length;
    final totalPassengers = (completedTrips as List).fold<int>(
      0,
      (sum, t) => sum + ((t['trip_passengers'] as List?)?.length ?? 0),
    );

    // Most recent vehicle via latest trip
    final recentTrip = await _supabase
        .from('operation_trips')
        .select('vehicles(vehicle_code, plate_number, capacity, model)')
        .eq('driver_id', driverId)
        .order('trip_date', ascending: false)
        .limit(1)
        .maybeSingle();

    final vehicle = recentTrip != null
        ? recentTrip['vehicles'] as Map<String, dynamic>?
        : null;

    // Average rating (graceful — table may not exist)
    double avgRating = 0;
    try {
      final ratings = await _supabase
          .from('driver_ratings')
          .select('rating')
          .eq('driver_id', driverId);
      if ((ratings as List).isNotEmpty) {
        final sum = ratings.fold<double>(
            0, (acc, r) => acc + ((r['rating'] as num?)?.toDouble() ?? 0));
        avgRating = sum / ratings.length;
      }
    } catch (_) {}

    final name = driver['name'] as String? ??
        user.userMetadata?['full_name'] as String? ??
        user.userMetadata?['name'] as String? ??
        'السائق';

    return DriverProfile(
      id: driverId,
      name: name,
      phone: driver['phone'] as String? ?? user.phone ?? '',
      licenseNumber: driver['license_number'] as String?,
      photoUrl: driver['photo_url'] as String? ??
          user.userMetadata?['avatar_url'] as String?,
      averageRating: avgRating,
      totalTrips: totalTrips,
      totalPassengers: totalPassengers,
      vehicleCode: vehicle?['vehicle_code'] as String?,
      plateNumber: vehicle?['plate_number'] as String?,
      vehicleModel: vehicle?['model'] as String?,
      vehicleCapacity: (vehicle?['capacity'] as num?)?.toInt(),
    );
  }
}
