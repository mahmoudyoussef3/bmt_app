/// Search criteria passed between booking flow screens.
class BookingSearchQuery {
  const BookingSearchQuery({
    this.routeId,
    this.pickup = '',
    this.destination = '',
    this.date = 'Today, Jun 3',
    this.time = '',
  });

  final String? routeId;
  final String pickup;
  final String destination;
  final String date;
  final String time;

  bool get isComplete => pickup.isNotEmpty && destination.isNotEmpty;

  String get summaryLine {
    if (!isComplete) return 'Set pickup and destination';
    final timePart = time.isEmpty ? '' : ' · $time';
    return '$pickup → $destination · $date$timePart';
  }

  BookingSearchQuery copyWith({
    String? routeId,
    String? pickup,
    String? destination,
    String? date,
    String? time,
  }) {
    return BookingSearchQuery(
      routeId: routeId ?? this.routeId,
      pickup: pickup ?? this.pickup,
      destination: destination ?? this.destination,
      date: date ?? this.date,
      time: time ?? this.time,
    );
  }

  Map<String, String> toArguments() => {
    if (routeId != null) 'routeId': routeId!,
    'pickup': pickup,
    'destination': destination,
    'date': date,
    'time': time,
  };

  static BookingSearchQuery fromArguments(Object? args) {
    if (args is BookingSearchQuery) return args;
    if (args is Map) {
      return BookingSearchQuery(
        routeId: args['routeId']?.toString(),
        pickup: args['pickup']?.toString() ?? '',
        destination: args['destination']?.toString() ?? '',
        date: args['date']?.toString() ?? 'Today, Jun 3',
        time: args['time']?.toString() ?? '',
      );
    }
    return const BookingSearchQuery();
  }
}
