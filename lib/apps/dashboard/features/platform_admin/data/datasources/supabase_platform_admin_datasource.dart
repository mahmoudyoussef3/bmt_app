import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/office_onboarding.dart';
import '../../domain/entities/platform_office.dart';
import 'platform_admin_datasource.dart';

/// The platform administration surface.
///
/// Three of the four calls are plain RPCs — `platform_list_offices`,
/// `platform_set_office_listing`, `platform_set_office_status` — each of which
/// re-checks `is_platform_admin()` server-side under this session's own JWT.
/// There is no office parameter to tamper with beyond the id, and an office id
/// alone grants nothing without the platform-admin identity behind it.
///
/// Onboarding goes through an Edge Function instead, for one reason: creating
/// the `auth.users` row needs the Supabase Auth Admin API, which needs the
/// service-role key, which must never exist in a Flutter binary. The function
/// holds that key; the office data it creates is still written by
/// `platform_create_office` under the *caller's* JWT, so the Dashboard cannot
/// obtain any authority through it that it does not already have.
class SupabasePlatformAdminDatasource implements PlatformAdminDatasource {
  const SupabasePlatformAdminDatasource(this._client);

  final SupabaseClient _client;

  static const _onboardFunction = 'platform-create-office';

  @override
  Future<List<PlatformOffice>> getOffices() async {
    try {
      final rows = await _client.rpc('platform_list_offices') as List;
      return [
        for (final row in rows) _mapOffice(Map<String, dynamic>.from(row as Map)),
      ];
    } on PostgrestException catch (error) {
      throw Exception(_messageForCode(error.message));
    }
  }

  @override
  Future<OfficeOnboardingResult> onboardOffice(
    OfficeOnboardingRequest request,
  ) async {
    final FunctionResponse response;
    try {
      response = await _client.functions.invoke(
        _onboardFunction,
        body: request.toPayload(),
      );
    } on FunctionException catch (error) {
      // Non-2xx responses arrive here with the parsed body attached, which is
      // where the machine-readable error code lives.
      throw Exception(_messageForCode(_codeFromBody(error.details)));
    } catch (_) {
      throw Exception('تعذر الاتصال بالخادم. تحقق من الشبكة وحاول مرة أخرى.');
    }

    final data = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : <String, dynamic>{};

    final error = data['error']?.toString().trim() ?? '';
    if (error.isNotEmpty) {
      throw Exception(_messageForCode(error));
    }

    final office = data['office'] is Map
        ? Map<String, dynamic>.from(data['office'] as Map)
        : <String, dynamic>{};
    final officeId = office['office_id']?.toString() ?? '';
    if (officeId.isEmpty) {
      throw Exception('تم إنشاء الطلب لكن لم تصل بيانات المكتب. حدّث القائمة.');
    }

    return OfficeOnboardingResult(
      officeId: officeId,
      officeName: office['name']?.toString() ?? '',
      slug: office['slug']?.toString() ?? '',
      joinCode: office['join_code']?.toString() ?? '',
      username: data['login_username']?.toString() ??
          office['username']?.toString() ??
          '',
      listingStatus: office['listing_status']?.toString() ?? 'draft',
      // Present only when the server generated it. Held in memory for the one
      // screen that reveals it and never written anywhere.
      temporaryPassword: _nullIfBlank(data['temporary_password']?.toString()),
    );
  }

  @override
  Future<void> setListingStatus(String officeId, String listingStatus) async {
    try {
      await _client.rpc(
        'platform_set_office_listing',
        params: {'p_office_id': officeId, 'p_listing_status': listingStatus},
      );
    } on PostgrestException catch (error) {
      throw Exception(_messageForCode(error.message));
    }
  }

  @override
  Future<void> setOfficeStatus(String officeId, String status) async {
    try {
      await _client.rpc(
        'platform_set_office_status',
        params: {'p_office_id': officeId, 'p_status': status},
      );
    } on PostgrestException catch (error) {
      throw Exception(_messageForCode(error.message));
    }
  }

