import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/trip_review.dart';
import '../../domain/entities/trip_review_failure.dart';
import '../mappers/trip_review_failure_mapper.dart';
import '../models/trip_review_model.dart';
import 'trip_reviews_datasource.dart';

class SupabaseTripReviewsDatasource implements TripReviewsDatasource {
  const SupabaseTripReviewsDatasource(this._supabase);

  final SupabaseClient _supabase;

  /// Reads the caller's own review.
  ///
  /// The signed-in check is a privacy guard, not a convenience: `trip_reviews`
  /// grants `select` to `anon` so the Dashboard (which has no login gate) can
  /// read the queue, so an unauthenticated caller here would read *everyone's*
  /// reviews. Signed in, RLS narrows the table to the caller's own rows and no
  /// client-side filter is needed.
  @override
  Future<TripReviewModel?> getReviewForBooking(String bookingId) async {
    if (_supabase.auth.currentUser == null) {
      throw const TripReviewException(TripReviewFailure.notAuthenticated);
    }

    try {
      final row = await _supabase
          .from('trip_reviews')
          .select(
            'booking_id, driver_rating, vehicle_rating, route_rating, '
            'comment, created_at',
          )
          .eq('booking_id', bookingId)
          .maybeSingle();

      return row == null ? null : TripReviewModel.fromJson(row);
    } on PostgrestException catch (error) {
      throw TripReviewException(
        TripReviewFailureMapper.fromMessage(error.message),
        details: error,
      );
    }
  }

  /// The RPC — not this call — decides whether the review is allowed: it checks
  /// the booking is the caller's, the trip actually finished, and that a second
  /// submission amends the first rather than duplicating it.
  @override
  Future<void> submitReview(TripReview review) async {
    try {
      await _supabase.rpc(
        'submit_trip_review',
        params: {
          'p_booking_id': review.bookingId,
          'p_driver_rating': review.driverRating,
          'p_vehicle_rating': review.vehicleRating,
          'p_route_rating': review.routeRating,
          'p_comment': review.comment.trim(),
        },
      );
    } on PostgrestException catch (error) {
      throw TripReviewException(
        TripReviewFailureMapper.fromMessage(error.message),
        details: error,
      );
    }
  }
}
