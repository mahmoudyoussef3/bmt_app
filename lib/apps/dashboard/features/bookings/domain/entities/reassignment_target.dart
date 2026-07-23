/// A trip an existing booking can be moved onto.
///
/// Only trips that are still accepting passengers qualify, so the picker can
/// never offer a departed or closed trip as a destination.
class ReassignmentTarget {
  const ReassignmentTarget({
    required this.tripId,
    required this.routeName,
    required this.tripDate,
    required this.departureTime,
  });

  final String tripId;
  final String routeName;
  final String tripDate;
  final String departureTime;

  String get label => '$routeName — $tripDate · $departureTime';
}
