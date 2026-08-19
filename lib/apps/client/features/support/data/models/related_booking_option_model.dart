import '../../domain/entities/related_booking_option.dart';

class RelatedBookingOptionModel extends RelatedBookingOption {
  const RelatedBookingOptionModel({
    required super.bookingId,
    super.tripId,
    required super.route,
    super.tripDate,
    super.seat,
    super.officeId,
  });

  factory RelatedBookingOptionModel.fromJson(Map<String, dynamic> json) {
    return RelatedBookingOptionModel(
      bookingId: json['id'] as String,
      tripId: json['trip_id'] as String?,
      route: (json['route'] as String?) ?? '',
      tripDate: json['trip_date'] != null
          ? DateTime.tryParse(json['trip_date'] as String)
          : null,
      seat: (json['seat'] as String?) ?? '',
      officeId: json['office_id'] as String?,
    );
  }
}
