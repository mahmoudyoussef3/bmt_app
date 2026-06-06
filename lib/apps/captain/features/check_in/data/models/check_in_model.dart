import '../../domain/entities/check_in_result.dart';

class CheckInModel {
  const CheckInModel({
    required this.tripId,
    required this.passengerId,
    required this.status,
  });

  final String tripId;
  final String passengerId;
  final CheckInStatus status;

  CheckInResult toEntity() {
    return CheckInResult(
      tripId: tripId,
      passengerId: passengerId,
      status: status,
    );
  }
}
