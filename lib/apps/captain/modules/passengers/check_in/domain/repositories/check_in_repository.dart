import '../entities/check_in_result.dart';

abstract class CheckInRepository {
  Future<CheckInResult> checkPassenger({
    required String tripId,
    required String bookingId,
    required CheckInStatus status,
  });

  Future<int> flushOfflineQueue();
  Future<int> get offlineQueueLength;
}
