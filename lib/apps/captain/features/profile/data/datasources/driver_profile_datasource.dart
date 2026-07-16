import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bmt_app/apps/captain/core/session/captain_driver_id_resolver.dart';

import '../../domain/entities/driver_profile.dart';

class DriverProfileDataSource {
  const DriverProfileDataSource(this._supabase);

  final SupabaseClient _supabase;

  Future<DriverProfile> getProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('المستخدم غير مسجّل الدخول');

    final driverId = await resolveCaptainDriverId(_supabase, user);
    if (driverId == null) {
      throw Exception(
        'لم يتم العثور على ملف السائق، حاول تسجيل الدخول مرة أخرى',
      );
    }

    final driverRow = await _supabase
        .from('drivers')
        .select()
        .eq('id', driverId)
        .single();
    final driver = Map<String, dynamic>.from(driverRow);

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

    // The captain's public average, maintained on `drivers` by the trip_reviews
    // trigger. They see the number, never the individual reviews behind it —
    // those belong to operations.
    final avgRating = (driver['rating'] as num?)?.toDouble() ?? 0;

    return DriverProfile(
      id: driverId,
      name: driver['full_name'] as String? ?? 'السائق',
      phone: driver['phone'] as String? ?? '',
      licenseNumber: driver['license_number'] as String?,
      photoUrl: driver['profile_image_url'] as String?,
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
