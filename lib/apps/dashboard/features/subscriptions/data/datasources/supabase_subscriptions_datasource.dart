import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/session/dashboard_session.dart';
import '../../domain/entities/user_subscription.dart';
import '../models/user_subscription_model.dart';
import 'subscriptions_datasource.dart';

class SupabaseSubscriptionsDatasource implements SubscriptionsDatasource {
  final SupabaseClient _client;
  final DashboardSession _session;

  const SupabaseSubscriptionsDatasource(this._client, this._session);

  // Join packages to recover title + days for renewals, even on old rows.
  static const _select = '''
    *,
    client:clients(full_name, phone),
    package:packages(id, title, days, trips_count)
  ''';

  @override
  Future<List<UserSubscription>> fetchSubscriptions() async {
    await _client.rpc('office_expire_overdue_subscriptions');
    final rows = await _client
        .from('subscriptions')
        .select(_select)
        .order('created_at', ascending: false);
    return rows.map((r) => _fromRow(r)).toList();
  }

  @override
  Future<UserSubscription> fetchSubscriptionDetails(String id) async {
    await _client.rpc('office_expire_overdue_subscriptions');
    final row = await _client
        .from('subscriptions')
        .select(_select)
        .eq('id', id)
        .single();
    return _fromRow(row);
  }

  @override
  Future<UserSubscription> createSubscription(
    UserSubscription subscription,
  ) async {
    final payload = <String, dynamic>{
      'office_id': _session.officeId,
      if (subscription.userId.isNotEmpty) 'client_id': subscription.userId,
      'customer_name': subscription.userName,
      'customer_phone': subscription.userPhone,
      // routeId is repurposed to carry the package_id from the cubit.
      if (subscription.routeId.isNotEmpty) 'package_id': subscription.routeId,
      'package_name': subscription.routeName,
      // Persist the route the subscriber signed up for; fall back to the
      // package name only if no route was chosen.
      'route_name': subscription.routeLabel.isNotEmpty
          ? subscription.routeLabel
          : subscription.routeName,
      'start_date': subscription.startDate.toIso8601String(),
      'end_date': subscription.endDate.toIso8601String(),
      'status': 'pending_payment',
      'total_price': subscription.price,
      'paid_amount': 0,
      'remaining_amount': subscription.price,
      'trips_count': subscription.totalRides,
      'trips_used': 0,
    };
    final row = await _client
        .from('subscriptions')
        .insert(payload)
        .select(_select)
        .single();
    return _fromRow(row);
  }

  @override
  Future<UserSubscription> cancelSubscription(String id) async {
    final row = await _client
        .from('subscriptions')
        .update({'status': 'cancelled'})
        .eq('id', id)
        .select(_select)
        .single();
    return _fromRow(row);
  }

  @override
  Future<UserSubscription> renewSubscription(String id) async {
    final created = await _client.rpc(
      'office_request_subscription_renewal',
      params: {'p_subscription_id': id},
    );
    final createdId = (created as Map<String, dynamic>)['id'].toString();
    final row = await _client
        .from('subscriptions')
        .select(_select)
        .eq('id', createdId)
        .single();
    return _fromRow(row);
  }

  @override
  Future<UserSubscription> markRideUsed(String id) async {
    await _client.rpc(
      'office_consume_subscription_ride',
      params: {'p_subscription_id': id},
    );
    final updated = await _client
        .from('subscriptions')
        .select(_select)
        .eq('id', id)
        .single();
    return _fromRow(updated);
  }

  @override
  Future<UserSubscription> confirmPayment(String id) async {
    await _client.rpc(
      'office_confirm_subscription_payment',
      params: {'p_subscription_id': id},
    );
    final row = await _client
        .from('subscriptions')
        .select(_select)
        .eq('id', id)
        .single();
    return _fromRow(row);
  }

