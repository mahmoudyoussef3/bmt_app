import '../entities/check_in_result.dart';

abstract class CheckInRepository {
  Future<CheckInResult> checkPassenger({
    required String tripId,
    required String passengerId,
    required CheckInStatus status,
  });
}
