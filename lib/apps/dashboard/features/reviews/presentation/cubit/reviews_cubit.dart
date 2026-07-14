import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/trip_review_entry.dart';
import '../../domain/usecases/reviews_usecases.dart';
import 'reviews_state.dart';

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
      emit(ReviewsLoaded(reviews: await _getReviews()));
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
    emit(current.copyWith(filter: filter));
  }

  void search(String query) {
    final current = state;
    if (current is! ReviewsLoaded) return;
    emit(current.copyWith(query: query));
  }

  String _message(Object error) =>
      error.toString().replaceAll('Exception: ', '');

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
