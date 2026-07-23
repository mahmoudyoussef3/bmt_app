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

  Stream<List<OperationBooking>> watchBookings();
}
