import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip_review.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip_review_failure.dart';
import 'package:bmt_app/apps/client/features/trips/domain/repositories/trip_reviews_repository.dart';
import 'package:bmt_app/apps/client/features/trips/domain/usecases/get_trip_review_usecase.dart';
import 'package:bmt_app/apps/client/features/trips/domain/usecases/submit_trip_review_usecase.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trip_review_cubit.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/cubit/trip_review_state.dart';

class _FakeTripReviewsRepository implements TripReviewsRepository {
  _FakeTripReviewsRepository({this.existing, this.submitFails = false});

  final TripReview? existing;
  bool submitFails;

  TripReview? submitted;

  @override
  Future<TripReview?> getReviewForBooking(String bookingId) async => existing;

  @override
  Future<void> submitReview(TripReview review) async {
    if (submitFails) throw Exception('network down');
    submitted = review;
  }
}

TripData _trip({TripStatus status = TripStatus.completed}) => TripData(
  id: 'booking-1',
  reference: 'BK-C89AAE2E',
  status: status,
  pickup: 'Banha Station',
  destination: 'Smart Village',
  dateLabel: '2026-07-14',
  timeLabel: '08:00',
  driverName: 'Ahmed Mohamed',
  driverPhone: '0100',
  driverInitials: 'AM',
  driverRating: 4.5,
  vehicleName: 'Mega Coach',
  vehicleType: 'Bus',
  vehicleId: 'v1',
  seats: const ['A1'],
  paymentStatus: PaymentStatus.paid,
  fare: 'EGP 100',
);

TripReviewCubit _cubit(_FakeTripReviewsRepository repo) => TripReviewCubit(
  getReview: GetTripReviewUseCase(repo),
  submitReview: SubmitTripReviewUseCase(repo),
);

