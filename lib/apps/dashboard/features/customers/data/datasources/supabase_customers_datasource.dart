import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/entitlements/licensing_guard.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_activity.dart';
import '../../domain/entities/customer_filters.dart';
import '../../domain/entities/customer_payment.dart';
import '../../domain/entities/customer_profile.dart';
import '../../domain/entities/customer_subscription.dart';
import '../../domain/entities/customer_trip.dart';
import '../models/customer_models.dart';
import 'customers_datasource.dart';

/// Every العملاء read, over the RPC surface.
///
/// ## Why nothing here is a table read
///
/// A customer is assembled from six office-scoped tables plus `clients`, which
/// carries no office id at all. Doing that join from Dart would mean fetching
/// every booking, payment and subscription the office has ever taken in order to
/// render twelve rows — the exact cost `DashboardQueryCaps` exists to refuse —
/// and it would have to re-derive the "is this my customer" predicate that
/// `office_owns_client` already states once.
///
/// ## Why the office id is never sent
///
/// Every RPC resolves the office from `current_office_id()` server-side and
/// refuses to accept one as a parameter. There is therefore no office id to get
/// wrong, and no cross-office request this class is capable of making — a
/// client id belonging to another office comes back as `not_authorized`, not as
/// data.
class SupabaseCustomersDatasource implements CustomersDatasource {
  final SupabaseClient _client;

  const SupabaseCustomersDatasource(this._client);

  @override
  Future<CustomersOverview> fetchOverview() async {
    try {
      final json = await _client.rpc('office_customers_overview');
      return CustomerMapper.overview(json as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<CustomerDirectoryPage> fetchDirectory({
    required CustomerFilters filters,
    required int limit,
    required int offset,
  }) async {
    try {
      final search = filters.search.trim();
      final json = await _client.rpc(
        'office_customer_directory',
        params: {
          'p_search': search.isEmpty ? null : search,
          'p_subscription': filters.subscription.wire,
          'p_upcoming': filters.upcoming.wire,
          'p_activity': filters.activity.wire,
          'p_status': filters.status,
          'p_sort': filters.sort.wire,
          'p_limit': limit,
          'p_offset': offset,
        },
      );
      return CustomerMapper.directory(json as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<CustomerProfile> fetchProfile(String clientId) async {
    try {
      final json = await _client.rpc(
        'office_customer_profile',
        params: {'p_client_id': clientId},
      );
      return CustomerMapper.profile(json as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<CustomerTripsPage> fetchTrips(
    String clientId, {
    required bool upcoming,
    required int limit,
    required int offset,
  }) async {
    try {
      final json = await _client.rpc(
        'office_customer_trips',
        params: {
          'p_client_id': clientId,
          'p_scope': upcoming ? 'upcoming' : 'past',
          'p_limit': limit,
          'p_offset': offset,
        },
      );
      return CustomerMapper.trips(json as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<CustomerSubscription>> fetchSubscriptions(String clientId) async {
    try {
      final json = await _client.rpc(
        'office_customer_subscriptions',
        params: {'p_client_id': clientId},
      );
      return (json as List)
          .whereType<Map>()
          .map(
            (row) => CustomerMapper.subscription(row.cast<String, dynamic>()),
          )
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<CustomerPaymentsPage> fetchPayments(
    String clientId, {
    required int limit,
    required int offset,
  }) async {
    try {
      final json = await _client.rpc(
        'office_customer_payments',
        params: {'p_client_id': clientId, 'p_limit': limit, 'p_offset': offset},
      );
      return CustomerMapper.payments(json as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<CustomerActivityEvent>> fetchActivity(String clientId) async {
    try {
      final json = await _client.rpc(
        'office_customer_activity',
        params: {'p_client_id': clientId},
      );
      return CustomerMapper.activity(json);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// The machine codes the customer RPCs raise, as the sentence an operator can
  /// act on. `not_authorized` is the one that matters: it is what a client id
  /// belonging to another office comes back as, and "هذا العميل لا يتبع مكتبك"
  /// tells the operator they are looking at the wrong record rather than that
  /// the console is broken.
  static const _messages = <String, String>{
    'not_an_office_user': 'هذا الحساب غير مرتبط بمكتب.',
    'not_authorized':
        'هذا العميل لا يتبع مكتبك، أو لا تملك صلاحية عرض العملاء.',
    'client_not_found': 'لم يعد هذا العميل موجوداً.',
  };

  /// `LicensingGuard.check` runs first, as it does in every datasource: a
  /// plan-limit refusal is not a database error and must leave as a
  /// `LicensingFailure` so the shell can raise the upgrade card rather than
  /// showing an operator a stack of Postgres text.
  Exception _handleError(dynamic error) {
    LicensingGuard.check(error);

    if (error is PostgrestException) {
      final message = error.message;
      final translated = _messages.entries
          .where((entry) => message.contains(entry.key))
          .map((entry) => entry.value)
          .firstOrNull;
      if (translated != null) return Exception(translated);
      return Exception('خطأ بقاعدة البيانات: $message');
    }
    return Exception(error.toString());
  }
}
