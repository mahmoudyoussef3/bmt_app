import 'reviewable_trip.dart';
import 'trip_seat.dart';
import 'trip_status.dart';

export 'reviewable_trip.dart';
export 'trip_attention.dart';
export 'trip_policies.dart';
export 'trip_status.dart';

class TripData {
  const TripData({
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

  /// The transport office operating this trip — empty for rows that predate
  /// office attribution. On a marketplace the rider booked with an office,
  /// so their ticket history says which one.
  final String officeName;

  /// The `operation_trips` id (distinct from the booking [id]) — needed to
  /// resolve the trip's real seat layout.
  final String tripId;

  /// The vehicle's real seat layout for this trip, with the passenger's own
  /// seat flagged. Empty until details are loaded (list cards omit it).
  final List<TripSeat> seatMap;

  final String reference;

  /// Where the *journey* stands. Not the same question as [bookingState].
  final TripStatus status;

  /// Where the *rider's seat* stands. A trip can be open for booking while this
  /// rider's own booking is still unpaid, and a trip can complete over a booking
  /// that was never confirmed — so these two are read together, never merged.
  final BookingState bookingState;

  final String pickup;
  final String destination;
  final String dateLabel;
  final String timeLabel;
  final String driverName;
  final String driverPhone;
  final String driverInitials;

  /// The captain's public average, aggregated from every passenger review.
  final double driverRating;

  /// How many reviews that average is built from. Zero means "not rated yet" —
  /// a brand-new captain must not be shown as a 0.0-star one.
  final int driverRatingCount;

  /// The captain's photo, when the office uploaded one. Empty falls back to
  /// [driverInitials].
  final String driverPhotoUrl;

  bool get hasDriverRating => driverRatingCount > 0 && driverRating > 0;

  final String vehicleName;
  final String vehicleType;
  final String vehicleId;

  /// The plate on the outside of the bus — what a passenger matches against at
  /// the curb.
  final String vehiclePlate;

  /// The office's own fleet label ("bus 1"). Shown only when there is no plate
  /// on file, so the vehicle is never left without an identifier.
  final String vehicleCode;

  /// Photos of this bus, as uploaded against the fleet record.
  final List<String> vehicleImageUrls;

  /// How a passenger names this bus: its plate, else the fleet code, else
  /// nothing at all (never a placeholder dash — the presentation layer decides
  /// what a blank looks like).
  String get vehicleNumber =>
      vehiclePlate.trim().isNotEmpty ? vehiclePlate.trim() : vehicleCode.trim();

  bool get hasVehiclePhotos => vehicleImageUrls.isNotEmpty;
  final List<String> seats;
  final PaymentStatus paymentStatus;
  final String fare;
  final String? cancellationReason;
  final String? completedAt;

  /// True once this booking carries a stored review. A passenger rates a trip
  /// once, so a rated trip must stop asking to be rated.
  final bool isReviewed;

  /// The slice of this trip the review flow actually needs.
  ReviewableTrip get reviewable => ReviewableTrip(
    bookingId: id,
    isCompleted: status == TripStatus.completed,
    reference: reference,
    driverName: driverName,
    vehicleName: vehicleName,
    origin: pickup,
    destination: destination,
  );

  bool get hasSeatMap => seatMap.isNotEmpty;

  int get vehicleCapacity => seatMap.length;

  int get availableSeatCount =>
      seatMap.where((seat) => seat.isAvailable).length;

  /// The passenger's own seats — from the live layout when available, else the
  /// booking's seat labels (so the summary never goes blank).
  List<String> get mySeatLabels {
    final fromMap = seatMap
        .where((seat) => seat.isMine)
        .map((seat) => seat.displayLabel)
        .toList();
    if (fromMap.isNotEmpty) return fromMap;
    return seats.where((seat) => seat.trim().isNotEmpty).toList();
  }
}
