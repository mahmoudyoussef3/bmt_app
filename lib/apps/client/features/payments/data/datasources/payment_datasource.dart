import '../../domain/entities/payment_models.dart';

abstract class PaymentDatasource {
  Future<List<PaymentMethodData>> getPaymentMethods();
}
