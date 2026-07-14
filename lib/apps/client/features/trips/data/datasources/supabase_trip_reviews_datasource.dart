import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/trip_review.dart';
import '../models/trip_review_model.dart';
import 'trip_reviews_datasource.dart';

class SupabaseTripReviewsDatasource implements TripReviewsDatasource {
  const SupabaseTripReviewsDatasource(this._supabase);

  final SupabaseClient _supabase;

  /// RLS already limits a signed-in passenger to their own rows, so this needs
  /// no client filter — there is nothing else here for them to read.
  @override
  Future<TripReviewModel?> getReviewForBooking(String bookingId) async {
    if (_supabase.auth.currentUser == null) return null;

    final row = await _supabase
        .from('trip_reviews')
        .select('booking_id, driver_rating, vehicle_rating, route_rating, '
            'comment, created_at')
        .eq('booking_id', bookingId)
        .maybeSingle();

    return row == null ? null : TripReviewModel.fromJson(row);
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
      throw Exception(_errorMessage(error.message));
    }
  }

  String _errorMessage(String raw) {
    if (raw.contains('trip_not_completed')) {
      return 'You can only review a trip once it has been completed.';
    }
    if (raw.contains('booking_cancelled')) {
      return 'This booking was cancelled, so there is nothing to review.';
    }
    if (raw.contains('not_authorized')) {
      return 'You can only review your own trips.';
    }
    if (raw.contains('booking_not_found')) {
      return 'This booking no longer exists.';
    }
    if (raw.contains('invalid_rating')) {
      return 'Please give the driver, vehicle, and route 1–5 stars.';
    }
    if (raw.contains('not_authenticated')) {
      return 'Please sign in to review your trip.';
    }
    return 'Could not submit your review. Please try again.';
  }
}
