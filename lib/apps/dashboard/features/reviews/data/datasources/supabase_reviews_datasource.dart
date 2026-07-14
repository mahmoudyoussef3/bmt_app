import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/trip_review_entry.dart';
import '../models/trip_review_entry_model.dart';
import 'reviews_datasource.dart';

class SupabaseReviewsDatasource implements ReviewsDatasource {
  const SupabaseReviewsDatasource(this._supabase);

  final SupabaseClient _supabase;

  static const String _columns = '''
    id, booking_id, booking_number, client_name, driver_id, driver_name,
    vehicle_name, route_label, driver_rating, vehicle_rating, route_rating,
    comment, created_at
  ''';

  @override
  Future<List<TripReviewEntry>> getReviews() async {
    final rows = await _supabase
        .from('trip_reviews')
        .select(_columns)
        .order('created_at', ascending: false);

    return rows.map((row) => TripReviewEntryModel(row).toEntity()).toList();
  }

  /// The Dashboard reads as the anon role (no login gate), which the
  /// `dashboard reads all reviews` policy allows. Passengers are limited to
  /// their own rows by a separate policy, so this full feed is operations-only.
  @override
  Stream<List<TripReviewEntry>> watchReviews() {
    return _supabase
        .from('trip_reviews')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map(
          (rows) =>
              rows.map((row) => TripReviewEntryModel(row).toEntity()).toList(),
        );
  }
}
