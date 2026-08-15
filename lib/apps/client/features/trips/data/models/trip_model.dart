import '../../domain/entities/trip.dart';
import '../../domain/entities/trip_seat.dart';

class TripModel {
  const TripModel({
    required this.id,
    required this.reference,
    required this.status,
    required this.pickup,
    required this.destination,
    required this.dateLabel,
    required this.timeLabel,
    required this.driverName,
    required this.driverPhone,
    required this.driverInitials,
    required this.driverRating,
    this.driverRatingCount = 0,
    this.driverPhotoUrl = '',
    required this.vehicleName,
    required this.vehicleType,
    required this.vehicleId,
    this.vehiclePlate = '',
    this.vehicleCode = '',
    this.vehicleImageUrls = const [],
    required this.seats,
    required this.paymentStatus,
    required this.fare,
    this.bookingState = BookingState.reserved,
    this.tripId = '',
    this.seatMap = const [],
    this.officeName = '',
    this.cancellationReason,
    this.completedAt,
    this.isReviewed = false,
  });

  final String id;
  final String tripId;
  final String officeName;
  final List<TripSeat> seatMap;
  final String reference;
  final TripStatus status;
  final BookingState bookingState;
  final String pickup;
  final String destination;
  final String dateLabel;
  final String timeLabel;
  final String driverName;
  final String driverPhone;
  final String driverInitials;
  final double driverRating;
  final int driverRatingCount;
  final String driverPhotoUrl;
  final String vehicleName;
  final String vehicleType;
  final String vehicleId;
  final String vehiclePlate;
  final String vehicleCode;
  final List<String> vehicleImageUrls;
  final List<String> seats;
  final PaymentStatus paymentStatus;
  final String fare;
  final String? cancellationReason;
  final String? completedAt;
  final bool isReviewed;

  TripData toEntity() {
    return TripData(
      id: id,
      tripId: tripId,
      seatMap: seatMap,
      reference: reference,
      status: status,
      bookingState: bookingState,
      pickup: pickup,
      destination: destination,
      dateLabel: dateLabel,
      timeLabel: timeLabel,
      driverName: driverName,
      driverPhone: driverPhone,
      driverInitials: driverInitials,
      driverRating: driverRating,
      driverRatingCount: driverRatingCount,
      driverPhotoUrl: driverPhotoUrl,
      vehicleName: vehicleName,
      vehicleType: vehicleType,
      vehicleId: vehicleId,
      vehiclePlate: vehiclePlate,
      vehicleCode: vehicleCode,
      vehicleImageUrls: vehicleImageUrls,
      seats: seats,
      paymentStatus: paymentStatus,
      fare: fare,
      officeName: officeName,
      cancellationReason: cancellationReason,
      completedAt: completedAt,
      isReviewed: isReviewed,
    );
  }
}
