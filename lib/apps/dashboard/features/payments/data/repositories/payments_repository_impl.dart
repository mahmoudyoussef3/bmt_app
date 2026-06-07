import '../../domain/entities/finance_payment.dart';
import '../../domain/repositories/payments_repository.dart';
import '../datasources/mock_payments_datasource.dart';

class PaymentsRepositoryImpl implements PaymentsRepository {
  final PaymentsDatasource _datasource;

  const PaymentsRepositoryImpl(this._datasource);

  @override
  Future<FinancePayment> addNote(String paymentId, String note) async {
    try {
      return await _datasource.addNote(paymentId, note);
    } catch (_) {
      throw Exception('تعذر إضافة الملاحظة');
    }
  }

  @override
  Future<List<FinancePayment>> getPayments() async {
    try {
      return await _datasource.fetchPayments();
    } catch (_) {
      throw Exception('تعذر تحميل المدفوعات');
    }
  }

  @override
  Future<FinancePayment> updateStatus(
    String paymentId,
    PaymentReviewStatus status,
  ) async {
    try {
      return await _datasource.updateStatus(paymentId, status);
    } catch (_) {
      throw Exception('تعذر تحديث حالة الدفعة');
    }
  }
}