  /// Pulls the bare error code out of an Edge Function error body.
  String _codeFromBody(dynamic details) {
    if (details is Map) {
      final code = details['error']?.toString().trim() ?? '';
      if (code.isNotEmpty) return code;
    }
    return details?.toString() ?? '';
  }

  /// Server errors are machine codes by design — `raise exception 'slug_taken'`
  /// and the Edge Function's own vocabulary — so the Arabic text lives here,
  /// once, rather than being duplicated across a SQL function and a Deno file
  /// that neither can localise.
  String _messageForCode(String raw) {
    final code = raw.trim();
    if (code.contains('platform_admin_required')) {
      return 'هذه العملية متاحة لمسؤولي المنصة فقط.';
    }
    if (code.contains('not_authenticated')) {
      return 'انتهت الجلسة. سجّل الدخول مرة أخرى.';
    }
    if (code.contains('slug_taken')) {
      return 'المعرّف المختصر مستخدم بالفعل لمكتب آخر.';
    }
    if (code.contains('username_taken')) {
      return 'اسم الدخول مستخدم بالفعل. اختر اسماً آخر.';
    }
    if (code.contains('admin_user_already_assigned')) {
      return 'هذا الحساب مرتبط بمكتب آخر بالفعل.';
    }
    if (code.contains('invalid_username')) {
      return 'اسم الدخول غير صالح.';
    }
    if (code.contains('invalid_slug')) {
      return 'المعرّف المختصر غير صالح.';
    }
    if (code.contains('invalid_office_name') ||
        code.contains('office_name_too_long')) {
      return 'اسم المكتب غير صالح.';
    }
    if (code.contains('invalid_logo_url')) {
      return 'رابط الشعار يجب أن يبدأ بـ https://';
    }
    if (code.contains('invalid_email')) {
      return 'البريد الإلكتروني غير صالح.';
    }
    if (code.contains('invalid_phone')) {
      return 'رقم الهاتف غير صالح.';
    }
    if (code.contains('description_too_long')) {
      return 'وصف المكتب طويل جداً.';
    }
    if (code.contains('too_many_service_areas') ||
        code.contains('invalid_service_area')) {
      return 'مناطق الخدمة غير صالحة.';
    }
    if (code.contains('weak_password')) {
      return 'كلمة المرور قصيرة جداً (10 أحرف على الأقل).';
    }
    if (code.contains('office_profile_incomplete')) {
      return 'أكمل وصف المكتب ومناطق الخدمة قبل عرضه في السوق.';
    }
    if (code.contains('office_not_active')) {
      return 'لا يمكن عرض مكتب غير نشط في السوق.';
    }
    if (code.contains('office_not_found')) {
      return 'المكتب غير موجود.';
    }
    if (code.contains('auth_user_creation_failed')) {
      return 'تعذر إنشاء حساب المسؤول. حاول مرة أخرى.';
    }
    if (code.contains('join_code_generation_failed')) {
      return 'تعذر توليد كود انضمام فريد. حاول مرة أخرى.';
    }
    if (code.isEmpty || code.contains('onboarding_failed')) {
      return 'تعذر إنشاء المكتب. حاول مرة أخرى.';
    }
    return 'تعذر إتمام العملية ($code)';
  }

  PlatformOffice _mapOffice(Map<String, dynamic> row) {
    return PlatformOffice(
      id: row['id']?.toString() ?? '',
      name: row['name']?.toString() ?? '',
      slug: row['slug']?.toString() ?? '',
      description: row['description']?.toString() ?? '',
      serviceAreas: _toStringList(row['service_areas']),
      status: row['status']?.toString() ?? 'active',
      listingStatus: row['listing_status']?.toString() ?? 'listed',
      rating: _toDouble(row['rating']),
      ratingsCount: _toInt(row['ratings_count']),
      operators: _toInt(row['operators']),
      drivers: _toInt(row['drivers']),
      routes: _toInt(row['routes']),
      logoUrl: _nullIfBlank(row['logo_url']?.toString()),
      phone: _nullIfBlank(row['phone']?.toString()),
      email: _nullIfBlank(row['email']?.toString()),
      listedAt: _parseDate(row['listed_at']),
      createdAt: _parseDate(row['created_at']),
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
