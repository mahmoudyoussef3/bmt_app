import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vehicle_detail_model.dart';
import 'vehicle_booking_datasource.dart';

class SupabaseVehicleBookingDatasource implements VehicleBookingDatasource {
  final SupabaseClient _supabase;

  const SupabaseVehicleBookingDatasource(this._supabase);

  @override
  Future<List<VehicleDetailModel>> getVehicles() async {
    final response = await _supabase.from('vehicles').select();

    return response.map((data) {
      return VehicleDetailModel(
        id: data['id']?.toString() ?? '',
        name: data['brand']?.toString() ?? 'Vehicle',
        model: data['model']?.toString() ?? 'Unknown',
        vehicleType: data['vehicle_type']?.toString() ?? 'Standard',
        imageLabels: const ['Exterior', 'Interior'],
        hasAirConditioning: true,
        seatType: data['seat_layout_type']?.toString() ?? 'Standard',
        hasRecliningSeats: true,
        legRoomRating: 4.5,
        vehicleCondition: 'Excellent',
        driverName: 'Driver',
        driverRating: 4.8,
        completedTrips: 150,
        yearsExperience: 5,
        price: 'EGP 85',
        availableSeats: data['capacity'] as int? ?? 14,
        estimatedArrival: '8:40 AM',
        routeDuration: '45 min',
      );
    }).toList();
  }

  @override
  Future<VehicleDetailModel?> getVehicleById(String id) async {
    final response = await _supabase
        .from('vehicles')
        .select()
        .eq('id', id)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;

    return VehicleDetailModel(
      id: response['id']?.toString() ?? '',
      name: response['brand']?.toString() ?? 'Vehicle',
      model: response['model']?.toString() ?? 'Unknown',
      vehicleType: response['vehicle_type']?.toString() ?? 'Standard',
      imageLabels: const ['Exterior', 'Interior'],
      hasAirConditioning: true,
      seatType: response['seat_layout_type']?.toString() ?? 'Standard',
      hasRecliningSeats: true,
      legRoomRating: 4.5,
      vehicleCondition: 'Excellent',
      driverName: 'Driver',
      driverRating: 4.8,
      completedTrips: 150,
      yearsExperience: 5,
      price: 'EGP 85',
      availableSeats: response['capacity'] as int? ?? 14,
      estimatedArrival: '8:40 AM',
      routeDuration: '45 min',
    );
  }
}
