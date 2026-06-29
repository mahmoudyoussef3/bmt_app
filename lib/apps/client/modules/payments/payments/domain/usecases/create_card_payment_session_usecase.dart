import '../entities/payment_models.dart';
import '../repositories/payment_repository.dart';

class CreateCardPaymentSessionUseCase {
  const CreateCardPaymentSessionUseCase(this._repository);

  final PaymentRepository _repository;

  Future<CardPaymentSession> call({
    required PaymentCheckoutData checkoutData,
    required PaymentMethodData paymentMethod,
    required String bookingId,
    required int amount,
  }) {
    return _repository.createCardPaymentSession(
      checkoutData: checkoutData,
      paymentMethod: paymentMethod,
      bookingId: bookingId,
      amount: amount,
    );
  }
}
