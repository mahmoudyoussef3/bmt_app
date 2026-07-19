import '../entities/payment_models.dart';
import 'create_card_payment_session_usecase.dart';
import 'get_payment_methods_usecase.dart';

/// Opens a gateway checkout for a booking that is already written.
///
/// The card method is looked up rather than assumed: the operator can retire it
/// from the Dashboard, and a rider who reaches the pay button after that must be
/// told the method is gone instead of being sent to a session that cannot be
/// created.
class StartCardCheckoutUseCase {
  const StartCardCheckoutUseCase({
    required GetPaymentMethodsUseCase getPaymentMethods,
    required CreateCardPaymentSessionUseCase createCardPaymentSession,
  }) : _getPaymentMethods = getPaymentMethods,
       _createCardPaymentSession = createCardPaymentSession;

  final GetPaymentMethodsUseCase _getPaymentMethods;
  final CreateCardPaymentSessionUseCase _createCardPaymentSession;

  /// Throws `card_payment_unavailable` when no card method is configured.
  Future<CardPaymentSession> call({
    required PaymentCheckoutData checkoutData,
    required String bookingId,
    required int amount,
  }) async {
    final cards = (await _getPaymentMethods()).where(
      (method) => method.type == PaymentMethodType.creditCard,
    );
    if (cards.isEmpty) throw Exception('card_payment_unavailable');

    return _createCardPaymentSession(
      checkoutData: checkoutData,
      paymentMethod: cards.first,
      bookingId: bookingId,
      amount: amount,
    );
  }
}
