import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/subscription_plan.dart';

/// Real Supabase datasource for subscription plans (the `packages` table).
class SubscriptionPlansDatasource {
  final SupabaseClient _client;

  const SubscriptionPlansDatasource(this._client);

  static const _columns =
      'id, title, subtitle, price, days, trips_count, discount_percent, savings_amount, description, status';

  Future<List<SubscriptionPlan>> getPlans() async {
    final rows = await _client
        .from('packages')
        .select(_columns)
        .order('price', ascending: true);
    return (rows as List).map((r) => _fromRow(r as Map<String, dynamic>)).toList();
  }

  Future<void> createPlan(SubscriptionPlan plan) async {
    await _client.from('packages').insert(plan.toInsert());
  }

  Future<void> updatePlan(SubscriptionPlan plan) async {
    await _client.from('packages').update(plan.toInsert()).eq('id', plan.id);
  }

  Future<void> setPlanStatus(String id, PlanStatus status) async {
    await _client.from('packages').update({'status': status.db}).eq('id', id);
  }

  Future<void> deletePlan(String id) async {
    await _client.from('packages').delete().eq('id', id);
  }

  SubscriptionPlan _fromRow(Map<String, dynamic> r) {
    return SubscriptionPlan(
      id: r['id'].toString(),
      title: r['title']?.toString() ?? '',
      subtitle: r['subtitle']?.toString() ?? '',
      price: double.tryParse(r['price']?.toString() ?? '0') ?? 0,
      days: int.tryParse(r['days']?.toString() ?? '0') ?? 0,
      tripsCount: int.tryParse(r['trips_count']?.toString() ?? '0') ?? 0,
      discountPercent: int.tryParse(r['discount_percent']?.toString() ?? '0') ?? 0,
      savingsAmount: double.tryParse(r['savings_amount']?.toString() ?? '0') ?? 0,
      description: r['description']?.toString() ?? '',
      status: PlanStatus.fromDb(r['status']?.toString()),
    );
  }
}
