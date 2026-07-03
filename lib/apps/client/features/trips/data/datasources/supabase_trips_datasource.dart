import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/trip.dart';
import '../models/trip_model.dart';
import 'trips_datasource.dart';

class SupabaseTripsDatasource implements TripsDatasource {
  final SupabaseClient _supabase;

  const SupabaseTripsDatasource(this._supabase);

  TripStatus _mapStatus(String statusStr) {
    switch (statusStr.toLowerCase()) {
      case 'newrequest':
      case 'approved':
        return TripStatus.upcoming;
      case 'active':
        return TripStatus.inProgress;
      case 'completed':
        return TripStatus.completed;
      case 'rejected':
      case 'cancelled':
        return TripStatus.cancelled;
      default:
        return TripStatus.upcoming;
    }
  }

  PaymentStatus _mapPayment(String statusStr) {
    switch (statusStr.toLowerCase()) {
      case 'paid':
        return PaymentStatus.paid;
      case 'refunded':
        return PaymentStatus.refunded;
      default:
        return PaymentStatus.pending;
    }
  }

  String _reference(String id) {
    final clean = id.replaceAll('-', '');
    final take = clean.length >= 8 ? clean.substring(0, 8) : clean;
    return 'BMT-${take.toUpperCase()}';
  }

  String _initials(String? name) {
    final trimmed = (name ?? '').trim();
    if (trimmed.length >= 2) return trimmed.substring(0, 2).toUpperCase();
    if (trimmed.isNotEmpty) return trimmed.toUpperCase();
    return 'DP';
  }

  TripModel _mapBookingToTripModel(Map<String, dynamic> data) {
    final tripObj = data['operation_trips'] as Map<String, dynamic>?;
    final vehicleObj = tripObj?['vehicles'] as Map<String, dynamic>?;
    final driverObj = tripObj?['drivers'] as Map<String, dynamic>?;

    final routeParts = (data['route'] as String? ?? '').split(' - ');
    final pickup = routeParts.isNotEmpty ? routeParts[0] : 'Unknown';
    final destination = routeParts.length > 1 ? routeParts[1] : 'Unknown';

    final paymentDetails =
        data['payment_details'] as Map<String, dynamic>? ?? {};
    final fare = paymentDetails['amount']?.toString() ?? '85.00';
    final paymentStatusStr = paymentDetails['status']?.toString() ?? 'pending';

    return TripModel(
      id: data['id']?.toString() ?? '',
      reference: _reference(data['id']?.toString() ?? ''),
      status: _mapStatus(data['status']?.toString() ?? 'newRequest'),
      pickup: pickup,
      destination: destination,
      dateLabel: data['trip_date']?.toString() ?? '',
      timeLabel: data['trip_time']?.toString() ?? '',
      driverName: driverObj?['full_name']?.toString() ?? 'Driver Pending',
      driverPhone: driverObj?['phone']?.toString() ?? 'Not available',
      driverInitials: _initials(driverObj?['full_name']?.toString()),
      driverRating: driverObj?['rating'] != null
          ? (driverObj!['rating'] as num).toDouble()
          : 0.0,
      vehicleName: vehicleObj?['brand']?.toString() ?? 'Vehicle Pending',
      vehicleType: vehicleObj?['vehicle_type']?.toString() ?? 'Vehicle',
      vehicleId: vehicleObj?['id']?.toString() ?? '',
      seats: [data['seat']?.toString() ?? 'Seat Pending'],
      paymentStatus: _mapPayment(paymentStatusStr),
      fare: 'EGP $fare',
      cancellationReason: data['rejection_reason']?.toString(),
    );
  }

  @override
  Future<List<TripModel>> getTrips() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('operation_bookings')
        .select('''
          *,
          operation_trips (
            *,
            vehicles (*),
            drivers (*)
          )
        ''')
        .eq('client_id', user.id)
        .order('created_at', ascending: false);

    return response.map((e) => _mapBookingToTripModel(e)).toList();
  }

  @override
  Future<TripModel?> getTripById(String id) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('operation_bookings')
        .select('''
          *,
          operation_trips (
            *,
            vehicles (*),
            drivers (*)
          )
        ''')
        .eq('client_id', user.id)
        .eq('id', id)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;

    return _mapBookingToTripModel(response);
  }
}
