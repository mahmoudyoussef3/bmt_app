import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_subscription.dart';
import '../models/user_subscription_model.dart';
import 'subscriptions_datasource.dart';

/// Real Supabase-backed subscriptions datasource. Subscribers come from the
/// `subscriptions` table; creation options (clients + plans) come from
/// `clients` and `packages`. No mock data.
class SupabaseSubscriptionsDatasource implements SubscriptionsDatasource {
  final SupabaseClient _client;

  const SupabaseSubscriptionsDatasource(this._client);

  static const _select = '''
    *,
    client:clients(full_name, phone)
  ''';

  @override
  Future<List<UserSubscription>> fetchSubscriptions() async {
    final rows = await _client
        .from('subscriptions')
        .select(_select)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => _fromRow(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<UserSubscription> fetchSubscriptionDetails(String id) async {
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
    final payload = {
      if (subscription.userId.isNotEmpty) 'client_id': subscription.userId,
      'customer_name': subscription.userName,
      'customer_phone': subscription.userPhone,
      'package_name': subscription.routeName,
      'route_name': subscription.routeName,
      'start_date': subscription.startDate.toIso8601String(),
      'end_date': subscription.endDate.toIso8601String(),
      'status': 'active',
      'total_price': subscription.price,
      'paid_amount': 0,
      'remaining_amount': subscription.price,
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
    final current = await _client
        .from('subscriptions')
        .select('end_date, renewals_count')
        .eq('id', id)
        .single();
    final currentEnd =
        DateTime.tryParse(current['end_date']?.toString() ?? '') ??
        DateTime.now();
    final base = currentEnd.isAfter(DateTime.now())
        ? currentEnd
        : DateTime.now();
    final newEnd = DateTime(base.year, base.month + 1, base.day);
    final renewals = (current['renewals_count'] as int? ?? 0) + 1;
    final row = await _client
        .from('subscriptions')
        .update({
          'status': 'active',
          'end_date': newEnd.toIso8601String(),
          'renewals_count': renewals,
        })
        .eq('id', id)
        .select(_select)
        .single();
    return _fromRow(row);
  }

  @override
  Future<UserSubscription> markRideUsed(String id) async {
    // The `subscriptions` table tracks no per-ride usage, so this cannot be
    // persisted honestly from the dashboard.
    throw Exception('تتبع الرحلات غير مدعوم في قاعدة البيانات الحالية');
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

    return SubscriptionCreationOptions(users: users, plans: plans);
  }

  UserSubscriptionModel _fromRow(Map<String, dynamic> json) {
    final client = json['client'] as Map<String, dynamic>? ?? {};
    final statusStr = json['status']?.toString();
    final mappedStatus = switch (statusStr) {
      'expired' => SubscriptionStatus.expired,
      'cancelled' => SubscriptionStatus.cancelled,
      'paused' => SubscriptionStatus.pendingPayment,
      _ => SubscriptionStatus.active,
    };
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
      routeId: '',
      routeName:
          json['route_name']?.toString() ??
          json['package_name']?.toString() ??
          'باقة',
      fromPointId: '',
      fromPointName: '',
      toPointId: '',
      toPointName: '',
      type: SubscriptionType.monthly,
      price: double.tryParse(json['total_price']?.toString() ?? '0') ?? 0.0,
      currency: 'ج.م',
      totalRides: 0,
      usedRides: 0,
      remainingRides: 0,
      paidAmount:
          double.tryParse(json['paid_amount']?.toString() ?? '0') ?? 0.0,
      remainingAmount:
          double.tryParse(json['remaining_amount']?.toString() ?? '0') ?? 0.0,
      renewalsCount:
          int.tryParse(json['renewals_count']?.toString() ?? '0') ?? 0,
      startDate: DateTime.tryParse(json['start_date']?.toString() ?? '') ?? now,
      endDate:
          DateTime.tryParse(json['end_date']?.toString() ?? '') ??
          now.add(const Duration(days: 30)),
      status: mappedStatus,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? now,
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? now,
    );
  }
}
