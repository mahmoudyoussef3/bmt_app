import '../../domain/entities/operation_booking.dart';
import '../../domain/repositories/bookings_repository.dart';
import '../datasources/mock_bookings_datasource.dart';

class BookingsRepositoryImpl implements BookingsRepository {
  final BookingsDatasource _datasource;

  const BookingsRepositoryImpl(this._datasource);

  @override
  Future<List<OperationBooking>> assignToTrip(
    List<String> bookingIds,
    String tripId,
  ) async {
    try {
      return await _datasource.assignToTrip(bookingIds, tripId);
    } catch (_) {
      throw Exception('تعذر إسناد الحجوزات للرحلة');
    }
  }

  @override
  Future<List<OperationBooking>> bulkUpdateStatus(
    List<String> bookingIds,
    BookingStatus status,
  ) async {
    try {
      return await _datasource.bulkUpdateStatus(bookingIds, status);
    } catch (_) {
      throw Exception('تعذر تحديث الحجوزات');
    }
  }

  @override
  Future<List<OperationBooking>> getBookings() async {
    try {
      return await _datasource.fetchBookings();
    } catch (_) {
      throw Exception('تعذر تحميل الحجوزات');
    }
  }

  @override
  Future<OperationBooking> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  ) async {
    try {
      return await _datasource.updateBookingStatus(bookingId, status);
    } catch (_) {
      throw Exception('تعذر تحديث حالة الحجز');
    }
  }

  @override
  Future<OperationBooking> approveBooking(
    String bookingId,
    String reviewer,
    String? note,
  ) async {
    try {
      return await _datasource.approveBooking(bookingId, reviewer, note);
    } catch (_) {
      throw Exception('تعذر قبول الحجز');
    }
  }

  @override
  Future<OperationBooking> rejectBooking(
    String bookingId,
    String reviewer,
    String reason,
    String? note,
  ) async {
    try {
      return await _datasource.rejectBooking(bookingId, reviewer, reason, note);
    } catch (_) {
      throw Exception('تعذر رفض الحجز');
    }
  }

  @override
  Future<OperationBooking> requestReupload(
    String bookingId,
    String reviewer,
    String reason,
  ) async {
    try {
      return await _datasource.requestReupload(bookingId, reviewer, reason);
    } catch (_) {
      throw Exception('تعذر طلب إعادة رفع الإيصال');
    }
  }
}
