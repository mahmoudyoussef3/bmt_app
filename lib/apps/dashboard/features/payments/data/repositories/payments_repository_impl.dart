import '../../domain/entities/finance_payment.dart';
import '../../domain/repositories/payments_repository.dart';
import '../datasources/payments_datasource.dart';

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

  @override
  Future<List<Map<String, dynamic>>> getAvailableTrips() async {
    try {
      return await _datasource.fetchAvailableTrips();
    } catch (_) {
      throw Exception('تعذر تحميل الرحلات');
    }
  }

  @override
  Future<void> reassignBooking(String bookingId, String newTripId) async {
    try {
      await _datasource.reassignBooking(bookingId, newTripId);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('trip_full')) {
        throw Exception('الرحلة المختارة ممتلئة');
      }
      if (msg.contains('same_trip')) {
        throw Exception('الحجز موجود بالفعل في هذه الرحلة');
      }
      throw Exception('تعذر تحويل الحجز');
    }
  }
}
