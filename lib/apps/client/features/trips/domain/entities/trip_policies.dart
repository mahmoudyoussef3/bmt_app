import 'trip.dart';

/// The business rules that decide which actions a trip offers the passenger.
/// Kept beside the data shape so [TripData] stays a plain record of fields.
extension TripPolicies on TripData {
  /// A booking may only be cancelled by the client while its payment is still
  /// waiting on the dashboard. Once the dashboard approves the payment the seat
  /// is paid for and final — cancelling then goes through support, not a
  /// self-service button. Mirrors `cancel_booking_by_client`, which enforces
  /// the same rule on the seat and the money.
  bool get canBeCancelled {
    if (status != TripStatus.upcoming) return false;
    // Read off the booking axis, not the journey one: `reserved` is precisely
    // the state `cancel_booking_by_client` still accepts. Gating on the trip's
    // status alone offered the button on bookings the RPC would refuse.
    if (bookingState != BookingState.reserved) return false;
    return paymentStatus == PaymentStatus.pending ||
        paymentStatus == PaymentStatus.underReview;
  }

  /// A completed or cancelled trip is a record of a journey, not a journey.
  bool get isFinished =>
      status == TripStatus.completed || status == TripStatus.cancelled;

  /// Calling or messaging the captain only makes sense while the journey is
  /// still ahead of the passenger or under way. Once it is finished there is no
  /// captain on duty for this booking to reach.
  bool get canContactDriver => !isFinished;

  /// The vehicle must stay untrackable until this booking's own payment is
  /// approved — a trip can be in progress for other passengers while this
  /// client's payment is still under review — and there is nothing left to
  /// follow on a map once the trip has ended.
  bool get canBeTracked =>
      status == TripStatus.inProgress &&
      paymentStatus == PaymentStatus.paid &&
      bookingState != BookingState.cancelled;

  /// Rating is offered on a completed trip the passenger has not rated yet —
  /// and actually travelled on. A booking that never left `reserved` did not
  /// put anyone on that vehicle, so it is not theirs to rate.
  bool get canBeReviewed =>
      status == TripStatus.completed &&
      !isReviewed &&
      (bookingState == BookingState.completed ||
          bookingState == BookingState.confirmed);
}
