import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/models/route_filter_criteria.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/utils/route_result_sort.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

PopularRouteListData _route({
  String pickup = 'Cairo',
  String destination = 'Alexandria',
  String startingPrice = r'$100',
  String averageDuration = '2 hours',
  int dailyTrips = 3,
}) {
  return PopularRouteListData(
    id: 'route-1',
    routeName: '$pickup - $destination',
    dailyTrips: dailyTrips,
    averageDuration: averageDuration,
    startingPrice: startingPrice,
    pickup: pickup,
    destination: destination,
    distance: '200 km',
  );
}

void main() {
  group('RouteFilterCriteria.activeCount', () {
    test('is zero with no filters applied', () {
      expect(const RouteFilterCriteria().activeCount, 0);
    });

    test('counts each independently-set filter', () {
      const criteria = RouteFilterCriteria(
        pickup: 'Cairo',
        destination: 'Alexandria',
        priceRange: RangeValues(0, 100),
      );
      expect(criteria.activeCount, 3);
    });
  });

  group('RouteFilterCriteria.copyWith', () {
    test('clears an individual filter without touching the others', () {
      const criteria = RouteFilterCriteria(
        pickup: 'Cairo',
        destination: 'Alexandria',
      );
      final updated = criteria.copyWith(clearPickup: true);
      expect(updated.pickup, isNull);
      expect(updated.destination, 'Alexandria');
    });
  });

  group('RouteFilterCriteria.reset', () {
    test('clears every filter and sort choice', () {
      const criteria = RouteFilterCriteria(
        pickup: 'Cairo',
        sort: RouteResultSort.priceLow,
      );
      final reset = criteria.reset();
      expect(reset.activeCount, 0);
      expect(reset.sort, RouteResultSort.recommended);
    });
  });

  group('RouteFilterCriteria.matches', () {
    test('rejects a route outside the price range', () {
      const criteria = RouteFilterCriteria(priceRange: RangeValues(0, 50));
      expect(criteria.matches(_route(startingPrice: r'$100')), isFalse);
    });

    test('accepts a route inside the price range', () {
      const criteria = RouteFilterCriteria(priceRange: RangeValues(0, 150));
      expect(criteria.matches(_route(startingPrice: r'$100')), isTrue);
    });

    test('rejects a route outside the duration range', () {
      const criteria = RouteFilterCriteria(durationRange: RangeValues(0, 60));
      expect(criteria.matches(_route(averageDuration: '2 hours')), isFalse);
    });

    test('rejects a route with a non-matching pickup', () {
      const criteria = RouteFilterCriteria(pickup: 'Giza');
      expect(criteria.matches(_route(pickup: 'Cairo')), isFalse);
    });
  });

  group('RouteFilterCriteria.compare', () {
    test('priceLow sorts ascending by parsed price', () {
      const criteria = RouteFilterCriteria(sort: RouteResultSort.priceLow);
      final cheap = _route(startingPrice: r'$50');
      final expensive = _route(startingPrice: r'$200');
      expect(criteria.compare(cheap, expensive), lessThan(0));
    });

    test('durationShort sorts ascending by parsed duration', () {
      const criteria = RouteFilterCriteria(sort: RouteResultSort.durationShort);
      final short = _route(averageDuration: '30 min');
      final long = _route(averageDuration: '3 hours');
      expect(criteria.compare(short, long), lessThan(0));
    });
  });

  group('RouteFilterCriteria parsing helpers', () {
    test('parsePrice extracts digits from a currency string', () {
      expect(RouteFilterCriteria.parsePrice(r'$1,250'), 1250);
    });

    test('parseDurationMinutes converts hours to minutes', () {
      expect(RouteFilterCriteria.parseDurationMinutes('1.5 hours'), 90);
    });

    test('parseDurationMinutes treats a plain number as minutes', () {
      expect(RouteFilterCriteria.parseDurationMinutes('45'), 45);
    });
  });
}
