import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/office_onboarding.dart';
import '../../domain/entities/platform_analytics.dart';
import '../../domain/entities/platform_office.dart';
import '../../domain/entities/platform_office_details.dart';
import 'platform_admin_datasource.dart';

/// The platform administration surface.
///
/// Four of the five calls are plain RPCs — `platform_list_offices`,
/// `platform_office_details`, `platform_set_office_listing`,
/// `platform_set_office_status` — each of which re-checks `is_platform_admin()`
/// server-side under this session's own JWT. There is no office parameter to
/// tamper with beyond the id, and an office id alone grants nothing without the
/// platform-admin identity behind it.
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
        for (final row in rows)
          _mapOffice(Map<String, dynamic>.from(row as Map)),
      ];
    } on PostgrestException catch (error) {
      throw Exception(_messageForCode(error.message));
    }
  }

  @override
  Future<PlatformAnalytics> getAnalytics({int windowDays = 30}) async {
    try {
      final row = await _client.rpc(
        'platform_office_analytics',
        params: {'p_window_days': windowDays},
      );
      if (row is! Map) {
        throw Exception('تعذر قراءة تحليلات المنصة.');
      }
      return _mapAnalytics(Map<String, dynamic>.from(row));
    } on PostgrestException catch (error) {
      throw Exception(_messageForCode(error.message));
    }
  }

  @override
  Future<PlatformOfficeDetails> getOfficeDetails(String officeId) async {
    try {
      final row = await _client.rpc(
        'platform_office_details',
        params: {'p_office_id': officeId},
      );
      if (row is! Map) {
        throw Exception('تعذر قراءة بيانات المكتب.');
      }
      return _mapDetails(Map<String, dynamic>.from(row));
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
      username:
          data['login_username']?.toString() ??
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
      vehicles: _toInt(row['vehicles']),
      trips: _toInt(row['trips']),
      ownerName: _nullIfBlank(row['owner_name']?.toString()),
      ownerUsername: _nullIfBlank(row['owner_username']?.toString()),
      logoUrl: _nullIfBlank(row['logo_url']?.toString()),
      phone: _nullIfBlank(row['phone']?.toString()),
      email: _nullIfBlank(row['email']?.toString()),
      listedAt: _parseDate(row['listed_at']),
      createdAt: _parseDate(row['created_at']),
      updatedAt: _parseDate(row['updated_at']),
    );
  }

  /// `platform_office_details` returns one jsonb document rather than a row, so
  /// the office identity is read with the same [_mapOffice] the list uses — the
  /// key names are identical on purpose, and the counts it reads for the card
  /// live at the top level of that document too.
  PlatformOfficeDetails _mapDetails(Map<String, dynamic> row) {
    final counts = row['counts'] is Map
        ? Map<String, dynamic>.from(row['counts'] as Map)
        : const <String, dynamic>{};

    // The list card's own count fields are flattened in from `counts`, so an
    // office rendered from a details payload and one rendered from the list are
    // the same object with the same numbers on it.
    final office = _mapOffice({
      ...row,
      'operators': counts['operators'],
      'drivers': counts['drivers'],
      'routes': counts['routes'],
      'vehicles': counts['vehicles'],
      'trips': counts['trips'],
    });

    final marketplace = row['marketplace'];

    return PlatformOfficeDetails(
      office: office,
      counts: PlatformOfficeCounts(
        operators: _toInt(counts['operators']),
        drivers: _toInt(counts['drivers']),
        vehicles: _toInt(counts['vehicles']),
        routes: _toInt(counts['routes']),
        trips: _toInt(counts['trips']),
        bookings: _toInt(counts['bookings']),
        reviews: _toInt(counts['reviews']),
      ),
      operators: [
        if (row['operators'] is List)
          for (final item in row['operators'] as List)
            if (item is Map) _mapOperator(Map<String, dynamic>.from(item)),
      ],
      // Absent when the office is not on the marketplace. Kept null rather than
      // defaulted, because "a passenger sees nothing" is the information.
      marketplace: marketplace is Map
          ? _mapMarketplace(Map<String, dynamic>.from(marketplace))
          : null,
    );
  }

  /// `platform_office_analytics` returns one jsonb document: a totals object, a
  /// day-by-day trend array, and one entry per office. The office entries are
  /// keyed by id here rather than kept as a list, because every consumer looks
  /// them up by the office they are already rendering.
  PlatformAnalytics _mapAnalytics(Map<String, dynamic> row) {
    final totals = row['totals'] is Map
        ? Map<String, dynamic>.from(row['totals'] as Map)
        : const <String, dynamic>{};

    return PlatformAnalytics(
      windowDays: _toInt(row['window_days']) == 0
          ? 30
          : _toInt(row['window_days']),
      generatedAt: _parseDate(row['generated_at']),
      totals: PlatformTotals(
        offices: _toInt(totals['offices']),
        active: _toInt(totals['active']),
        paused: _toInt(totals['paused']),
        suspended: _toInt(totals['suspended']),
        archived: _toInt(totals['archived']),
        listed: _toInt(totals['listed']),
        draft: _toInt(totals['draft']),
        unlisted: _toInt(totals['unlisted']),
        trading: _toInt(totals['trading']),
        idle: _toInt(totals['idle']),
        neverTraded: _toInt(totals['never_traded']),
        onboardedInWindow: _toInt(totals['onboarded_in_window']),
        withoutAdmin: _toInt(totals['without_admin']),
        listedWithoutTrips: _toInt(totals['listed_without_trips']),
        tripsTotal: _toInt(totals['trips_total']),
        tripsRecent: _toInt(totals['trips_recent']),
        tripsUpcoming: _toInt(totals['trips_upcoming']),
        tripsStale: _toInt(totals['trips_stale']),
        bookingsTotal: _toInt(totals['bookings_total']),
        bookingsRecent: _toInt(totals['bookings_recent']),
        revenueTotal: _toDouble(totals['revenue_total']),
        revenueRecent: _toDouble(totals['revenue_recent']),
        paymentsAwaitingReview: _toInt(totals['payments_awaiting_review']),
        paymentsAwaitingAmount: _toDouble(totals['payments_awaiting_amount']),
        ticketsOpen: _toInt(totals['tickets_open']),
        captainRequestsPending: _toInt(totals['captain_requests_pending']),
        seatsOffered: _toInt(totals['seats_offered']),
        seatsSold: _toInt(totals['seats_sold']),
      ),
      trend: [
        if (row['trend'] is List)
          for (final item in row['trend'] as List)
            if (item is Map) _mapTrendPoint(Map<String, dynamic>.from(item)),
      ],
      offices: {
        for (final metrics in [
          if (row['offices'] is List)
            for (final item in row['offices'] as List)
              if (item is Map) _mapMetrics(Map<String, dynamic>.from(item)),
        ])
          metrics.officeId: metrics,
      },
    );
  }

  PlatformTrendPoint _mapTrendPoint(Map<String, dynamic> row) {
    return PlatformTrendPoint(
      // A `date` column, so it arrives without a time. Parsed as-is rather than
      // localised: shifting a calendar day by a timezone offset would move a
      // day's bookings onto the day before it.
      day: DateTime.tryParse(row['day']?.toString() ?? '') ?? DateTime.now(),
      bookings: _toInt(row['bookings']),
      revenue: _toDouble(row['revenue']),
    );
  }

  PlatformOfficeMetrics _mapMetrics(Map<String, dynamic> row) {
    return PlatformOfficeMetrics(
      officeId: row['office_id']?.toString() ?? '',
      totalTrips: _toInt(row['trips_total']),
      recentTrips: _toInt(row['trips_recent']),
      upcomingTrips: _toInt(row['trips_upcoming']),
      staleTrips: _toInt(row['trips_stale']),
      completedTrips: _toInt(row['trips_completed']),
      cancelledTrips: _toInt(row['trips_cancelled']),
      totalBookings: _toInt(row['bookings_total']),
      recentBookings: _toInt(row['bookings_recent']),
      confirmedBookings: _toInt(row['bookings_confirmed']),
      cancelledBookings: _toInt(row['bookings_cancelled']),
      recentCancelledBookings: _toInt(row['bookings_cancelled_recent']),
      revenueTotal: _toDouble(row['revenue_total']),
      revenueRecent: _toDouble(row['revenue_recent']),
      paymentsAwaitingReview: _toInt(row['payments_awaiting_review']),
      paymentsAwaitingAmount: _toDouble(row['payments_awaiting_amount']),
      paymentsRejected: _toInt(row['payments_rejected']),
      seatsOffered: _toInt(row['seats_offered']),
      seatsSold: _toInt(row['seats_sold']),
      ticketsTotal: _toInt(row['tickets_total']),
      openTickets: _toInt(row['tickets_open']),
      recentTickets: _toInt(row['tickets_recent']),
      pendingCaptainRequests: _toInt(row['captain_requests_pending']),
      reviewsTotal: _toInt(row['reviews_total']),
      recentReviews: _toInt(row['reviews_recent']),
      activeOperators: _toInt(row['active_operators']),
      activeAdmins: _toInt(row['active_admins']),
      // Null when the office has no rated reviews. Kept null rather than
      // defaulted to 0, which would read as "rated one star".
      averageRating: row['avg_office_rating'] == null
          ? null
          : _toDouble(row['avg_office_rating']),
      lastTripDate: _parseDate(row['last_trip_date']),
      firstBookingAt: _parseDate(row['first_booking_at']),
      lastBookingAt: _parseDate(row['last_booking_at']),
    );
  }

  PlatformOfficeOperator _mapOperator(Map<String, dynamic> row) {
    return PlatformOfficeOperator(
      username: row['username']?.toString() ?? '',
      fullName: row['full_name']?.toString() ?? '',
      role: row['role']?.toString() ?? 'support_agent',
      status: row['status']?.toString() ?? 'active',
      createdAt: _parseDate(row['created_at']),
    );
  }

  PlatformOfficeMarketplacePreview _mapMarketplace(Map<String, dynamic> row) {
    return PlatformOfficeMarketplacePreview(
      name: row['name']?.toString() ?? '',
      slug: row['slug']?.toString() ?? '',
      description: row['description']?.toString() ?? '',
      serviceAreas: _toStringList(row['service_areas']),
      rating: _toDouble(row['rating']),
      ratingsCount: _toInt(row['ratings_count']),
      logoUrl: _nullIfBlank(row['logo_url']?.toString()),
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
