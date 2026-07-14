import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/reviewable_trip.dart';
import '../../domain/entities/trip_review.dart';
import '../../domain/usecases/get_trip_review_usecase.dart';
import '../../domain/usecases/submit_trip_review_usecase.dart';
import 'trip_review_state.dart';

class TripReviewCubit extends Cubit<TripReviewState> {
  TripReviewCubit({
    required GetTripReviewUseCase getReview,
    required SubmitTripReviewUseCase submitReview,
  }) : _getReview = getReview,
       _submitReview = submitReview,
       super(const TripReviewLoading());

  final GetTripReviewUseCase _getReview;
  final SubmitTripReviewUseCase _submitReview;

  ReviewableTrip? _trip;

  /// Opens the sheet on the right state: the passenger's existing review if
  /// they already left one, otherwise an empty form.
  Future<void> load(ReviewableTrip trip) async {
    _trip = trip;
    emit(const TripReviewLoading());
    try {
      final existing = await _getReview(trip.bookingId);
      if (isClosed) return;
      if (existing != null) {
        emit(TripReviewSubmitted(existing));
        return;
      }
      emit(TripReviewEditing(draft: _emptyDraft(trip.bookingId)));
    } catch (error) {
      if (isClosed) return;
      emit(TripReviewLoadFailure(_message(error)));
    }
  }

  void rateDriver(int stars) => _edit((d) => d.copyWith(driverRating: stars));

  void rateVehicle(int stars) => _edit((d) => d.copyWith(vehicleRating: stars));

  void rateRoute(int stars) => _edit((d) => d.copyWith(routeRating: stars));

  void writeComment(String comment) =>
      _edit((d) => d.copyWith(comment: comment), silent: true);

  Future<void> submit() async {
    final current = state;
    final trip = _trip;
    if (current is! TripReviewEditing || trip == null) return;
    if (!current.canSubmit) return;

    emit(current.copyWith(isSubmitting: true));
    try {
      await _submitReview(trip, current.draft);
      if (isClosed) return;
      emit(TripReviewSubmitted(current.draft));
    } catch (error) {
      if (isClosed) return;
      emit(current.copyWith(isSubmitting: false, error: _message(error)));
    }
  }

  Future<void> retry() async {
    final trip = _trip;
    if (trip != null) await load(trip);
  }

  TripReview _emptyDraft(String bookingId) => TripReview(
    bookingId: bookingId,
    driverRating: 0,
    vehicleRating: 0,
    routeRating: 0,
  );

  /// Edits clear any previous error: the passenger has moved on from it.
  /// A comment keystroke is [silent] so it does not fight the text field.
  void _edit(TripReview Function(TripReview) change, {bool silent = false}) {
    final current = state;
    if (current is! TripReviewEditing || current.isSubmitting) return;
    final draft = change(current.draft);
    if (silent) {
      emit(TripReviewEditing(draft: draft, error: current.error));
      return;
    }
    emit(TripReviewEditing(draft: draft));
  }

  String _message(Object error) =>
      error.toString().replaceAll('Exception: ', '');
}
