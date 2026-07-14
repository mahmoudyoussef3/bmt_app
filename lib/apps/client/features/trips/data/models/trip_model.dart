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
    required this.vehicleName,
    required this.vehicleType,
    required this.vehicleId,
    required this.seats,
    required this.paymentStatus,
    required this.fare,
    this.tripId = '',
    this.seatMap = const [],
    this.cancellationReason,
    this.completedAt,
  });

  final String id;
  final String tripId;
  final List<TripSeat> seatMap;
  final String reference;
  final TripStatus status;
  final String pickup;
  final String destination;
  final String dateLabel;
  final String timeLabel;
  final String driverName;
  final String driverPhone;
  final String driverInitials;
  final double driverRating;
  final int driverRatingCount;
  final String vehicleName;
  final String vehicleType;
  final String vehicleId;
  final List<String> seats;
  final PaymentStatus paymentStatus;
  final String fare;
  final String? cancellationReason;
  final String? completedAt;

  TripData toEntity() {
    return TripData(
      id: id,
      tripId: tripId,
      seatMap: seatMap,
      reference: reference,
      status: status,
      pickup: pickup,
      destination: destination,
      dateLabel: dateLabel,
      timeLabel: timeLabel,
      driverName: driverName,
      driverPhone: driverPhone,
      driverInitials: driverInitials,
      driverRating: driverRating,
      driverRatingCount: driverRatingCount,
      vehicleName: vehicleName,
      vehicleType: vehicleType,
      vehicleId: vehicleId,
      seats: seats,
      paymentStatus: paymentStatus,
      fare: fare,
      cancellationReason: cancellationReason,
      completedAt: completedAt,
    );
  }
}
