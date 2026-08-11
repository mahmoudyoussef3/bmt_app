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
    this.boardingPointId,
    this.boardingIndex,
    this.dropoffIndex,
    this.status,
    this.bookingStatus,
  });

  final String? seatLabel;
  final String? boardingName;
  final String? dropoffName;

  /// `trip_passengers.pickup_point_id` — the route station id, which is what a
  /// station board row is keyed on. Kept so the rider's stop can be found on the
  /// board by id rather than by a name that may have been edited since.
  final String? boardingPointId;

  /// Index into the trip's ordered stops, or null when the manifest point
  /// couldn't be matched to a stop on this trip.
  final int? boardingIndex;
  final int? dropoffIndex;

  /// The manifest status, straight from `trip_passengers.status`.
  final String? status;

  /// The booking's own status, straight from `operation_bookings.status`.
  ///
  /// Distinct from [status] and not redundant with it: the manifest row is the
  /// operation's record of who is aboard, while the booking is *this rider's*
  /// record — and it is the booking, flipping to `boarded`, that ends this
  /// rider's live-tracking access. Trips can also carry manifest rows with no
  /// booking behind them (an office-entered passenger), so neither implies the
  /// other.
  final String? bookingStatus;

  /// Aboard. True from either side of the record: the captain checking them in
  /// on the manifest, or the rider confirming their own boarding.
  bool get hasBoarded => status == 'confirmed' || bookingStatus == 'boarded';

  /// Whether this rider may still watch the vehicle move.
  ///
  /// Deliberately fails *open*: this is off only when we positively know the
  /// rider is aboard. The boundary is `can_read_trip_fixes`, which returns
  /// nothing to a boarded rider whatever the app believes, so failing open costs
  /// at most an idle subscription that receives no rows — while failing closed
  /// would take the map away from a rider still standing at their stop because a
  /// single field did not load.
  bool get canTrackVehicle => !hasBoarded;

  /// Ready to confirm boarding: paid for, not yet aboard.
  bool get canConfirmBoarding => bookingStatus == 'confirmed' && !hasBoarded;

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
