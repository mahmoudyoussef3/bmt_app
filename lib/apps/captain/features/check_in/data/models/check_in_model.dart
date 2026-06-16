import '../../domain/entities/check_in_result.dart';

class CheckInModel {
  const CheckInModel({
    required this.tripId,
    required this.passengerId,
    required this.status,
    this.passengerName,
    this.seatLabel,
    this.errorMessage,
  });

  final String tripId;
  final String passengerId;
  final CheckInStatus status;
  final String? passengerName;
  final String? seatLabel;
  final String? errorMessage;

  factory CheckInModel.fromRpcResponse({
    required String tripId,
    required String passengerId,
    required Map<String, dynamic> response,
  }) {
    final success = response['success'] as bool? ?? false;
    final alreadyIn = response['already_checked_in'] as bool? ?? false;

    CheckInStatus status;
    if (!success) {
      status = CheckInStatus.absent;
    } else if (alreadyIn) {
      status = CheckInStatus.alreadyCheckedIn;
    } else {
      status = CheckInStatus.boarded;
    }

    return CheckInModel(
      tripId: tripId,
      passengerId: passengerId,
      status: status,
      passengerName: response['passenger_name'] as String?,
      seatLabel: response['seat_label'] as String?,
      errorMessage: response['error'] as String?,
    );
  }

  CheckInResult toEntity() {
    return CheckInResult(
      tripId: tripId,
      passengerId: passengerId,
      status: status,
      passengerName: passengerName,
      seatLabel: seatLabel,
      errorMessage: errorMessage,
    );
  }
}
