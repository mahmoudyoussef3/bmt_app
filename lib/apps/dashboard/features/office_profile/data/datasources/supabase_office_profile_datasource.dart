import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/entitlements/licensing_guard.dart';
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
        throw Exception(
          'تعذر قراءة بيانات المكتب. سجّل الخروج ثم الدخول مرة أخرى.',
        );
      }

      return _mapProfile(row, joinCode: await _fetchJoinCode());
    } on PostgrestException catch (error) {
      throw Exception(error.message);
    }
  }

  /// The office's own join code and, when the database can say so, when it was
  /// last rotated.
  ///
  /// Both readers resolve the office from `current_office_id()` — neither takes
  /// a parameter that could point at someone else's. `office_join_code_info()`
  /// (migration 20260830090000) is tried first because the rotation time is
  /// behind the same column-privilege revoke as the code itself; an office
  /// running against a database without that function falls back to
  /// `office_join_code()` and simply does not learn the date.
  ///
  /// A failure of both is reported as [_JoinCode.failed] rather than as an empty
  /// code: the join code is one card on a screen whose main job is the
  /// marketplace profile, so losing it must not lose the screen — but "we could
  /// not read it" and "no code has been issued" are different sentences and the
  /// card says whichever is true.
  Future<_JoinCode> _fetchJoinCode() async {
    try {
      final info = await _client.rpc('office_join_code_info');
      if (info is Map) {
        return _JoinCode(
          code: info['code']?.toString() ?? '',
          rotatedAt: _parseDate(info['rotated_at']),
        );
      }
    } catch (_) {
      // Falls through to the older reader below.
    }

    try {
      final code = await _client.rpc('office_join_code');
      return _JoinCode(code: code?.toString() ?? '');
    } catch (_) {
      return const _JoinCode(code: '', failed: true);
    }
  }

  /// Issues a new code through `office_rotate_join_code()`, which loops until
  /// the value is unique platform-wide and stamps `join_code_rotated_at` — work
  /// that cannot be done from an update statement the dashboard composes, which
  /// is why the RPC exists.
  ///
  /// The row is re-read afterwards instead of patching the new code into the
  /// entity in memory: the office as the database now holds it is the only
  /// version worth showing after a credential change.
  @override
  Future<OfficeProfile> rotateJoinCode() async {
    try {
      await _client.rpc('office_rotate_join_code');
    } on PostgrestException catch (error) {
      throw Exception(_rotateMessage(error));
    }
    return getProfile();
  }

  /// The RPC raises bare condition names (`dashboard_admin_required`,
  /// `not_an_office_user`); an operator reads them as noise, so they are named
  /// in the words of the screen they happened on.
  String _rotateMessage(PostgrestException error) {
    final raw = error.message;
    if (raw.contains('dashboard_admin_required')) {
      return 'تدوير كود الانضمام متاح لحساب المالك فقط.';
    }
    if (raw.contains('not_an_office_user')) {
      return 'تعذر تحديد المكتب. سجّل الخروج ثم الدخول مرة أخرى.';
    }
    return raw;
  }

  @override
  Future<OfficeProfile> updateProfile(OfficeProfileEdit edit) async {
    try {
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
        throw Exception('لا تملك صلاحية تعديل بيانات المكتب.');
      }

      return _mapProfile(row, joinCode: await _fetchJoinCode());
    } on PostgrestException catch (error) {
      throw Exception(error.message);
    }
  }

  /// The bucket provisioned by migration 20260801090000: public to read, and
  /// writable only by the office's own owner inside a folder named for the
  /// office id.
  static const _logoBucket = 'office-logos';

  @override
  Future<String> uploadLogo({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final path =
        '${_session.officeId}/'
        '${DateTime.now().millisecondsSinceEpoch}-${_safeFileName(fileName)}';

    try {
      await _client.storage
          .from(_logoBucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: _contentType(fileName)),
          );

      return _client.storage.from(_logoBucket).getPublicUrl(path);
    } on StorageException catch (error) {
      LicensingGuard.check(error);
      throw Exception(error.message);
    }
  }

  /// Storage object keys are URL path segments, so Arabic filenames and spaces —
  /// both routine on an operator's machine — have to be reduced to a safe slug
  /// before they become part of a public URL.
  String _safeFileName(String input) {
    final extension = _extension(input);
    final base = extension.isEmpty
        ? input
        : input.substring(0, input.length - extension.length - 1);

    final slug = base
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_\-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    return '${slug.isEmpty ? 'logo' : slug}'
        '${extension.isEmpty ? '' : '.$extension'}';
  }

  String _extension(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0 || dot == fileName.length - 1) return '';
    return fileName.substring(dot + 1).toLowerCase();
  }

  /// Sent explicitly: the bucket restricts `allowed_mime_types` to the three
  /// image types, and a default of `application/octet-stream` is rejected by
  /// that check rather than by anything the operator could act on.
  String _contentType(String fileName) => switch (_extension(fileName)) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => 'image/jpeg',
  };

  OfficeProfile _mapProfile(
    Map<String, dynamic> row, {
    required _JoinCode joinCode,
  }) {
    return OfficeProfile(
      id: row['id']?.toString() ?? '',
      name: row['name']?.toString() ?? '',
      slug: row['slug']?.toString() ?? '',
      description: row['description']?.toString() ?? '',
      serviceAreas: _toStringList(row['service_areas']),
      status: row['status']?.toString() ?? 'active',

      listingStatus: row['listing_status']?.toString() ?? 'draft',
      rating: _toDouble(row['rating']),
      ratingsCount: _toInt(row['ratings_count']),
      joinCode: joinCode.code,
      joinCodeReadFailed: joinCode.failed,
      joinCodeRotatedAt: joinCode.rotatedAt,
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

/// What the join-code readers could establish: the code, when it last changed,
/// and whether the read succeeded at all.
class _JoinCode {
  const _JoinCode({required this.code, this.rotatedAt, this.failed = false});

  final String code;
  final DateTime? rotatedAt;
  final bool failed;
}
