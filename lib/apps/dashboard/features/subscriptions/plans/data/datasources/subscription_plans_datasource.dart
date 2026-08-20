import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/entitlements/licensing_guard.dart';
import '../../../../../core/session/dashboard_session.dart';
import '../../domain/entities/subscription_plan.dart';

/// Real Supabase datasource for the packages used by the booking flow.
class SubscriptionPlansDatasource {
  final SupabaseClient _client;
  final DashboardSession _session;

  const SubscriptionPlansDatasource(this._client, this._session);

  static const _columns =
      'id, name_ar, name_en, package_type, price, duration_days, ride_count, '
      'description_ar, description_en, active, display_order';

  Future<List<SubscriptionPlan>> getPlans() async {
    final rows = await _client
        .from('transport_packages')
        .select(_columns)
        .eq('office_id', _session.officeId)
        // The office catalog only. A package created inside the trip planner
        // carries `trip_id` and is sold on that one trip — listing it here
        // would make a per-trip offer look like a permanent catalog entry.
        // See `20260820100000_trip_scoped_packages.sql`.
        .isFilter('trip_id', null)
        .order('display_order', ascending: true);
    return (rows as List)
        .map((r) => _fromRow(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> createPlan(SubscriptionPlan plan) async {
    final displayOrder = await _nextDisplayOrder();
    await LicensingGuard.run(
      () => _client.from('transport_packages').insert({
        ...plan.toTransportPackage(),
        'office_id': _session.officeId,
        'display_order': displayOrder,
      }),
    );
  }

  Future<void> updatePlan(SubscriptionPlan plan) async {
    await LicensingGuard.run(
      () => _client
          .from('transport_packages')
          .update(plan.toTransportPackage())
          .eq('id', plan.id),
    );
  }

  Future<void> setPlanStatus(String id, PlanStatus status) async {
    await LicensingGuard.run(
      () => _client
          .from('transport_packages')
          .update({'active': status == PlanStatus.active})
          .eq('id', id),
    );
  }

  Future<void> deletePlan(String id) async {
    await LicensingGuard.run(
      () => _client.from('transport_packages').delete().eq('id', id),
    );
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
      descriptionAr: r['description_ar']?.toString() ?? '',
      descriptionEn: r['description_en']?.toString() ?? '',
      status: r['active'] == true ? PlanStatus.active : PlanStatus.paused,
      packageType: r['package_type']?.toString() ?? '',
    );
  }

  Future<int> _nextDisplayOrder() async {
    final row = await _client
        .from('transport_packages')
        .select('display_order')
        .eq('office_id', _session.officeId)
        .order('display_order', ascending: false)
        .limit(1)
        .maybeSingle();
    return (row?['display_order'] as int? ?? 0) + 1;
  }
}
