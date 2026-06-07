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
}
