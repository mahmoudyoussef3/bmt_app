import '../../domain/entities/trip_history_item.dart';

enum TripHistoryDateFilter { all, today, thisWeek, thisMonth }

extension TripHistoryDateFilterLabel on TripHistoryDateFilter {
  String get label => switch (this) {
    TripHistoryDateFilter.all => 'الكل',
    TripHistoryDateFilter.today => 'اليوم',
    TripHistoryDateFilter.thisWeek => 'هذا الأسبوع',
    TripHistoryDateFilter.thisMonth => 'هذا الشهر',
  };

  bool matches(DateTime tripDate, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(tripDate.year, tripDate.month, tripDate.day);
    return switch (this) {
      TripHistoryDateFilter.all => true,
      TripHistoryDateFilter.today => day == today,
      TripHistoryDateFilter.thisWeek => !day.isBefore(
        today.subtract(Duration(days: today.weekday - 1)),
      ),
      TripHistoryDateFilter.thisMonth =>
        tripDate.year == now.year && tripDate.month == now.month,
    };
  }
}

/// Applies the date filter and a free-text route search, in that order.
List<TripHistoryItem> filterTripHistory({
  required List<TripHistoryItem> trips,
  required TripHistoryDateFilter dateFilter,
  required String query,
  DateTime? now,
}) {
  final effectiveNow = now ?? DateTime.now();
  final normalizedQuery = query.trim().toLowerCase();

  return trips.where((trip) {
    if (!dateFilter.matches(trip.tripDate, effectiveNow)) return false;
    if (normalizedQuery.isEmpty) return true;
    return trip.route.toLowerCase().contains(normalizedQuery);
  }).toList();
}

/// How many trips sit in each date range.
///
/// The search query is deliberately left out: a chip's count answers "is there
/// anything for me over there?", and narrowing it by a query the captain is
/// about to leave behind would answer a question nobody asked — every chip
/// would read zero the moment a search missed.
Map<TripHistoryDateFilter, int> countTripsByDateFilter(
  List<TripHistoryItem> trips, {
  DateTime? now,
}) {
  final effectiveNow = now ?? DateTime.now();
  return {
    for (final filter in TripHistoryDateFilter.values)
      filter: trips
          .where((trip) => filter.matches(trip.tripDate, effectiveNow))
          .length,
  };
}

class TripHistoryGroup {
  const TripHistoryGroup(this.label, this.trips);

  final String label;
  final List<TripHistoryItem> trips;
}

/// Buckets an already-sorted (newest first) trip list into recency sections.
/// Order within each bucket is preserved from the input.
List<TripHistoryGroup> groupTripHistoryByPeriod(
  List<TripHistoryItem> trips, {
  DateTime? now,
}) {
  final effectiveNow = now ?? DateTime.now();
  final today = DateTime(
    effectiveNow.year,
    effectiveNow.month,
    effectiveNow.day,
  );
  final yesterday = today.subtract(const Duration(days: 1));
  final weekStart = today.subtract(Duration(days: today.weekday - 1));

  const todayLabel = 'اليوم';
  const yesterdayLabel = 'أمس';
  const thisWeekLabel = 'هذا الأسبوع';
  const thisMonthLabel = 'هذا الشهر';
  const olderLabel = 'أقدم';
  const order = [
    todayLabel,
    yesterdayLabel,
    thisWeekLabel,
    thisMonthLabel,
    olderLabel,
  ];

  final buckets = <String, List<TripHistoryItem>>{};
  for (final trip in trips) {
    final day = DateTime(
      trip.tripDate.year,
      trip.tripDate.month,
      trip.tripDate.day,
    );
    final String key;
    if (day == today) {
      key = todayLabel;
    } else if (day == yesterday) {
      key = yesterdayLabel;
    } else if (!day.isBefore(weekStart)) {
      key = thisWeekLabel;
    } else if (day.year == effectiveNow.year &&
        day.month == effectiveNow.month) {
      key = thisMonthLabel;
    } else {
      key = olderLabel;
    }
    buckets.putIfAbsent(key, () => []).add(trip);
  }

  return [
    for (final key in order)
      if (buckets[key] case final tripsInBucket?)
        TripHistoryGroup(key, tripsInBucket),
  ];
}
