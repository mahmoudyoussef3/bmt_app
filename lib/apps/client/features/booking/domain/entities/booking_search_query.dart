/// Search criteria passed between booking flow screens.
class BookingSearchQuery {
  const BookingSearchQuery({
    this.routeId,
    this.pickup = '',
    this.destination = '',
    this.date = '',
    this.time = '',
    this.initialPackageId,
  });

  final String? routeId;
  final String pickup;
  final String destination;
  final String date;
  final String time;

  /// A package the rider reviewed before starting this search — carried
  /// through so the wizard's package step can open with it pre-selected.
  final String? initialPackageId;

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
    String? initialPackageId,
  }) {
    return BookingSearchQuery(
      routeId: routeId ?? this.routeId,
      pickup: pickup ?? this.pickup,
      destination: destination ?? this.destination,
      date: date ?? this.date,
      time: time ?? this.time,
      initialPackageId: initialPackageId ?? this.initialPackageId,
    );
  }

  Map<String, String> toArguments() => {
    'routeId': ?routeId,
    'pickup': pickup,
    'destination': destination,
    'date': date,
    'time': time,
    'initialPackageId': ?initialPackageId,
  };

  static BookingSearchQuery fromArguments(Object? args) {
    if (args is BookingSearchQuery) return args;
    if (args is Map) {
      return BookingSearchQuery(
        routeId: args['routeId']?.toString(),
        pickup: args['pickup']?.toString() ?? '',
        destination: args['destination']?.toString() ?? '',
        date: args['date']?.toString() ?? '',
        time: args['time']?.toString() ?? '',
        initialPackageId: args['initialPackageId']?.toString(),
      );
    }
    return const BookingSearchQuery();
  }
}
