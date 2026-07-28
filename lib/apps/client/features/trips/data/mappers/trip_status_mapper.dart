import '../../domain/entities/trip.dart';

/// Translates the backend's raw status strings into the app's [TripStatus] and
/// [PaymentStatus] enums. DB-string knowledge lives here in the data layer so
/// the domain enums stay pure Dart.
abstract final class TripStatusMapper {
  /// A cancelled booking is cancelled regardless of the trip's own status —
  /// the booking status wins.
  static TripStatus tripStatus(String tripStatus, String bookingStatus) {
    if (bookingStatus == 'cancelled') return TripStatus.cancelled;

    switch (tripStatus.toLowerCase()) {
      case 'scheduled':
      case 'open_for_booking':
        return TripStatus.upcoming;
      case 'boarding':
      case 'in_progress':
        return TripStatus.inProgress;
      case 'completed':
        return TripStatus.completed;
      case 'cancelled':
        return TripStatus.cancelled;
      default:
        return TripStatus.upcoming;
    }
  }

  /// The rider's own booking row status, kept as its own axis.
  ///
  /// The vocabulary is the Dashboard's `BookingStatus`
  /// (`draft`, `reserved`, `confirmed`, `boarded`, `completed`, `cancelled`),
  /// folded onto the four states a passenger can act on. `boarded` maps to
  /// `confirmed`, not `completed`: a rider on the vehicle has a seat that is
  /// theirs, but has not finished the journey — that fact belongs to
  /// [TripStatus], not here.
  ///
  /// `reserved` is the default for anything unrecognised (including `draft`): a
  /// booking the app cannot classify has certainly not been confirmed, and
  /// treating an unknown value as confirmed would tell a rider their seat is
  /// theirs on no evidence.
  static BookingState bookingState(String status) {
    return switch (status.toLowerCase()) {
      'confirmed' || 'boarded' || 'approved' || 'paid' => BookingState.confirmed,
      'completed' => BookingState.completed,
      'cancelled' || 'canceled' || 'rejected' => BookingState.cancelled,
      _ => BookingState.reserved,
    };
  }

  static PaymentStatus paymentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'approved':
        return PaymentStatus.paid;
      case 'refunded':
        return PaymentStatus.refunded;
      case 'cancelled':
        return PaymentStatus.cancelled;
      case 'rejected':
      case 'failed':
        return PaymentStatus.failed;
      case 'underreview':
      case 'under_review':
      case 'submitted':
        return PaymentStatus.underReview;
      default:
        return PaymentStatus.pending;
    }
  }
}
