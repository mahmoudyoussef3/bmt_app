import '../../domain/entities/reassignment_target.dart';
import '../models/operation_booking_model.dart';

abstract class BookingsDatasource {
  Future<List<OperationBookingModel>> fetchBookings();

  Future<OperationBookingModel> approveBooking(String bookingId, String? note);

  Future<OperationBookingModel> rejectBooking(String bookingId, String reason);

  Future<OperationBookingModel> requestReupload(
    String bookingId,
    String reason,
  );

  /// Approves every submitted payment in [bookingIds] via the same audited RPC
  /// used for a single booking. Returns the refreshed rows.
  Future<List<OperationBookingModel>> bulkApprove(
    List<String> bookingIds,
    String? note,
  );

  Future<List<OperationBookingModel>> bulkReject(
    List<String> bookingIds,
    String reason,
  );

  /// Trips this booking could be moved to: future departures still accepting
  /// passengers, newest first. Used by the reassignment picker.
  Future<List<ReassignmentTarget>> fetchReassignmentTargets();

  /// Moves a booking onto [newTripId], releasing the old seat and taking one on
  /// the new trip. Returns the refreshed booking row.
  Future<OperationBookingModel> reassignBooking(
    String bookingId,
    String newTripId,
  );

  Stream<List<OperationBookingModel>> watchBookings();
}
