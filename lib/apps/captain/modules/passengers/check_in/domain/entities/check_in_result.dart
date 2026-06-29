enum CheckInStatus { boarded, absent, cancelled, alreadyCheckedIn }

class CheckInResult {
  const CheckInResult({
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
}