void main() {
  group('TripReviewCubit.load', () {
    test('opens an empty form when the trip has not been reviewed', () async {
      final cubit = _cubit(_FakeTripReviewsRepository());

      await cubit.load(_trip().reviewable);

      final state = cubit.state as TripReviewEditing;
      expect(state.draft.officeRating, 0);
      expect(state.draft.driverRating, 0);
      expect(state.draft.vehicleRating, 0);
      expect(state.draft.routeRating, 0);
      // An untouched sheet must not be submittable — otherwise it would post a
      // review the passenger never gave.
      expect(state.canSubmit, isFalse);
    });

    test('shows the existing review back instead of a blank form', () async {
      final existing = const TripReview(
        bookingId: 'booking-1',
        officeRating: 5,
        driverRating: 5,
        vehicleRating: 4,
        routeRating: 3,
        comment: 'Great captain',
      );
      final cubit = _cubit(_FakeTripReviewsRepository(existing: existing));

      await cubit.load(_trip().reviewable);

      final state = cubit.state as TripReviewSubmitted;
      expect(state.review.driverRating, 5);
      expect(state.review.comment, 'Great captain');
    });
  });

  group('TripReviewCubit.submit', () {
    test('is refused until all four ratings are set', () async {
      final repo = _FakeTripReviewsRepository();
      final cubit = _cubit(repo);
      await cubit.load(_trip().reviewable);

      cubit.rateOffice(5);
      cubit.rateDriver(5);
      cubit.rateVehicle(4);
      // Route still unrated.
      expect((cubit.state as TripReviewEditing).canSubmit, isFalse);

      // The office is its own dimension, not a derived average: rating the driver,
      // vehicle and route still leaves the form incomplete without it.
      cubit.rateRoute(3);
      cubit.rateOffice(0);
      expect((cubit.state as TripReviewEditing).canSubmit, isFalse);

      await cubit.submit();

      expect(repo.submitted, isNull);
      expect(cubit.state, isA<TripReviewEditing>());
    });

    test('stores the review once every rating is given', () async {
      final repo = _FakeTripReviewsRepository();
      final cubit = _cubit(repo);
      await cubit.load(_trip().reviewable);

      cubit.rateOffice(5);
      cubit.rateDriver(5);
      cubit.rateVehicle(4);
      cubit.rateRoute(3);
      cubit.writeComment('Smooth ride');
      await cubit.submit();

      expect(repo.submitted?.officeRating, 5);
      expect(repo.submitted?.driverRating, 5);
      expect(repo.submitted?.vehicleRating, 4);
      expect(repo.submitted?.routeRating, 3);
      expect(repo.submitted?.comment, 'Smooth ride');
      expect(cubit.state, isA<TripReviewSubmitted>());
    });

    test(
      'a stored review is timestamped, not left looking unsubmitted',
      () async {
        final repo = _FakeTripReviewsRepository();
        final cubit = _cubit(repo);
        await cubit.load(_trip().reviewable);

        cubit.rateOffice(5);
        cubit.rateDriver(5);
        cubit.rateVehicle(5);
        cubit.rateRoute(5);
        await cubit.submit();

        // The entity documents submittedAt as null only until the review is
        // stored, so a submitted review must carry one.
        expect(
          (cubit.state as TripReviewSubmitted).review.submittedAt,
          isNotNull,
        );
      },
    );

    test('retrying a failed submit clears the previous error', () async {
      final repo = _FakeTripReviewsRepository(submitFails: true);
      final cubit = _cubit(repo);
      await cubit.load(_trip().reviewable);

      cubit.rateOffice(5);
      cubit.rateDriver(5);
      cubit.rateVehicle(5);
      cubit.rateRoute(5);
      await cubit.submit();
      expect((cubit.state as TripReviewEditing).error, isNotNull);

      repo.submitFails = false;
      await cubit.submit();

      expect(cubit.state, isA<TripReviewSubmitted>());
    });

    test('an unrelated edit does not silently drop a pending error', () async {
      final repo = _FakeTripReviewsRepository(submitFails: true);
      final cubit = _cubit(repo);
      await cubit.load(_trip().reviewable);

      cubit.rateOffice(5);
      cubit.rateDriver(5);
      cubit.rateVehicle(5);
      cubit.rateRoute(5);
      await cubit.submit();

      final failed = cubit.state as TripReviewEditing;
      expect(failed.error, isNotNull);

      // copyWith keeps an omitted field: only an explicit clearError drops it.
      expect(failed.copyWith(isSubmitting: true).error, failed.error);
      expect(failed.copyWith(clearError: true).error, isNull);
    });

    test('keeps the ratings on screen when the submit fails', () async {
      final repo = _FakeTripReviewsRepository(submitFails: true);
      final cubit = _cubit(repo);
      await cubit.load(_trip().reviewable);

      cubit.rateOffice(5);
      cubit.rateDriver(5);
      cubit.rateVehicle(5);
      cubit.rateRoute(5);
      await cubit.submit();

      final state = cubit.state as TripReviewEditing;
      // A bare exception from the repository is not a named review failure, so
      // the passenger is told something generic rather than shown Dart's text.
      expect(state.error, TripReviewFailure.unknown);
      expect(state.isSubmitting, isFalse);
      // The passenger does not have to re-enter what they already chose.
      expect(state.draft.driverRating, 5);
      expect(state.canSubmit, isTrue);
    });

    test('refuses to review a trip that has not been completed', () async {
      final repo = _FakeTripReviewsRepository();
      final cubit = _cubit(repo);
      await cubit.load(_trip(status: TripStatus.upcoming).reviewable);

      cubit.rateOffice(5);
      cubit.rateDriver(5);
      cubit.rateVehicle(5);
      cubit.rateRoute(5);
      await cubit.submit();

      expect(repo.submitted, isNull);
      expect(
        (cubit.state as TripReviewEditing).error,
        TripReviewFailure.tripNotCompleted,
      );
    });
  });
}
