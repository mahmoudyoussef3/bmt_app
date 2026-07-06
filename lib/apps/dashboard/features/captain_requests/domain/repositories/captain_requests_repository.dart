import '../entities/captain_request.dart';

abstract class CaptainRequestsRepository {
  /// All requests, newest first.
  Future<List<CaptainRequest>> getRequests();

  /// Live queue stream for the dashboard.
  Stream<List<CaptainRequest>> watchRequests();

  /// Links an approved request to the driver record created for it and stamps
  /// the reviewer.
  Future<void> approve({required String requestId, required String driverId});

  /// Marks a request rejected with a reason shown to the captain.
  Future<void> reject({required String requestId, required String reason});
}
