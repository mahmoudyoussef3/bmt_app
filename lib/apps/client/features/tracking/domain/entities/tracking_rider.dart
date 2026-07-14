/// The rider's own leg of the trip: where *they* board and alight, which seat
/// they hold, and whether the captain has actually checked them in.
///
/// A trip's stop list is the same for everyone on board, but the journey is
/// not: the rider boards at one stop and leaves at another, and the stops
/// before and after that segment are somebody else's trip. [boardingIndex] and
/// [dropoffIndex] point into the trip's ordered stop list so the timeline can
/// show that segment instead of an undifferentiated list of every stop.
class TrackingRider {
  const TrackingRider({
    this.seatLabel,
    this.boardingName,
    this.dropoffName,
    this.boardingIndex,
    this.dropoffIndex,
    this.status,
  });

  final String? seatLabel;
  final String? boardingName;
  final String? dropoffName;

  /// Index into the trip's ordered stops, or null when the manifest point
  /// couldn't be matched to a stop on this trip.
  final int? boardingIndex;
  final int? dropoffIndex;

  /// The manifest status, straight from `trip_passengers.status`.
  final String? status;

  /// The captain marks a passenger `confirmed` when they physically board.
  bool get hasBoarded => status == 'confirmed';

  bool get hasSeat => seatLabel != null && seatLabel!.trim().isNotEmpty;

  /// True once we know enough to draw the rider's segment on the timeline.
  bool get hasSegment => boardingIndex != null || dropoffIndex != null;

  bool isBoardingStop(int index) => boardingIndex == index;

  bool isDropoffStop(int index) => dropoffIndex == index;

  /// A stop the rider actually travels through — between their boarding point
  /// and their drop-off. Stops outside this range belong to other passengers'
  /// legs and are de-emphasised rather than hidden (the bus still calls there,
  /// and that is why the arrival takes as long as it does).
  bool isOnRiderLeg(int index) {
    final from = boardingIndex;
    final to = dropoffIndex;
    if (from == null || to == null) return true;
    return index >= from && index <= to;
  }
}
