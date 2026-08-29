import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_filter_memory.dart';

import 'package:bmt_app/apps/dashboard/features/reviews/domain/entities/trip_review_entry.dart';
import 'package:bmt_app/apps/dashboard/features/reviews/domain/repositories/reviews_repository.dart';
import 'package:bmt_app/apps/dashboard/features/reviews/domain/usecases/reviews_usecases.dart';
import 'package:bmt_app/apps/dashboard/features/reviews/presentation/cubit/reviews_cubit.dart';
import 'package:bmt_app/apps/dashboard/features/reviews/presentation/cubit/reviews_state.dart';

class _FakeReviewsRepository implements ReviewsRepository {
  _FakeReviewsRepository({this.reviews = const [], this.fails = false});

  final List<TripReviewEntry> reviews;
  final bool fails;

  @override
  Future<List<TripReviewEntry>> getReviews() async {
    if (fails) throw Exception('supabase down');
    return reviews;
  }

  @override
  Stream<List<TripReviewEntry>> watchReviews() => const Stream.empty();
}

TripReviewEntry _review({
  String id = 'r1',
  String clientName = 'Mahmoud',
  String driverName = 'Ahmed',
  int driver = 5,
  int vehicle = 5,
  int route = 5,
  String comment = '',
}) {
  return TripReviewEntry(
    id: id,
    bookingId: 'b-$id',
    bookingNumber: 'BK-$id',
    clientName: clientName,
    driverName: driverName,
    vehicleName: 'Mega Coach',
    routeLabel: 'Banha → Smart Village',
    driverRating: driver,
    vehicleRating: vehicle,
    routeRating: route,
    comment: comment,
    createdAt: DateTime(2026, 7, 14),
  );
}

ReviewsCubit _cubit(_FakeReviewsRepository repo) => ReviewsCubit(
  getReviews: GetReviewsUseCase(repo),
  watchReviews: WatchReviewsUseCase(repo),
);

void main() {
  // التقييمات now files its narrowings in the session-wide filter memory, the
  // way الشكاوى does — so one test's filter would otherwise be restored by the
  // next test's `load()`.
  setUp(DashboardFilterMemory.instance.clear);
  tearDown(DashboardFilterMemory.instance.clear);

  group('ReviewsCubit.load', () {
    test('surfaces a load failure instead of an empty board', () async {
      final cubit = _cubit(_FakeReviewsRepository(fails: true));

      await cubit.load();

      expect((cubit.state as ReviewsError).message, 'supabase down');
    });

    test('summarises every review, not just the visible ones', () async {
      final cubit = _cubit(
        _FakeReviewsRepository(
          reviews: [
            _review(id: 'a', driver: 5, vehicle: 5, route: 5),
            _review(id: 'b', driver: 1, vehicle: 3, route: 3),
          ],
        ),
      );

      await cubit.load();
      // Narrowing the list must not move the averages.
      cubit.setFilter(ReviewsFilter.needsAttention);

      final state = cubit.state as ReviewsLoaded;
      expect(state.summary.total, 2);
      expect(state.summary.driverAverage, 3.0);
      expect(state.summary.needsAttentionCount, 1);
      expect(state.visibleReviews.single.id, 'b');
    });
  });

  group('ReviewsCubit filters', () {
    test(
      'needsAttention catches a low score on any single dimension',
      () async {
        final cubit = _cubit(
          _FakeReviewsRepository(
            reviews: [
              // Averages a respectable 3.7 — but the vehicle was a 1.
              _review(id: 'mixed', driver: 5, vehicle: 1, route: 5),
              _review(id: 'good', driver: 5, vehicle: 5, route: 4),
            ],
          ),
        );

        await cubit.load();
        cubit.setFilter(ReviewsFilter.needsAttention);

        final state = cubit.state as ReviewsLoaded;
        expect(state.visibleReviews.single.id, 'mixed');
      },
    );

    test('withComments hides star-only reviews', () async {
      final cubit = _cubit(
        _FakeReviewsRepository(
          reviews: [
            _review(id: 'silent'),
            _review(id: 'spoken', comment: 'Bus was late'),
          ],
        ),
      );

      await cubit.load();
      cubit.setFilter(ReviewsFilter.withComments);

      final state = cubit.state as ReviewsLoaded;
      expect(state.visibleReviews.single.id, 'spoken');
    });

    test('search matches the captain as well as the passenger', () async {
      final cubit = _cubit(
        _FakeReviewsRepository(
          reviews: [
            _review(id: 'a', clientName: 'Mahmoud', driverName: 'Ahmed'),
            _review(id: 'b', clientName: 'Sara', driverName: 'Khaled'),
          ],
        ),
      );

      await cubit.load();

      cubit.search('khaled');
      expect((cubit.state as ReviewsLoaded).visibleReviews.single.id, 'b');

      cubit.search('mahmoud');
      expect((cubit.state as ReviewsLoaded).visibleReviews.single.id, 'a');
    });

    test('distinguishes an empty board from an over-filtered one', () async {
      final cubit = _cubit(_FakeReviewsRepository(reviews: [_review(id: 'a')]));

      await cubit.load();
      cubit.search('nobody');

      final state = cubit.state as ReviewsLoaded;
      expect(state.isEmpty, isFalse);
      expect(state.isFilteredEmpty, isTrue);
    });
  });
}
