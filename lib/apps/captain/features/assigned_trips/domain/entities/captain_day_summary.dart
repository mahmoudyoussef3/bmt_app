import 'assigned_trip.dart';

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
    final upcoming = sorted.where((t) => t.status.isUpcoming).toList();

    return CaptainDaySummary(
      totalTrips: sorted.length,
      activeTrips: running.length,
      passengers: sorted.fold(0, (sum, t) => sum + t.passengerCount),
      boarded: sorted.fold(0, (sum, t) => sum + t.boardedCount),
      focusTrip: running.firstOrNull ?? upcoming.firstOrNull,
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

  final AssignedTrip? focusTrip;

  final DateTime? lastArrival;

  bool get isEmpty => totalTrips == 0;

  bool get isDayComplete => totalTrips > 0 && focusTrip == null;

  double get boardingProgress => passengers == 0 ? 0 : boarded / passengers;
}
