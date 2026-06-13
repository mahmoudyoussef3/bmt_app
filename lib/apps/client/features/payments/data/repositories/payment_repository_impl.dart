import '../../domain/entities/payment_models.dart';
import '../../domain/repositories/payment_repository.dart';
import '../datasources/payment_datasource.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  const PaymentRepositoryImpl(this._datasource);

  final PaymentDatasource _datasource;

  @override
  Future<List<PaymentMethodData>> getPaymentMethods() {
    return _datasource.getPaymentMethods();
  }
}
