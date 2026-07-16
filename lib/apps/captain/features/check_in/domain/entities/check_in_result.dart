enum CheckInStatus {
  boarded,
  absent,
  cancelled,
  alreadyCheckedIn,

  /// Scanned while offline: saved locally, not yet checked against the
  /// booking. Distinct from [boarded] — the ticket hasn't been validated yet,
  /// so this must never read as a confirmed board.
  pendingSync,
}

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
