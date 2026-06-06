import '../../domain/entities/check_in_result.dart';
import '../models/check_in_model.dart';

class CheckInDataSource {
  const CheckInDataSource();

  Future<CheckInModel> checkPassenger({
    required String tripId,
    required String passengerId,
    required CheckInStatus status,
  }) async {
    return CheckInModel(
      tripId: tripId,
      passengerId: passengerId,
      status: status,
    );
  }
}
