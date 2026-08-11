import '../../domain/entities/trip_seat.dart';
import '../models/trip_model.dart';
import 'trip_status_mapper.dart';

/// Assembles a raw `operation_bookings` row (with its embedded trip, vehicle,
/// driver and review) into a [TripModel]. Every field is mapped from a row;
/// nothing is invented.
abstract final class TripMapper {
  static TripModel fromBookingRow(
    Map<String, dynamic> data, {
    List<TripSeat> seatMap = const [],
  }) {
    final tripObj = data['operation_trips'] as Map<String, dynamic>?;
    final vehicleObj = tripObj?['vehicles'] as Map<String, dynamic>?;
    final driverObj = tripObj?['drivers'] as Map<String, dynamic>?;

    final routeRaw = data['route'] as String? ?? '';
    final routeParts = routeRaw.contains('→')
        ? routeRaw.split(RegExp(r'\s*→\s*'))
        : routeRaw.split(RegExp(r'\s+-\s+'));
    
    final pickup = routeParts.isNotEmpty ? routeParts[0] : '';
    final destination = routeParts.length > 1 ? routeParts[1] : '';

    final paymentDetails =
        data['payment_details'] as Map<String, dynamic>? ?? {};
    final fare =
        data['payment_amount']?.toString() ??
        paymentDetails['amount']?.toString() ??
        '0';
    final paymentStatusStr = paymentDetails['status']?.toString() ?? 'pending';
    final dbPaymentStatus =
        data['payment_status']?.toString() ?? paymentStatusStr;
    final id = data['id']?.toString() ?? '';
    final bookingStatus = data['status']?.toString() ?? 'draft';

    return TripModel(
      id: id,
      tripId: tripObj?['id']?.toString() ?? '',
      seatMap: seatMap,
      reference: data['booking_number']?.toString() ?? _reference(id),
      status: TripStatusMapper.tripStatus(
        tripObj?['status']?.toString() ?? 'scheduled',
        bookingStatus,
      ),
      bookingState: TripStatusMapper.bookingState(bookingStatus),
      pickup: pickup,
      destination: destination,
      dateLabel: data['trip_date']?.toString() ?? '',
      timeLabel: data['trip_time']?.toString() ?? '',
      
      driverName: driverObj?['full_name']?.toString() ?? '',
      driverPhone: driverObj?['phone']?.toString() ?? 'Not available',
      driverInitials: _initials(driverObj?['full_name']?.toString()),
      driverRating: (driverObj?['rating'] as num?)?.toDouble() ?? 0.0,
      driverRatingCount: (driverObj?['rating_count'] as num?)?.toInt() ?? 0,
      vehicleName: vehicleObj?['brand']?.toString() ?? '',
      vehicleType: vehicleObj?['vehicle_type']?.toString() ?? 'Vehicle',
      vehicleId: vehicleObj?['id']?.toString() ?? '',
      seats: _seats(data['seat']),
      paymentStatus: TripStatusMapper.paymentStatus(dbPaymentStatus),
      fare: 'EGP $fare',
      officeName:
          (tripObj?['office'] as Map<String, dynamic>?)?['name']?.toString() ??
          '',
      isReviewed: _hasReview(data['trip_reviews']),
      cancellationReason:
          data['cancellation_reason']?.toString() ??
          data['payment_rejection_reason']?.toString() ??
          data['rejection_reason']?.toString(),
    );
  }

  /// Wraps the booking's raw seat label, or an empty list when it isn't set
  /// yet — [TripData.mySeatLabels] already falls back to the live seat map,
  /// and the "seat pending" copy is resolved by the presentation layer.
  static List<String> _seats(Object? rawSeat) {
    final seat = rawSeat?.toString().trim();
    return seat == null || seat.isEmpty ? const [] : [seat];
  }

  static String _reference(String id) {
    final clean = id.replaceAll('-', '');
    final take = clean.length >= 8 ? clean.substring(0, 8) : clean;
    return 'BMT-${take.toUpperCase()}';
  }

  /// Whether the passenger already reviewed this booking. RLS shows them only
  /// their own review rows, so an embedded row existing at all means "rated".
  static bool _hasReview(Object? embedded) {
    if (embedded is Map) return embedded.isNotEmpty;
    if (embedded is List) return embedded.isNotEmpty;
    return false;
  }

  static String _initials(String? name) {
    final trimmed = (name ?? '').trim();
    if (trimmed.length >= 2) return trimmed.substring(0, 2).toUpperCase();
    if (trimmed.isNotEmpty) return trimmed.toUpperCase();
    return 'DP';
  }
}
