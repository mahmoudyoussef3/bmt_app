import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/profile_repository.dart';
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

    final results = await Future.wait([
      _queries.clientRow(user.id),
      _queries.activePackageRow(user.id),
      _queries.bookingCount(
        user.id,
        tripStatuses: ProfileQueries.completedTripStatuses,
      ),
      _queries.bookingCount(
        user.id,
        tripStatuses: ProfileQueries.upcomingTripStatuses,
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
      
      if (error.code == '23505') {
        throw Exception(
          'That phone number or email is already used by another account.',
        );
      }
      throw Exception('We could not save your details. Please try again.');
    }

    try {
      await _supabase.auth.updateUser(
        UserAttributes(data: {'full_name': name, 'phone': phone}),
      );
    } catch (_) {
      
    }

    return getProfile();
  }

  User _requireUser() {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw const ProfileUnauthenticatedException();
    }
    return user;
  }
}
