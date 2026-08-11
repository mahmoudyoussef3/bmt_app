library;

const Duration kCaptainBoardingWindow = Duration(minutes: 30);

enum CaptainTripStage {
  awaitingRelease,

  awaitingWindow,

  readyToBoard,

  boarding,

  underway,

  finished,
  cancelled,
}

extension CaptainTripStageX on CaptainTripStage {
  bool get isLive =>
      this == CaptainTripStage.boarding || this == CaptainTripStage.underway;

  bool get isWaiting =>
      this == CaptainTripStage.awaitingRelease ||
      this == CaptainTripStage.awaitingWindow;

  bool get isTerminal =>
      this == CaptainTripStage.finished || this == CaptainTripStage.cancelled;
}

CaptainTripStage resolvePublishedStage({
  required DateTime departureTime,
  required DateTime now,
}) {
  final boardingOpensAt = departureTime.subtract(kCaptainBoardingWindow);
  return now.isBefore(boardingOpensAt)
      ? CaptainTripStage.awaitingWindow
      : CaptainTripStage.readyToBoard;
}

DateTime boardingOpensAt(DateTime departureTime) =>
    departureTime.subtract(kCaptainBoardingWindow);
