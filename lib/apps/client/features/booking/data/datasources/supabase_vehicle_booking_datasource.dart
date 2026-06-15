import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vehicle_detail_model.dart';
import 'vehicle_booking_datasource.dart';

class SupabaseVehicleBookingDatasource implements VehicleBookingDatasource {
  final SupabaseClient _supabase;

  const SupabaseVehicleBookingDatasource(this._supabase);

  @override
  Future<List<VehicleDetailModel>> getVehicles({String? routeId}) async {
    var query = _supabase.from('operation_trips').select('''
      *,
      vehicles (*),
      drivers (*),
      operation_routes (*),
      trip_pricing (*)
    ''').eq('status', 'active');

    if (routeId != null) {
      query = query.eq('route_id', routeId);
    }

    final response = await query;

    return response.map((data) => _mapToModel(data)).toList();
  }

  @override
  Future<VehicleDetailModel?> getVehicleById(String id) async {
    final response = await _supabase.from('operation_trips').select('''
      *,
      vehicles (*),
      drivers (*),
      operation_routes (*),
      trip_pricing (*)
    ''').eq('id', id).maybeSingle();

    if (response == null) return null;

    return _mapToModel(response);
  }

  VehicleDetailModel _mapToModel(Map<String, dynamic> data) {
    final vehicle = data['vehicles'] ?? {};
    final driver = data['drivers'] ?? {};
    final route = data['operation_routes'] ?? {};
    final pricingList = data['trip_pricing'] as List<dynamic>? ?? [];
    final pricing = pricingList.isNotEmpty ? pricingList.first : {};

    final features = List<String>.from(vehicle['features'] ?? []);
    final hasAc = features.contains('AC') || features.contains('Air Conditioning');
    final driverFullName = driver['full_name']?.toString() ?? 'Driver';
    final initials = driverFullName.isNotEmpty ? driverFullName[0].toUpperCase() : 'D';

    final capacity = vehicle['capacity'] as int? ?? 14;
    final passengerCount = data['passenger_count'] as int? ?? 0;

    return VehicleDetailModel(
      id: data['id']?.toString() ?? '',
      name: vehicle['brand']?.toString() ?? 'Vehicle',
      model: vehicle['model']?.toString() ?? 'Unknown',
      vehicleType: vehicle['vehicle_type']?.toString() ?? 'Standard',
      imageLabels: const ['Exterior', 'Interior'],
      hasAirConditioning: hasAc,
      seatType: vehicle['seat_layout_type']?.toString() ?? 'Standard',
      driverName: driverFullName,
      price: '${pricing['currency'] ?? 'EGP'} ${pricing['base_price'] ?? 50}',
      availableSeats: capacity - passengerCount,
      estimatedArrival: data['end_time']?.toString() ?? 'N/A',
      routeDuration: route['estimated_time']?.toString() ?? 'N/A',
      departureTime: data['start_time']?.toString() ?? 'N/A',
      driverInitials: initials,
    );
  }
}
