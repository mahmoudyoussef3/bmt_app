import '../../domain/entities/operation_booking.dart';
import '../../domain/repositories/bookings_repository.dart';
import '../datasources/bookings_datasource.dart';

class BookingsRepositoryImpl implements BookingsRepository {
  final BookingsDatasource _datasource;

  const BookingsRepositoryImpl(this._datasource);

  @override
  Future<List<OperationBooking>> getBookings() async {
    try {
      return await _datasource.fetchBookings();
    } catch (_) {
      throw Exception('تعذر تحميل الحجوزات');
    }
  }

  @override
  Future<OperationBooking> approveBooking(String bookingId, String? note) async {
    try {
      return await _datasource.approveBooking(bookingId, note);
    } catch (_) {
      throw Exception('تعذر قبول الدفع');
    }
  }

  @override
  Future<OperationBooking> rejectBooking(String bookingId, String reason) async {
    try {
      return await _datasource.rejectBooking(bookingId, reason);
    } catch (_) {
      throw Exception('تعذر رفض الدفع');
    }
  }

  @override
  Future<OperationBooking> requestReupload(
    String bookingId,
    String reason,
  ) async {
    try {
      return await _datasource.requestReupload(bookingId, reason);
    } catch (_) {
      throw Exception('تعذر طلب إعادة رفع الإيصال');
    }
  }

  @override
  Future<List<OperationBooking>> bulkApprove(
    List<String> bookingIds,
    String? note,
  ) async {
    try {
      return await _datasource.bulkApprove(bookingIds, note);
    } catch (_) {
      throw Exception('تعذر اعتماد الحجوزات المحددة');
    }
  }

  @override
  Future<List<OperationBooking>> bulkReject(
    List<String> bookingIds,
    String reason,
  ) async {
    try {
      return await _datasource.bulkReject(bookingIds, reason);
    } catch (_) {
      throw Exception('تعذر رفض الحجوزات المحددة');
    }
  }

  @override
  Stream<List<OperationBooking>> watchBookings() =>
      _datasource.watchBookings().cast();
}
