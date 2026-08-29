import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/ui_state/dashboard_filter_memory.dart';

import '../../domain/entities/trip_review_entry.dart';
import '../../domain/usecases/reviews_usecases.dart';
import '../models/review_sort.dart';
import 'reviews_state.dart';

/// التقييمات' narrowings as one remembered value, so an operator who opens a
/// review, reads it and comes back finds the queue they were working — the same
/// contract [TicketFilterSnapshot] gives the support desk next door.
typedef ReviewFilterSnapshot = ({
  String search,
  ReviewsFilter filter,
  ReviewRatingBand band,
  String? driverName,
  String? routeLabel,
});

class ReviewsCubit extends Cubit<ReviewsState> {
  ReviewsCubit({
    required GetReviewsUseCase getReviews,
    required WatchReviewsUseCase watchReviews,
  }) : _getReviews = getReviews,
       _watchReviews = watchReviews,
       super(const ReviewsLoading());

  final GetReviewsUseCase _getReviews;
  final WatchReviewsUseCase _watchReviews;

  StreamSubscription<List<TripReviewEntry>>? _sub;

  Future<void> load() async {
    emit(const ReviewsLoading());
    try {
      final remembered = DashboardFilterMemory.instance
          .read<ReviewFilterSnapshot>(DashboardFilterIds.reviews);
      emit(
        ReviewsLoaded(
          reviews: await _getReviews(),
          query: remembered?.search ?? '',
          filter: remembered?.filter ?? ReviewsFilter.all,
          band: remembered?.band ?? ReviewRatingBand.any,
          driverName: remembered?.driverName,
          routeLabel: remembered?.routeLabel,
        ),
      );
      _listen();
    } catch (error) {
      emit(ReviewsError(_message(error)));
    }
  }

  /// A review that lands while operations is on this screen shows up on its
  /// own. The live feed must never blow away the filter they are working in,
  /// so it only swaps the data.
  void _listen() {
    _sub?.cancel();
    _sub = _watchReviews().listen((reviews) {
      final current = state;
      if (current is! ReviewsLoaded) {
        emit(ReviewsLoaded(reviews: reviews));
        return;
      }
      emit(current.copyWith(reviews: reviews));
    }, onError: (_) {});
  }

  void setFilter(ReviewsFilter filter) {
    final current = state;
    if (current is! ReviewsLoaded) return;
    _remember(current.copyWith(filter: filter));
  }

  void search(String query) {
    final current = state;
    if (current is! ReviewsLoaded) return;
    _remember(current.copyWith(query: query));
  }

  void setBand(ReviewRatingBand band) {
    final current = state;
    if (current is! ReviewsLoaded) return;
    _remember(current.copyWith(band: band));
  }

  void setDriver(String? driverName) {
    final current = state;
    if (current is! ReviewsLoaded) return;
    _remember(
      current.copyWith(
        driverName: driverName,
        clearDriverName: driverName == null,
      ),
    );
  }

  void setRoute(String? routeLabel) {
    final current = state;
    if (current is! ReviewsLoaded) return;
    _remember(
      current.copyWith(
        routeLabel: routeLabel,
        clearRouteLabel: routeLabel == null,
      ),
    );
  }

  /// Re-orders the feed. Handed the key already in force it flips the
  /// direction, which is what both the toolbar's arrow and a second tap on a
  /// column header mean.
  void setSort(ReviewSort sort) {
    final current = state;
    if (current is! ReviewsLoaded) return;
    if (current.sort == sort) {
      emit(current.copyWith(sortAscending: !current.sortAscending));
      return;
    }
    // Every key here opens on the answer worth seeing first: the newest review,
    // the worst score, the first captain alphabetically.
    emit(
      current.copyWith(sort: sort, sortAscending: sort == ReviewSort.driver),
    );
  }

  /// Drops every narrowing at once, search text included — what the empty
  /// state's "عرض الكل" offers when a filtered feed comes back with nothing.
  void clearFilters() {
    final current = state;
    if (current is! ReviewsLoaded) return;
    // Forget rather than remember an empty snapshot, so "cleared" survives
    // navigation the same way a selection does.
    DashboardFilterMemory.instance.forget(DashboardFilterIds.reviews);
    emit(
      current.copyWith(
        query: '',
        filter: ReviewsFilter.all,
        band: ReviewRatingBand.any,
        clearDriverName: true,
        clearRouteLabel: true,
      ),
    );
  }

  /// Emits [next] and files its narrowings away for the operator's next visit.
  /// Every setter goes through here so none can be added later that silently
  /// forgets.
  void _remember(ReviewsLoaded next) {
    DashboardFilterMemory.instance.write(DashboardFilterIds.reviews, (
      search: next.query,
      filter: next.filter,
      band: next.band,
      driverName: next.driverName,
      routeLabel: next.routeLabel,
    ));
    emit(next);
  }

  String _message(Object error) =>
      error.toString().replaceAll('Exception: ', '');

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
