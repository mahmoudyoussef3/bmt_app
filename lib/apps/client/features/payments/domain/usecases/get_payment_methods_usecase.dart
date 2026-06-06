import '../entities/payment_models.dart';
import '../repositories/payment_repository.dart';

class GetPaymentMethodsUseCase {
  const GetPaymentMethodsUseCase(this._repository);

  final PaymentRepository _repository;

  Future<List<PaymentMethodData>> call() {
    return _repository.getPaymentMethods();
  }
}
