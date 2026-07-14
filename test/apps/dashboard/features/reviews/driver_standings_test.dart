import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/features/reviews/domain/entities/reviews_summary.dart';
import 'package:bmt_app/apps/dashboard/features/reviews/domain/entities/trip_review_entry.dart';

TripReviewEntry _review({
  required String driverName,
  required int driver,
}) {
  return TripReviewEntry(
    id: '$driverName-$driver',
    bookingId: 'b',
    bookingNumber: 'BK-1',
    clientName: 'Client',
    driverName: driverName,
    vehicleName: 'Coach',
    routeLabel: 'A → B',
    driverRating: driver,
    vehicleRating: 5,
    routeRating: 5,
    comment: '',
    createdAt: DateTime(2026, 7, 14),
  );
}

void main() {
  group('DriverRatingStanding.rank', () {
    test('averages each captain and ranks the best first', () {
      final standings = DriverRatingStanding.rank([
        _review(driverName: 'Ahmed', driver: 5),
        _review(driverName: 'Ahmed', driver: 3),
        _review(driverName: 'Khaled', driver: 5),
      ]);

      expect(standings.first.driverName, 'Khaled');
      expect(standings.first.average, 5.0);
      expect(standings.last.driverName, 'Ahmed');
      expect(standings.last.average, 4.0);
      expect(standings.last.reviewCount, 2);
    });

    test('ignores reviews whose captain was never recorded', () {
      final standings = DriverRatingStanding.rank([
        _review(driverName: '  ', driver: 1),
        _review(driverName: 'Ahmed', driver: 4),
      ]);

      expect(standings.map((s) => s.driverName), ['Ahmed']);
    });
  });

  group('ReviewsSummary.from', () {
    test('an empty board reports zeroes rather than NaN', () {
      final summary = ReviewsSummary.from([]);

      expect(summary.total, 0);
      expect(summary.driverAverage, 0);
      expect(summary.needsAttentionCount, 0);
    });
  });
}
