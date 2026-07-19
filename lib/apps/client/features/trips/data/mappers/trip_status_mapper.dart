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
