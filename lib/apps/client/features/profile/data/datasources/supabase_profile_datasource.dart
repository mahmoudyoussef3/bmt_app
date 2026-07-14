import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/client_profile_model.dart';
import 'profile_datasource.dart';
import 'profile_queries.dart';

class SupabaseProfileDatasource implements ProfileDatasource {
  SupabaseProfileDatasource(this._supabase)
    : _queries = ProfileQueries(_supabase);

  final SupabaseClient _supabase;
  final ProfileQueries _queries;

  @override
  Future<ClientProfileModel> getProfile() async {
    final user = _requireUser();
    final today = DateTime.now().toIso8601String().split('T').first;

    // The four reads are independent, so they go out together rather than
    // stacking four round-trips on a screen the rider is already looking at.
    final results = await Future.wait([
      _queries.clientRow(user.id),
      _queries.activePackageRow(user.id),
      _queries.bookingCount(
        user.id,
        statuses: ProfileQueries.completedStatuses,
      ),
      _queries.bookingCount(
        user.id,
        statuses: ProfileQueries.liveStatuses,
        fromDate: today,
      ),
    ]);

    return ClientProfileModel.fromRow(
      results[0] as Map<String, dynamic>?,
      userId: user.id,
      fallbackEmail: user.email,
      packageRow: results[1] as Map<String, dynamic>?,
      completedTrips: results[2] as int,
      upcomingTrips: results[3] as int,
    );
  }

  @override
  Future<ClientProfileModel> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    final user = _requireUser();

    try {
      await _queries.updateClientRow(
        user.id,
        name: name,
        email: email,
        phone: phone,
      );
    } on PostgrestException catch (error) {
      // 23505 is a unique-constraint violation: this phone or email already
      // belongs to another rider. That is theirs to fix, so it must reach them
      // as such rather than as a generic failure.
      if (error.code == '23505') {
        throw Exception(
          'That phone number or email is already used by another account.',
        );
      }
      throw Exception('We could not save your details. Please try again.');
    }

    // Keep the auth identity in step with the profile row: the session's
    // metadata is what greets the rider before the row is fetched.
    try {
      await _supabase.auth.updateUser(
        UserAttributes(data: {'full_name': name, 'phone': phone}),
      );
    } catch (_) {
      // Best-effort. The clients row — the hub's source of truth — is already
      // saved, so a metadata hiccup must not fail the edit.
    }

    return getProfile();
  }

  User _requireUser() {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Please sign in to view your profile.');
    }
    return user;
  }
}
