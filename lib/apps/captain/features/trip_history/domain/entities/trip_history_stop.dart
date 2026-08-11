class TripHistoryStop {
  const TripHistoryStop({
    required this.name,
    required this.order,
    this.scheduledTime,
  });

  final String name;
  final int order;

  final String? scheduledTime;
}
