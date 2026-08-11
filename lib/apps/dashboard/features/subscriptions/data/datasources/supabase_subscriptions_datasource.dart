import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/session/dashboard_session.dart';
import '../../domain/entities/subscription_trip.dart';
import '../../domain/entities/user_subscription.dart';
import '../models/user_subscription_model.dart';
import 'subscriptions_datasource.dart';

class SupabaseSubscriptionsDatasource implements SubscriptionsDatasource {
  final SupabaseClient _client;
  final DashboardSession _session;

  const SupabaseSubscriptionsDatasource(this._client, this._session);

  static const _select = '''
    *,
    client:clients(full_name, phone),
    package:packages(id, title, days, trips_count),
    route:operation_routes!subscriptions_route_fk(id, name, start_city, end_city)
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
      if (subscription.packageId.isNotEmpty)
        'package_id': subscription.packageId,
      'package_name': subscription.packageName,
      if (subscription.routeId.isNotEmpty) 'route_id': subscription.routeId,
      
      'route_name': subscription.routeLabel.isNotEmpty
          ? subscription.routeLabel
          : subscription.packageName,
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
  Future<UserSubscription> markRideUsed(String id, {String? tripId}) async {
    await _client.rpc(
      'office_consume_subscription_ride',
      params: {'p_subscription_id': id, 'p_trip_id': tripId},
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
  Future<List<SubscriptionTrip>> fetchTrips() async {
    final rows = await _client
        .from('operation_trips')
        .select('''
          id, trip_code, trip_date, departure_time, status, route_id,
          route:operation_routes(id, name, start_city, end_city)
        ''')
        .eq('office_id', _session.officeId)
        .order('trip_date', ascending: false)
        .order('departure_time', ascending: false);

    return (rows as List).map((row) {
      final map = row as Map<String, dynamic>;
      final route = map['route'] as Map<String, dynamic>?;
      return SubscriptionTrip(
        id: map['id'].toString(),
        code: map['trip_code']?.toString() ?? '',
        routeId: map['route_id']?.toString() ?? '',
        routeName: _routeLabel(route),
        date: DateTime.tryParse(map['trip_date']?.toString() ?? ''),
        departureTime: map['departure_time']?.toString() ?? '',
        status: map['status']?.toString() ?? '',
      );
    }).toList();
  }

  @override
  Future<List<SubscriptionRideUsage>> fetchRideUsage() async {
    final rows = await _client
        .from('subscription_ride_usage')
        .select('id, subscription_id, trip_id, used_at')
        .eq('office_id', _session.officeId)
        .order('used_at', ascending: false);

    return (rows as List).map((row) {
      final map = row as Map<String, dynamic>;
      return SubscriptionRideUsage(
        id: map['id'].toString(),
        subscriptionId: map['subscription_id'].toString(),
        tripId: map['trip_id']?.toString(),
        usedAt:
            DateTime.tryParse(map['used_at']?.toString() ?? '') ??
            DateTime.now(),
      );
    }).toList();
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
        .from('operation_routes')
        .select('id, name, start_city, end_city, status')
        .eq('office_id', _session.officeId)
        .neq('status', 'archived')
        .order('name');

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
      return SubscriptionRouteOption(
        id: m['id'].toString(),
        label: _routeLabel(m),
        status: m['status']?.toString() ?? 'active',
      );
    }).toList();

    return SubscriptionCreationOptions(
      users: users,
      plans: plans,
      routes: routeOptions,
    );
  }

  /// A route's display name, falling back to its city pair when unnamed.
  static String _routeLabel(Map<String, dynamic>? route) {
    if (route == null) return '';
    final name = route['name']?.toString().trim() ?? '';
    if (name.isNotEmpty) return name;
    final start = route['start_city']?.toString().trim() ?? '';
    final end = route['end_city']?.toString().trim() ?? '';
    final pair = [start, end].where((part) => part.isNotEmpty).join(' → ');
    return pair.isEmpty ? 'مسار' : pair;
  }

  UserSubscriptionModel _fromRow(Map<String, dynamic> json) {
    final client = json['client'] as Map<String, dynamic>? ?? {};
    final pkg = json['package'] as Map<String, dynamic>?;
    final route = json['route'] as Map<String, dynamic>?;

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

    final linkedRouteLabel = _routeLabel(route);

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
      packageId: json['package_id']?.toString() ?? '',
      packageName:
          pkg?['title']?.toString() ??
          json['package_name']?.toString() ??
          'باقة',
      routeId: json['route_id']?.toString() ?? '',
      routeLabel: linkedRouteLabel.isNotEmpty
          ? linkedRouteLabel
          : json['route_name']?.toString() ?? '',
      originTripId: json['origin_trip_id']?.toString() ?? '',
      originBookingId: json['origin_booking_id']?.toString() ?? '',
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
