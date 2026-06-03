import 'package:flutter/material.dart';

/// Search criteria passed between booking flow screens (UI only).
class BookingSearchQuery {
  const BookingSearchQuery({
    this.pickup = '',
    this.destination = '',
    this.date = 'Today, Jun 3',
    this.time = '',
  });

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
    String? pickup,
    String? destination,
    String? date,
    String? time,
  }) {
    return BookingSearchQuery(
      pickup: pickup ?? this.pickup,
      destination: destination ?? this.destination,
      date: date ?? this.date,
      time: time ?? this.time,
    );
  }

  Map<String, String> toArguments() => {
    'pickup': pickup,
    'destination': destination,
    'date': date,
    'time': time,
  };

  static BookingSearchQuery fromArguments(Object? args) {
    if (args is BookingSearchQuery) return args;
    if (args is Map) {
      return BookingSearchQuery(
        pickup: args['pickup']?.toString() ?? '',
        destination: args['destination']?.toString() ?? '',
        date: args['date']?.toString() ?? 'Today, Jun 3',
        time: args['time']?.toString() ?? '',
      );
    }
    return const BookingSearchQuery();
  }

  static BookingSearchQuery of(BuildContext context) {
    return fromArguments(ModalRoute.of(context)?.settings.arguments);
  }
}
