import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bmt_app/apps/client/core/utils/bookable_trip.dart';
import '../models/vehicle_detail_model.dart';
import 'vehicle_booking_datasource.dart';

class SupabaseVehicleBookingDatasource implements VehicleBookingDatasource {
  final SupabaseClient _supabase;

  const SupabaseVehicleBookingDatasource(this._supabase);

  @override
  Future<List<VehicleDetailModel>> getVehicles({String? routeId}) async {
    
    var query = _supabase
        .from('public_trips')
        .select('''
      *,
      operation_routes (*),
      trip_pricing (*),
      ${BookableTrip.seatsEmbed}
    ''')
        .eq('status', BookableTrip.status)
        .gte('trip_date', BookableTrip.today());

    if (routeId != null) {
      query = query.eq('route_id', routeId);
    }

    final response = await query;

    return response
        .where(_isBookableTrip)
        .map((data) => _mapToModel(data))
        .toList();
  }

  @override
  Future<VehicleDetailModel?> getVehicleById(String id) async {
    final response = await _supabase
        .from('public_trips')
        .select('''
      *,
      operation_routes (*),
      trip_pricing (*),
      ${BookableTrip.seatsEmbed}
    ''')
        .eq('id', id)
        .maybeSingle();

    if (response == null || !_isBookableTrip(response)) return null;

    return _mapToModel(response);
  }

  /// A vehicle is only listed when its trip can actually be sold *and* priced —
  /// this screen's whole content is a fare and a "book" button.
  bool _isBookableTrip(Map<String, dynamic> data) =>
      BookableTrip.isBookable(data) && _hasPositivePrice(data);

  bool _hasPositivePrice(Map<String, dynamic> data) {
    final ticketPrice = (data['ticket_price'] as num?)?.toDouble();
    if (ticketPrice != null && ticketPrice > 0) return true;

    final pricingRows = data['trip_pricing'];
    if (pricingRows is! List) return false;
    return pricingRows.any((row) {
      if (row is! Map<String, dynamic>) return false;
      final isActive = row['is_active'] as bool? ?? true;
      final amount = (row['one_time_price'] as num?)?.toDouble();
      return isActive && amount != null && amount > 0;
    });
  }

  VehicleDetailModel _mapToModel(Map<String, dynamic> data) {
    final vehicle = data['vehicles'] ?? {};
    final driver = data['drivers'] ?? {};
    final route = data['operation_routes'] ?? {};
    final pricingList = data['trip_pricing'] as List<dynamic>? ?? [];
    final pricing = pricingList.isNotEmpty ? pricingList.first : {};

    final features = List<String>.from(vehicle['features'] ?? []);
    final hasAc =
        features.contains('AC') || features.contains('Air Conditioning');
    final driverFullName = driver['full_name']?.toString() ?? 'Driver';
    final initials = driverFullName.isNotEmpty
        ? driverFullName[0].toUpperCase()
        : 'D';

    final capacity = vehicle['capacity'] as int? ?? 14;

    return VehicleDetailModel(
      id: data['id']?.toString() ?? '',
      name: vehicle['brand']?.toString() ?? 'Vehicle',
      model: vehicle['model']?.toString() ?? 'Unknown',
      vehicleType: vehicle['vehicle_type']?.toString() ?? 'Standard',
      imageLabels: const ['Exterior', 'Interior'],
      hasAirConditioning: hasAc,
      seatType: vehicle['seat_layout_type']?.toString() ?? 'Standard',
      driverName: driverFullName,
      price:
          '${data['currency'] ?? pricing['currency'] ?? 'EGP'} ${data['ticket_price'] ?? pricing['one_time_price'] ?? 0}',
      capacity: capacity,
      availableSeats: BookableTrip.seatsLeft(data),
      estimatedArrival: data['arrival_time']?.toString() ?? 'N/A',
      routeDuration: route['duration']?.toString() ?? 'N/A',
      departureTime: data['departure_time']?.toString() ?? 'N/A',
      driverInitials: initials,
      driverRating: (driver['rating'] as num?)?.toDouble() ?? 0,
      driverRatingCount: (driver['rating_count'] as num?)?.toInt() ?? 0,
      vehicleRating: (vehicle['rating'] as num?)?.toDouble() ?? 0,
      vehicleRatingCount: (vehicle['rating_count'] as num?)?.toInt() ?? 0,
    );
  }
}
