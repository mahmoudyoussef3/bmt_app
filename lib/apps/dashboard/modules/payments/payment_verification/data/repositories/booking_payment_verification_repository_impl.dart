import '../../domain/entities/booking_payment_verification.dart';
import '../../domain/repositories/booking_payment_verification_repository.dart';
import '../datasources/booking_payment_verification_datasource.dart';

class BookingPaymentVerificationRepositoryImpl
    implements BookingPaymentVerificationRepository {
  final BookingPaymentVerificationDatasource _datasource;

  const BookingPaymentVerificationRepositoryImpl(this._datasource);

  @override
  Future<BookingPaymentVerification> addNote(
    String verificationId,
    String note,
  ) async {
    try {
      return await _datasource.addNote(verificationId, note);
    } catch (_) {
      throw Exception('تعذر إضافة ملاحظة التحقق');
    }
  }

  @override
  Future<BookingPaymentVerification> approve(
    String verificationId,
    String note,
  ) async {
    try {
      return await _datasource.approve(verificationId, note);
    } catch (_) {
      throw Exception('تعذر قبول الدفع');
    }
  }

  @override
  Future<List<BookingPaymentVerification>> getQueue() async {
    try {
      return await _datasource.fetchQueue();
    } catch (_) {
      throw Exception('تعذر تحميل قائمة التحقق');
    }
  }

  @override
  Future<BookingPaymentVerification> reject(
    String verificationId,
    String note,
  ) async {
    try {
      return await _datasource.reject(verificationId, note);
    } catch (_) {
      throw Exception('تعذر رفض الدفع');
    }
  }

  @override
  Future<BookingPaymentVerification> requestReview(
    String verificationId,
    String note,
  ) async {
    try {
      return await _datasource.requestReview(verificationId, note);
    } catch (_) {
      throw Exception('تعذر طلب مراجعة إضافية');
    }
  }
}
