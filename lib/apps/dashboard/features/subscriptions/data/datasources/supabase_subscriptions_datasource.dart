import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_subscription.dart';
import '../models/user_subscription_model.dart';
import 'mock_subscriptions_datasource.dart'; // fallback

class SupabaseSubscriptionsDatasource implements SubscriptionsDatasource {
  final SupabaseClient _client;
  final MockSubscriptionsDatasource _mockDatasource;

  SupabaseSubscriptionsDatasource(this._client) : _mockDatasource = MockSubscriptionsDatasource();

  @override
  Future<List<UserSubscription>> fetchSubscriptions() async {
    final response = await _client.from('subscriptions').select('''
      *,
      client:clients(full_name, phone)
    ''').order('created_at', ascending: false);

    if (response.isEmpty) {
      // Fallback to mock if table is empty just to show UI while developing
      return _mockDatasource.fetchSubscriptions();
    }

    return response.map((json) {
      final client = json['client'] as Map<String, dynamic>? ?? {};
      
      SubscriptionStatus mappedStatus = SubscriptionStatus.active;
      final st = json['status']?.toString();
      if (st == 'expired') mappedStatus = SubscriptionStatus.expired;
      if (st == 'cancelled') mappedStatus = SubscriptionStatus.cancelled;
      if (st == 'paused') mappedStatus = SubscriptionStatus.pendingPayment; // Mapping paused to pendingPayment for now
      
      return UserSubscriptionModel(
        id: json['id'],
        userId: json['client_id']?.toString() ?? '',
        userName: json['customer_name'] ?? client['full_name'] ?? 'غير معروف',
        userPhone: json['customer_phone'] ?? client['phone'] ?? '',
        tripId: '', // Default as it's missing in DB schema
        routeId: '',
        routeName: json['route_name'] ?? json['package_name'] ?? 'باقة',
        fromPointId: '',
        fromPointName: '',
        toPointId: '',
        toPointName: '',
        type: SubscriptionType.monthly, // default
        price: double.tryParse(json['total_price']?.toString() ?? '0') ?? 0.0,
        currency: 'ج.م',
        totalRides: 30, // Default mock logic since missing from schema
        usedRides: 0,
        remainingRides: 30,
        startDate: DateTime.tryParse(json['start_date']?.toString() ?? '') ?? DateTime.now(),
        endDate: DateTime.tryParse(json['end_date']?.toString() ?? '') ?? DateTime.now().add(const Duration(days: 30)),
        status: mappedStatus,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }).toList();
  }

  @override
  Future<UserSubscription> fetchSubscriptionDetails(String id) async {
    return _mockDatasource.fetchSubscriptionDetails(id);
  }

  @override
  Future<UserSubscription> createSubscription(UserSubscription subscription) async {
    return _mockDatasource.createSubscription(subscription);
  }

  @override
  Future<UserSubscription> cancelSubscription(String id) async {
    await _client.from('subscriptions').update({
      'status': 'cancelled',
    }).eq('id', id);
    return _mockDatasource.cancelSubscription(id);
  }

  @override
  Future<UserSubscription> renewSubscription(String id) async {
    return _mockDatasource.renewSubscription(id);
  }

  @override
  Future<UserSubscription> markRideUsed(String id) async {
    return _mockDatasource.markRideUsed(id);
  }

  @override
  Future<SubscriptionCreationOptions> fetchCreationOptions() async {
    return _mockDatasource.fetchCreationOptions();
  }
}