  @override
  Future<SubscriptionCreationOptions> fetchCreationOptions() async {
    final clients = await _client
        .from('clients')
        .select('id, full_name, phone')
        .order('full_name')
        .limit(200);
    final packages = await _client
        .from('packages')
        .select('id, title, price, days, trips_count, status')
        .neq('status', 'archived')
        .order('price');
    final routes = await _client
        .from('routes')
        .select('id, pickup, destination, status')
        .neq('status', 'archived')
        .order('pickup');

    final users = (clients as List).map((c) {
      final m = c as Map<String, dynamic>;
      return SubscriptionUserOption(
        id: m['id'].toString(),
        name: m['full_name']?.toString() ?? 'عميل',
        phone: m['phone']?.toString() ?? '',
      );
    }).toList();

    final plans = (packages as List).map((p) {
      final m = p as Map<String, dynamic>;
      return SubscriptionPlanOption(
        id: m['id'].toString(),
        name: m['title']?.toString() ?? 'باقة',
        price: double.tryParse(m['price']?.toString() ?? '0') ?? 0,
        currency: 'ج.م',
        days: int.tryParse(m['days']?.toString() ?? '30') ?? 30,
        tripsCount: int.tryParse(m['trips_count']?.toString() ?? '0') ?? 0,
      );
    }).toList();

    final routeOptions = (routes as List).map((r) {
      final m = r as Map<String, dynamic>;
      final pickup = m['pickup']?.toString() ?? '';
      final destination = m['destination']?.toString() ?? '';
      final label = [pickup, destination].where((s) => s.isNotEmpty).join(' - ');
      return SubscriptionRouteOption(
        id: m['id'].toString(),
        label: label.isEmpty ? 'مسار' : label,
      );
    }).toList();

    return SubscriptionCreationOptions(
      users: users,
      plans: plans,
      routes: routeOptions,
    );
  }

  UserSubscriptionModel _fromRow(Map<String, dynamic> json) {
    final client = json['client'] as Map<String, dynamic>? ?? {};
    final pkg = json['package'] as Map<String, dynamic>?;

    final statusStr = json['status']?.toString();
    final mappedStatus = switch (statusStr) {
      'active' => SubscriptionStatus.active,
      'expired' => SubscriptionStatus.expired,
      'cancelled' => SubscriptionStatus.cancelled,
      'pending_payment' || 'paused' => SubscriptionStatus.pendingPayment,
      _ => SubscriptionStatus.pendingPayment,
    };

    final tripsCount = _toInt(json['trips_count'] ?? pkg?['trips_count']);
    final tripsUsed = _toInt(json['trips_used']);

    final now = DateTime.now();
    return UserSubscriptionModel(
      id: json['id'].toString(),
      userId: json['client_id']?.toString() ?? '',
      userName:
          json['customer_name']?.toString() ??
          client['full_name']?.toString() ??
          'غير معروف',
      userPhone:
          json['customer_phone']?.toString() ??
          client['phone']?.toString() ??
          '',
      tripId: '',
      // routeId carries the package_id so the cubit can reference it.
      routeId: json['package_id']?.toString() ?? '',
      routeName:
          pkg?['title']?.toString() ??
          json['package_name']?.toString() ??
          'باقة',
      // The actual route/line the subscriber rides — kept separate from the
      // package title so both can be shown in the dashboard.
      routeLabel: json['route_name']?.toString() ?? '',
      fromPointId: '',
      fromPointName: '',
      toPointId: '',
      toPointName: '',
      type: _typeForDays(_toInt(pkg?['days'])),
      price: _toDouble(json['total_price']),
      currency: 'ج.م',
      totalRides: tripsCount,
      usedRides: tripsUsed,
      remainingRides: (tripsCount - tripsUsed).clamp(0, tripsCount),
      paidAmount: _toDouble(json['paid_amount']),
      remainingAmount: _toDouble(json['remaining_amount']),
      renewalsCount: _toInt(json['renewals_count']),
      startDate: DateTime.tryParse(json['start_date']?.toString() ?? '') ?? now,
      endDate:
          DateTime.tryParse(json['end_date']?.toString() ?? '') ??
          now.add(const Duration(days: 30)),
      status: mappedStatus,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? now,
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? now,
    );
  }

  static double _toDouble(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;

  static int _toInt(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

  static SubscriptionType _typeForDays(int days) {
    if (days <= 1) return SubscriptionType.oneTime;
    if (days <= 7) return SubscriptionType.fiveDays;
    if (days <= 14) return SubscriptionType.tenDaysMonthly;
    if (days >= 80) return SubscriptionType.threeMonths;
    return SubscriptionType.monthly;
  }
}
