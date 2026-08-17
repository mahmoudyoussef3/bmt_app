import '../../domain/entities/operation_booking.dart';
import '../../domain/entities/reassignment_target.dart';
import '../../domain/repositories/bookings_repository.dart';
import '../datasources/bookings_datasource.dart';

class BookingsRepositoryImpl implements BookingsRepository {
  final BookingsDatasource _datasource;

  const BookingsRepositoryImpl(this._datasource);

  @override
  Future<List<OperationBooking>> getBookings() {
    return _guard(_datasource.fetchBookings, 'تعذر تحميل الحجوزات');
  }

  @override
  Future<OperationBooking> approveBooking(String bookingId, String? note) {
    return _guard(
      () => _datasource.approveBooking(bookingId, note),
      'تعذر قبول الدفع',
    );
  }

  @override
  Future<OperationBooking> rejectBooking(String bookingId, String reason) {
    return _guard(
      () => _datasource.rejectBooking(bookingId, reason),
      'تعذر رفض الدفع',
    );
  }

  @override
  Future<OperationBooking> requestReupload(String bookingId, String reason) {
    return _guard(
      () => _datasource.requestReupload(bookingId, reason),
      'تعذر طلب إعادة رفع الإيصال',
    );
  }

  @override
  Future<List<OperationBooking>> bulkApprove(
    List<String> bookingIds,
    String? note,
  ) {
    return _guard(
      () => _datasource.bulkApprove(bookingIds, note),
      'تعذر اعتماد الحجوزات المحددة',
    );
  }

  @override
  Future<List<OperationBooking>> bulkReject(
    List<String> bookingIds,
    String reason,
  ) {
    return _guard(
      () => _datasource.bulkReject(bookingIds, reason),
      'تعذر رفض الحجوزات المحددة',
    );
  }

  @override
  Future<List<ReassignmentTarget>> getReassignmentTargets() {
    return _guard(
      _datasource.fetchReassignmentTargets,
      'تعذر تحميل الرحلات المتاحة للنقل',
    );
  }

  @override
  Future<OperationBooking> reassignBooking(String bookingId, String newTripId) {
    return _guard(
      () => _datasource.reassignBooking(bookingId, newTripId),
      'تعذر نقل الحجز إلى الرحلة المحددة',
    );
  }

  @override
  Future<OperationBooking> addNote(String bookingId, String note) {
    return _guard(
      () => _datasource.addNote(bookingId, note),
      'تعذر حفظ الملاحظة',
    );
  }

  @override
  Stream<List<OperationBooking>> watchBookings() =>
      _datasource.watchBookings().cast();

  /// Runs [action], prefixing any failure with [message].
  ///
  /// The underlying reason is kept rather than discarded: the RPCs raise
  /// specific, actionable errors (`seat_taken`, `cross_office_reassignment_denied`,
  /// …) and an operator who only sees "تعذر نقل الحجز" has no way to act on them.
  Future<T> _guard<T>(Future<T> Function() action, String message) async {
    try {
      return await action();
    } catch (error) {
      throw Exception('$message: ${_reason(error)}');
    }
  }

  String _reason(Object error) {
    final text = error is Exception
        ? error.toString().replaceFirst('Exception: ', '')
        : error.toString();
    return text.trim().isEmpty ? 'سبب غير معروف' : text.trim();
  }
}
