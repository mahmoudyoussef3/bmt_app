import '../entities/operation_booking.dart';

abstract class BookingsRepository {
  Future<List<OperationBooking>> getBookings();
  Future<OperationBooking> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  );
  Future<List<OperationBooking>> bulkUpdateStatus(
    List<String> bookingIds,
    BookingStatus status,
  );
  Future<List<OperationBooking>> assignToTrip(
    List<String> bookingIds,
    String tripId,
  );
  Future<OperationBooking> approveBooking(
    String bookingId,
    String reviewer,
    String? note,
  );
  Future<OperationBooking> rejectBooking(
    String bookingId,
    String reviewer,
    String reason,
    String? note,
  );
  Future<OperationBooking> requestReupload(
    String bookingId,
    String reviewer,
    String reason,
  );

  Stream<List<OperationBooking>> watchBookings();
}
