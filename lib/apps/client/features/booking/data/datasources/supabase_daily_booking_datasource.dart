import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bmt_app/apps/client/core/utils/bookable_trip.dart';
import '../../domain/entities/daily_booking_data.dart';
import 'daily_booking_datasource.dart';

class SupabaseDailyBookingDatasource implements DailyBookingDatasource {
  final SupabaseClient _supabase;

  const SupabaseDailyBookingDatasource(this._supabase);

  @override
  Future<DailyBookingData> getDailyBookingData() async {
    // `public_trips` carries sanitised `drivers` / `vehicles` jsonb columns in
    // its `*`, replacing the table embeds the base table used to serve.
    //
    // This screen sells same-day seats, so it asks for exactly what can be
    // sold: `open_for_booking`, not yet departed. A `boarding` bus has closed
    // its manifest and a yesterday-dated one has left.
    final tripsResponse = await _supabase
        .from('public_trips')
        .select('*, ${BookableTrip.seatsEmbed}')
        .eq('status', BookableTrip.status)
        .gte('trip_date', BookableTrip.today());

    final routesResponse = await _supabase
        .from('operation_routes')
        .select('start_city, end_city')
        .eq('status', 'active');

    final distinctPickups = routesResponse
        .map((e) => e['start_city'].toString())
        .toSet()
        .toList();
    final distinctDestinations = routesResponse
        .map((e) => e['end_city'].toString())
        .toSet()
        .toList();

    final vehicles = tripsResponse.map((data) {
      final vehicle = data['vehicles'] as Map<String, dynamic>?;
      final driver = data['drivers'] as Map<String, dynamic>?;
      final capacity =
          (data['capacity'] as num?)?.toInt() ??
          (vehicle?['capacity'] as num?)?.toInt() ??
          14;
      final seatsLeft = BookableTrip.seatsLeft(data);
      final taken = (capacity - seatsLeft).clamp(0, capacity);

      return DailyBookingVehicle(
        id: data['id']?.toString() ?? '',
        driver: driver?['full_name']?.toString() ?? 'Unknown Driver',
        time: data['departure_time']?.toString() ?? '',
        seatsLeft: seatsLeft,
        occupancy: capacity > 0 ? taken / capacity : 0,
      );
    }).toList();

    final distinctArrivalTimes =
        tripsResponse
            .map((t) => t['arrival_time']?.toString() ?? '')
            .where((t) => t.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return DailyBookingData(
      pickupPoints: distinctPickups.isNotEmpty ? distinctPickups : [],
      destinations: distinctDestinations.isNotEmpty ? distinctDestinations : [],
      arrivalTimes: distinctArrivalTimes,
      vehicles: vehicles,
    );
  }
}
