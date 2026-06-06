import '../../domain/entities/payment_models.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/mock_payment_datasource.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  const PaymentRepositoryImpl(this._datasource);

  final MockPaymentDatasource _datasource;

  @override
  Future<List<PaymentMethodData>> getPaymentMethods() {
    return _datasource.getPaymentMethods();
  }
}
