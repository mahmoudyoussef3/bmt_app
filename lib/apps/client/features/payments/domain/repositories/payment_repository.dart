import '../entities/payment_models.dart';

abstract class PaymentRepository {
  Future<List<PaymentMethodData>> getPaymentMethods();
}
