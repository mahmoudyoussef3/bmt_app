import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/session/dashboard_session.dart';
import '../../domain/entities/office_profile.dart';
import 'office_profile_datasource.dart';

/// Reads and writes the signed-in office's own row in `offices`.
///
/// The row is addressed by [DashboardSession.officeId] rather than by anything
/// typed in or carried through a route, and RLS
/// (`offices_operator_read` / `offices_operator_update`, migration
/// 20260721090200) independently restricts both statements to that same office
/// and, for the update, to the `dashboard_admin` role. Two boundaries, neither
/// relying on the other.
class SupabaseOfficeProfileDatasource implements OfficeProfileDatasource {
  const SupabaseOfficeProfileDatasource(this._client, this._session);

  final SupabaseClient _client;
  final DashboardSession _session;

  /// `join_code` and `join_code_rotated_at` are deliberately absent.
  ///
  /// Migration 20260721100200 revoked table-wide SELECT on `offices` and
  /// re-granted it column by column, leaving both of those out: a client and a
  /// dashboard operator are the same Postgres role, so column privileges are the
  /// only thing separating the code from the rest of the row. Naming them here
  /// does not read a hidden value — it makes the whole statement fail with
  /// "permission denied for table offices". The code is read through
  /// [_fetchJoinCode] instead, which is the path the migration prescribes.
  ///
  /// `listing_status` is readable here — migration 20260721140000 granted SELECT
  /// on that column while revoking UPDATE on it, which is the whole shape of the
  /// listing axis: an office may see why it is not on the marketplace and may
  /// not publish itself out of it.
  static const _columns =
      'id, name, slug, logo_url, description, phone, email, service_areas, '
      'status, listing_status, rating, ratings_count, created_at, updated_at';

  @override
  Future<OfficeProfile> getProfile() async {
    try {
      final row = await _client
          .from('offices')
          .select(_columns)
          .eq('id', _session.officeId)
          .maybeSingle();

      if (row == null) {
        // RLS returns an empty set rather than an error when the row is out of
        // reach, so "not found" here means the session points at an office the
        // operator can no longer read — a stale session, not a missing office.
        throw Exception(
          'تعذر قراءة بيانات المكتب. سجّل الخروج ثم الدخول مرة أخرى.',
        );
      }

      return _mapProfile(row, joinCode: await _fetchJoinCode());
    } on PostgrestException catch (error) {
      throw Exception(error.message);
    }
  }

  /// Reads the office's own join code through `office_join_code()`, which
  /// resolves the office from `current_office_id()` — there is no parameter to
  /// point at someone else's.
  ///
  /// A failure here is swallowed to an empty code on purpose: the join code is
  /// one card on a screen whose main job is the marketplace profile, and a
  /// support agent (whom the RPC serves, but whose office may be mid-change)
  /// losing that card is better than losing the whole screen.
  Future<String> _fetchJoinCode() async {
    try {
      final code = await _client.rpc('office_join_code');
      return code?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  @override
  Future<OfficeProfile> updateProfile(OfficeProfileEdit edit) async {
    try {
      // Only the six marketplace-facing columns are ever sent. status, rating,
      // ratings_count, slug and join_code are deliberately absent: RLS would
      // permit them, so this payload is what actually keeps them platform-owned.
      final row = await _client
          .from('offices')
          .update({
            'name': edit.name.trim(),
            'description': edit.description.trim(),
            'logo_url': _nullIfBlank(edit.logoUrl),
            'phone': _nullIfBlank(edit.phone),
            'email': _nullIfBlank(edit.email),
            'service_areas': [
              for (final area in edit.serviceAreas)
                if (area.trim().isNotEmpty) area.trim(),
            ],
          })
          .eq('id', _session.officeId)
          .select(_columns)
          .maybeSingle();

      if (row == null) {
        // An update filtered to an existing id that returns nothing was blocked
        // by the policy's USING clause — i.e. the operator is a support agent.
        throw Exception('لا تملك صلاحية تعديل بيانات المكتب.');
      }

      return _mapProfile(row, joinCode: await _fetchJoinCode());
    } on PostgrestException catch (error) {
      throw Exception(error.message);
    }
  }

  OfficeProfile _mapProfile(Map<String, dynamic> row, {required String joinCode}) {
    return OfficeProfile(
      id: row['id']?.toString() ?? '',
      name: row['name']?.toString() ?? '',
      slug: row['slug']?.toString() ?? '',
      description: row['description']?.toString() ?? '',
      serviceAreas: _toStringList(row['service_areas']),
      status: row['status']?.toString() ?? 'active',
      // Falls back to 'draft', not 'listed': if the column ever fails to come
      // back, the honest answer is "we cannot confirm you are visible" rather
      // than a badge telling the operator their office is on the marketplace.
      listingStatus: row['listing_status']?.toString() ?? 'draft',
      rating: _toDouble(row['rating']),
      ratingsCount: _toInt(row['ratings_count']),
      joinCode: joinCode,
      logoUrl: _nullIfBlank(row['logo_url']?.toString()),
      phone: _nullIfBlank(row['phone']?.toString()),
      email: _nullIfBlank(row['email']?.toString()),
      createdAt: _parseDate(row['created_at']),
      updatedAt: _parseDate(row['updated_at']),
    );
  }

  List<String> _toStringList(dynamic value) {
    if (value is List) {
      return [
        for (final item in value)
          if (item != null && item.toString().trim().isNotEmpty)
            item.toString().trim(),
      ];
    }
    return const [];
  }

  String? _nullIfBlank(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }
}
