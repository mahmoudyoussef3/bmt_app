enum CheckInStatus { boarded, absent, cancelled }

class CheckInResult {
  const CheckInResult({
    required this.tripId,
    required this.passengerId,
    required this.status,
  });

  final String tripId;
  final String passengerId;
  final CheckInStatus status;
}
