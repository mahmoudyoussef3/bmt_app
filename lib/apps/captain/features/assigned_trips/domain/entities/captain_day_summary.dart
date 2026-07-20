import 'assigned_trip.dart';

/// The captain's day reduced to what the home screen has to answer:
/// how much work is there, how far along is boarding, and — above all —
/// *which trip should the captain act on right now*.
class CaptainDaySummary {
  const CaptainDaySummary({
    required this.totalTrips,
    required this.activeTrips,
    required this.passengers,
    required this.boarded,
    required this.focusTrip,
    required this.lastArrival,
  });

  factory CaptainDaySummary.fromTrips(List<AssignedTrip> trips) {
    final sorted = [...trips]
      ..sort((a, b) => a.departureTime.compareTo(b.departureTime));

    final running = sorted.where((t) => t.status.isRunning).toList();
    // Both pre-departure states count as upcoming work: a trip operations
    // hasn't published yet is still the captain's next trip, and hiding it
    // would report an empty day to a captain who has one.
    final upcoming = sorted.where((t) => t.status.isUpcoming).toList();

    return CaptainDaySummary(
      totalTrips: sorted.length,
      activeTrips: running.length,
      passengers: sorted.fold(0, (sum, t) => sum + t.passengerCount),
      boarded: sorted.fold(0, (sum, t) => sum + t.boardedCount),
      // A trip already under way outranks a scheduled one, however early that
      // scheduled one departs — the captain is driving it right now.
      focusTrip: running.firstOrNull ?? upcoming.firstOrNull,
      // The latest arrival, not the last trip by departure: a short trip that
      // leaves later can still finish before a long one that left earlier.
      lastArrival: sorted.isEmpty
          ? null
          : sorted
                .map((t) => t.expectedArrivalTime)
                .reduce((a, b) => a.isAfter(b) ? a : b),
    );
  }

  final int totalTrips;
  final int activeTrips;
  final int passengers;
  final int boarded;

  /// The trip the captain should act on, or null when nothing is left to drive.
  final AssignedTrip? focusTrip;

  /// When the day's last trip is expected to arrive — null only when no trip is
  /// assigned. Lets a finished day report the hour it closed on.
  final DateTime? lastArrival;

  bool get isEmpty => totalTrips == 0;

  /// Every assigned trip is done — distinct from having no trips at all.
  bool get isDayComplete => totalTrips > 0 && focusTrip == null;

  double get boardingProgress => passengers == 0 ? 0 : boarded / passengers;
}
