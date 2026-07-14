import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_wizard_session.dart';
import 'package:bmt_app/apps/client/features/payments/domain/entities/payment_models.dart';

/// The wizard carries its own session object while the checkout widgets speak
/// [PaymentCheckoutData]. Mapping lives here alone, so the payment step and the
/// card-session call that follows it can never describe the same booking with
/// two different sets of numbers.
PaymentCheckoutData wizardCheckoutData(BookingWizardSession session) {
  final trip = session.selectedTrip;

  return PaymentCheckoutData(
    tripId: trip?.id ?? '',
    pickupPoint: session.pickupStop?.name ?? '',
    destination: session.dropoffStop?.name ?? '',
    vehicleNumber: trip?.vehicleType ?? '',
    tripDate: trip?.tripDate ?? '',
    departureTime: trip?.departureTime ?? '',
    arrivalTime: trip?.arrivalTime ?? '',
    selectedSeatId: session.selectedSeatId ?? '',
    selectedSeat: session.selectedSeatLabel ?? '',
    driverName: '',
    baseFare: session.totalPrice.round(),
  );
}

/// The id the booking RPCs store for each method.
///
/// A wallet maps to nothing: `confirm_seat_booking` settles a fare against a
/// gateway or a receipt and has no wallet leg, so the wizard filters wallets
/// out rather than offering a method it cannot honour.
String? wizardPaymentMethodId(PaymentMethodType type) => switch (type) {
  PaymentMethodType.creditCard => 'credit_card',
  PaymentMethodType.instapay => 'instapay',
  PaymentMethodType.vodafoneCash => 'vodafone_cash',
  PaymentMethodType.bankTransfer => 'bank_transfer',
  PaymentMethodType.walletBalance => null,
};

PaymentMethodType? wizardPaymentMethodType(String? id) => switch (id) {
  'credit_card' => PaymentMethodType.creditCard,
  'instapay' => PaymentMethodType.instapay,
  'vodafone_cash' => PaymentMethodType.vodafoneCash,
  'bank_transfer' => PaymentMethodType.bankTransfer,
  _ => null,
};

/// Everything that is not a card is settled by an operator reading a receipt.
bool wizardMethodRequiresReceipt(String? id) =>
    id != null && id != 'credit_card';

/// Why the rider cannot pay yet — null once they can.
///
/// Every reason the pay button could refuse is named here, so the bar can show
/// the reason before it is pressed rather than failing on tap.
String? wizardPaymentBlockedReason({
  required BookingWizardSession session,
  required PaymentCheckoutData data,
  required bool uploading,
}) {
  if (!data.isReadyForPayment) return 'Some booking details are missing.';
  if (session.paymentMethod == null) {
    return 'Choose a payment method to continue.';
  }
  if (uploading) return 'Your receipt is still uploading.';
  if (wizardMethodRequiresReceipt(session.paymentMethod) &&
      session.receiptUrl == null) {
    return 'Attach your transfer receipt to continue.';
  }
  return null;
}
