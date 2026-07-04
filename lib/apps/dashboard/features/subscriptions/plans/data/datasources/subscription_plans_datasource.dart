import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/subscription_plan.dart';

/// Real Supabase datasource for the packages used by the booking flow.
class SubscriptionPlansDatasource {
  final SupabaseClient _client;

  const SubscriptionPlansDatasource(this._client);

  static const _columns =
      'id, name_ar, name_en, package_type, price, duration_days, ride_count, active, display_order';

  Future<List<SubscriptionPlan>> getPlans() async {
    final rows = await _client
        .from('transport_packages')
        .select(_columns)
        .order('display_order', ascending: true);
    return (rows as List)
        .map((r) => _fromRow(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> createPlan(SubscriptionPlan plan) async {
    await _client.from('transport_packages').insert({
      ...plan.toTransportPackage(),
      'display_order': await _nextDisplayOrder(),
    });
  }

  Future<void> updatePlan(SubscriptionPlan plan) async {
    await _client
        .from('transport_packages')
        .update(plan.toTransportPackage())
        .eq('id', plan.id);
  }

  Future<void> setPlanStatus(String id, PlanStatus status) async {
    await _client
        .from('transport_packages')
        .update({'active': status == PlanStatus.active})
        .eq('id', id);
  }

  Future<void> deletePlan(String id) async {
    await _client.from('transport_packages').delete().eq('id', id);
  }

  SubscriptionPlan _fromRow(Map<String, dynamic> r) {
    return SubscriptionPlan(
      id: r['id'].toString(),
      title: r['name_ar']?.toString() ?? '',
      subtitle: r['name_en']?.toString() ?? '',
      price: double.tryParse(r['price']?.toString() ?? '0') ?? 0,
      days: int.tryParse(r['duration_days']?.toString() ?? '0') ?? 0,
      tripsCount: int.tryParse(r['ride_count']?.toString() ?? '0') ?? 0,
      discountPercent: 0,
      savingsAmount: 0,
      description: '',
      status: r['active'] == true ? PlanStatus.active : PlanStatus.paused,
      packageType: r['package_type']?.toString() ?? '',
    );
  }

  Future<int> _nextDisplayOrder() async {
    final row = await _client
        .from('transport_packages')
        .select('display_order')
        .order('display_order', ascending: false)
        .limit(1)
        .maybeSingle();
    return (row?['display_order'] as int? ?? 0) + 1;
  }
}
