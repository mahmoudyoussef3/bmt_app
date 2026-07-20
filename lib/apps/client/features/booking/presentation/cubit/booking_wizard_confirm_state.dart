sealed class BookingWizardConfirmState {
  const BookingWizardConfirmState();
}

class BookingWizardConfirmIdle extends BookingWizardConfirmState {
  const BookingWizardConfirmIdle();
}

class BookingWizardConfirming extends BookingWizardConfirmState {
  const BookingWizardConfirming();
}

/// The booking row exists and the fare is owed to a gateway. The cubit cannot
/// push a webview, so it hands the checkout out and waits to be told how it
/// went.
class BookingWizardCardCheckout extends BookingWizardConfirmState {
  const BookingWizardCardCheckout({
    required this.checkoutUrl,
    required this.record,
  });

  final String checkoutUrl;
  final WizardBookingRecord record;
}

/// The rider is back from the gateway and the app is asking its own backend
/// whether the money actually moved. The redirect the webview came back on is
/// not evidence, so this state covers the wait for Paymob's signed callback.
class BookingWizardVerifyingPayment extends BookingWizardConfirmState {
  const BookingWizardVerifyingPayment();
}

class BookingWizardConfirmed extends BookingWizardConfirmState {
  const BookingWizardConfirmed({
    required this.record,
    required this.requiresVerification,
  });

  final WizardBookingRecord record;

  /// Manual transfers are settled by an operator reading a receipt, so the
  /// confirmation screen promises a check rather than a seat.
  final bool requiresVerification;
}

class BookingWizardConfirmFailed extends BookingWizardConfirmState {
  const BookingWizardConfirmFailed(this.reason);

  /// A backend code (`seat_unavailable`, `lock_expired`, …) or a raw message.
  /// The dialog turns it into something a rider can read.
  final String reason;
}

/// The booking row behind a confirm attempt, as the RPC reported it.
class WizardBookingRecord {
  const WizardBookingRecord({
    required this.id,
    required this.reference,
    required this.isNew,
  });

  factory WizardBookingRecord.fromRpc(
    Map<String, dynamic> booking, {
    required bool isNew,
  }) {
    final id = booking['booking_id']?.toString();
    // A booking is only ever shown by its number; an id prefix stands in until
    // the backend has one, so the rider always has something to quote.
    final reference =
        booking['booking_number']?.toString() ??
        (id != null && id.length >= 8
            ? id.substring(0, 8).toUpperCase()
            : null);
    return WizardBookingRecord(id: id, reference: reference, isNew: isNew);
  }

  final String? id;
  final String? reference;

  /// True when this attempt created the row. The wizard stores the ids of a new
  /// booking so a retry settles the same one instead of booking a second seat.
  final bool isNew;

  bool get isStorable => isNew && id != null && reference != null;
}
