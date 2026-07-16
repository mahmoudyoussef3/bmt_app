import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/features/trip_history/domain/entities/trip_history_item.dart';
import 'package:bmt_app/apps/captain/features/trip_history/presentation/utils/trip_history_filters.dart';

// "Now" is fixed at Wednesday 2026-07-16 for every test below.
final _now = DateTime(2026, 7, 16, 12);

void main() {
  group('filterTripHistory', () {
    test('TripHistoryDateFilter.all keeps every trip regardless of date', () {
      final trips = [_trip(date: DateTime(2020, 1, 1)), _trip(date: _now)];

      final result = filterTripHistory(
        trips: trips,
        dateFilter: TripHistoryDateFilter.all,
        query: '',
        now: _now,
      );

      expect(result, hasLength(2));
    });

    test('today excludes trips from any other day', () {
      final trips = [
        _trip(id: 'today', date: _now),
        _trip(id: 'yesterday', date: _now.subtract(const Duration(days: 1))),
      ];

      final result = filterTripHistory(
        trips: trips,
        dateFilter: TripHistoryDateFilter.today,
        query: '',
        now: _now,
      );

      expect(result.map((t) => t.id), ['today']);
    });

    test(
      'thisWeek includes Monday of the current week but not last Sunday',
      () {
        // _now is Wednesday 2026-07-16 -> week starts Monday 2026-07-13.
        final trips = [
          _trip(id: 'monday', date: DateTime(2026, 7, 13)),
          _trip(id: 'last-sunday', date: DateTime(2026, 7, 12)),
        ];

        final result = filterTripHistory(
          trips: trips,
          dateFilter: TripHistoryDateFilter.thisWeek,
          query: '',
          now: _now,
        );

        expect(result.map((t) => t.id), ['monday']);
      },
    );

    test('thisMonth excludes the same day/month from a different year', () {
      final trips = [
        _trip(id: 'this-month', date: DateTime(2026, 7, 1)),
        _trip(id: 'last-year', date: DateTime(2025, 7, 16)),
      ];

      final result = filterTripHistory(
        trips: trips,
        dateFilter: TripHistoryDateFilter.thisMonth,
        query: '',
        now: _now,
      );

      expect(result.map((t) => t.id), ['this-month']);
    });

    test('search matches the route case-insensitively', () {
      final trips = [
        _trip(id: 'a', route: 'القاهرة - الإسكندرية', date: _now),
        _trip(id: 'b', route: 'أسوان - الأقصر', date: _now),
      ];

      final result = filterTripHistory(
        trips: trips,
        dateFilter: TripHistoryDateFilter.all,
        query: 'قاهرة',
        now: _now,
      );

      expect(result.map((t) => t.id), ['a']);
    });

    test('date filter and search combine — both must match', () {
      final trips = [
        _trip(id: 'match', route: 'القاهرة - الإسكندرية', date: _now),
        _trip(id: 'wrong-route', route: 'أسوان - الأقصر', date: _now),
        _trip(
          id: 'wrong-day',
          route: 'القاهرة - الإسكندرية',
          date: _now.subtract(const Duration(days: 5)),
        ),
      ];

      final result = filterTripHistory(
        trips: trips,
        dateFilter: TripHistoryDateFilter.today,
        query: 'قاهرة',
        now: _now,
      );

      expect(result.map((t) => t.id), ['match']);
    });
  });

  group('groupTripHistoryByPeriod', () {
    test(
      'buckets into اليوم / أمس / هذا الأسبوع / هذا الشهر / أقدم in order',
      () {
        final trips = [
          _trip(id: 'today', date: _now),
          _trip(id: 'yesterday', date: _now.subtract(const Duration(days: 1))),
          // Monday of this week, but not today/yesterday.
          _trip(id: 'this-week', date: DateTime(2026, 7, 13)),
          // Earlier this month, before the current week started.
          _trip(id: 'this-month', date: DateTime(2026, 7, 2)),
          _trip(id: 'older', date: DateTime(2026, 5, 1)),
        ];

        final groups = groupTripHistoryByPeriod(trips, now: _now);

        expect(groups.map((g) => g.label), [
          'اليوم',
          'أمس',
          'هذا الأسبوع',
          'هذا الشهر',
          'أقدم',
        ]);
        expect(groups.map((g) => g.trips.single.id), [
          'today',
          'yesterday',
          'this-week',
          'this-month',
          'older',
        ]);
      },
    );

    test(
      'omits empty buckets entirely rather than rendering blank sections',
      () {
        final trips = [_trip(id: 'only-one', date: _now)];

        final groups = groupTripHistoryByPeriod(trips, now: _now);

        expect(groups, hasLength(1));
        expect(groups.single.label, 'اليوم');
      },
    );

    test('an empty trip list produces no groups', () {
      expect(groupTripHistoryByPeriod(const [], now: _now), isEmpty);
    });

    test('preserves the input order within a bucket', () {
      final trips = [
        _trip(id: 'first', date: _now, departureHour: 14),
        _trip(id: 'second', date: _now, departureHour: 8),
      ];

      final groups = groupTripHistoryByPeriod(trips, now: _now);

      expect(groups.single.trips.map((t) => t.id), ['first', 'second']);
    });
  });
}

TripHistoryItem _trip({
  String id = 'trip',
  String route = 'القاهرة - الإسكندرية',
  required DateTime date,
  int departureHour = 8,
}) {
  final departure = DateTime(date.year, date.month, date.day, departureHour);
  return TripHistoryItem(
    id: id,
    route: route,
    tripDate: date,
    departureTime: departure,
    arrivalTime: departure.add(const Duration(hours: 3)),
    passengerCount: 20,
    boardedCount: 20,
    vehicleNumber: 'BUS-1',
    plateNumber: 'أ ب ج 123',
  );
}
