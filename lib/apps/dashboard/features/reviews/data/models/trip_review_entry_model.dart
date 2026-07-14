import '../../domain/entities/trip_review_entry.dart';

class TripReviewEntryModel {
  const TripReviewEntryModel(this._json);

  final Map<String, dynamic> _json;

  String _text(String key) => _json[key]?.toString().trim() ?? '';

  int _stars(String key) => (_json[key] as num?)?.toInt() ?? 0;

  TripReviewEntry toEntity() {
    return TripReviewEntry(
      id: _text('id'),
      bookingId: _text('booking_id'),
      // The snapshots are taken at submit time, so an archived driver or a
      // deleted route still reads correctly here. Fall back only if a review
      // predates the snapshot columns.
      bookingNumber: _fallback(_text('booking_number'), 'بدون رقم حجز'),
      clientName: _fallback(_text('client_name'), 'عميل'),
      driverName: _fallback(_text('driver_name'), 'سائق غير محدد'),
      vehicleName: _fallback(_text('vehicle_name'), 'مركبة غير محددة'),
      routeLabel: _fallback(_text('route_label'), 'مسار غير محدد'),
      driverId: _json['driver_id']?.toString(),
      driverRating: _stars('driver_rating'),
      vehicleRating: _stars('vehicle_rating'),
      routeRating: _stars('route_rating'),
      comment: _text('comment'),
      createdAt:
          DateTime.tryParse(_text('created_at'))?.toLocal() ?? DateTime.now(),
    );
  }

  String _fallback(String value, String placeholder) =>
      value.isEmpty ? placeholder : value;
}
