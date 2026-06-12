import '../../domain/entities/operation_booking.dart';
import '../models/operation_booking_model.dart';

abstract class BookingsDatasource {
  Future<List<OperationBookingModel>> fetchBookings();
  Future<OperationBookingModel> updateBookingStatus(
    String bookingId,
    BookingStatus status,
  );
  Future<List<OperationBookingModel>> bulkUpdateStatus(
    List<String> bookingIds,
    BookingStatus status,
  );
  Future<List<OperationBookingModel>> assignToTrip(
    List<String> bookingIds,
    String tripId,
  );
  Future<OperationBookingModel> approveBooking(
    String bookingId,
    String reviewer,
    String? note,
  );
  Future<OperationBookingModel> rejectBooking(
    String bookingId,
    String reviewer,
    String reason,
    String? note,
  );
  Future<OperationBookingModel> requestReupload(
    String bookingId,
    String reviewer,
    String reason,
  );
}
