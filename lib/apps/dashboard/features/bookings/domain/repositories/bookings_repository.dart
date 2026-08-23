import '../entities/operation_booking.dart';
import '../entities/reassignment_target.dart';

abstract class BookingsRepository {
  Future<List<OperationBooking>> getBookings();

  Future<OperationBooking> approveBooking(String bookingId, String? note);

  Future<OperationBooking> rejectBooking(String bookingId, String reason);

  Future<OperationBooking> requestReupload(String bookingId, String reason);

  Future<List<OperationBooking>> bulkApprove(
    List<String> bookingIds,
    String? note,
  );

  Future<List<OperationBooking>> bulkReject(
    List<String> bookingIds,
    String reason,
  );

  Future<List<ReassignmentTarget>> getReassignmentTargets();

  Future<OperationBooking> reassignBooking(String bookingId, String newTripId);

  /// Records an operator note against the booking without deciding its
  /// payment — the "I called the passenger, they are re-sending the receipt"
  /// case that neither approve nor reject describes.
  Future<OperationBooking> addNote(String bookingId, String note);

  Stream<List<OperationBooking>> watchBookings();

  /// Exports [bookings] to CSV and hands the file to the platform's save /
  /// download flow. Returns the saved file name.
  Future<String> exportBookingsCsv(List<OperationBooking> bookings);
}
