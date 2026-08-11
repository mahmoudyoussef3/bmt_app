import 'trip.dart';

/// What a booking needs from the rider right now, resolved from all three state
/// axes at once ([TripStatus], [BookingState], [PaymentStatus]).
///
/// The three axes are independent and can disagree. Rendering them as one badge
/// — which the Client app used to do — hides exactly the cases a rider must act
/// on, and produces claims that are simply untrue: a `reserved` booking whose
/// receipt was rejected showed as "Upcoming", and a booking that never got past
/// `reserved` on a trip the operator marked `completed` showed as "Completed",
/// as though the rider had travelled.
///
/// This enum never replaces the individual statuses on screen. It sits beside
/// them and answers the one question a status badge cannot: *what happens next,
/// and is it my move?*
enum TripAttention {
  /// Nothing outstanding. The rider can ignore this booking until departure.
  none,

  /// Seat held, proof of payment sent, operator has not reviewed it yet.
  /// Waiting, not acting — but the rider must know the seat is not final.
  awaitingPaymentReview,

  /// A card booking whose payment never completed. The seat is held only until
  /// the hold expires; paying is the rider's move.
  paymentIncomplete,

  /// The operator rejected the payment. The rider's move: fix it or rebook.
  paymentRejected,

  /// The operator called the trip off after the money was taken. The rider is
  /// owed a refund and should be told so rather than shown a bare "Cancelled".
  refundDue,

  /// The axes contradict each other in a way no valid transition produces —
  /// most often a trip marked complete over a booking that was never confirmed.
  /// Surfaced honestly instead of being smoothed into a plausible-looking
  /// status, because the rider needs support, not a guess.
  needsSupport,
}

extension TripAttentionPolicy on TripData {
  /// Resolves this booking's outstanding action.
  ///
  /// Order matters: the terminal, money-bearing cases are checked before the
  /// in-flight ones, so a cancelled-but-paid booking reads as a refund rather
  /// than as a payment still under review.
  TripAttention get attention {
    if (bookingState == BookingState.cancelled) {
      
      if (paymentStatus == PaymentStatus.paid) return TripAttention.refundDue;
      return TripAttention.none;
    }

    if (bookingState == BookingState.completed ||
        status == TripStatus.completed) {
      
      if (bookingState == BookingState.reserved) {
        return TripAttention.needsSupport;
      }
      return TripAttention.none;
    }

    if (status == TripStatus.cancelled) {
      return paymentStatus == PaymentStatus.paid
          ? TripAttention.refundDue
          : TripAttention.none;
    }

    if (bookingState == BookingState.reserved) {
      return switch (paymentStatus) {
        PaymentStatus.failed => TripAttention.paymentRejected,
        PaymentStatus.underReview => TripAttention.awaitingPaymentReview,
        PaymentStatus.pending => TripAttention.paymentIncomplete,
        
        PaymentStatus.paid => TripAttention.needsSupport,
        PaymentStatus.refunded ||
        PaymentStatus.cancelled => TripAttention.needsSupport,
      };
    }

    if (paymentStatus == PaymentStatus.failed) {
      return TripAttention.paymentRejected;
    }
    return TripAttention.none;
  }

  /// Whether this booking is asking the rider to do something, as opposed to
  /// merely informing them. Drives whether the banner reads as an action.
  bool get needsRiderAction {
    return switch (attention) {
      TripAttention.paymentIncomplete ||
      TripAttention.paymentRejected ||
      TripAttention.needsSupport => true,
      TripAttention.none ||
      TripAttention.awaitingPaymentReview ||
      TripAttention.refundDue => false,
    };
  }
}
