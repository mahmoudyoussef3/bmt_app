import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/loyalty_data.dart';
import 'loyalty_datasource.dart';

class SupabaseLoyaltyDatasource implements LoyaltyDatasource {
  final SupabaseClient _supabase;

  const SupabaseLoyaltyDatasource(this._supabase);

  String _calculateTier(int points) {
    if (points >= 3000) return 'Platinum';
    if (points >= 2000) return 'Gold';
    if (points >= 1000) return 'Silver';
    return 'Bronze';
  }

  /// Runs a select query, returning an empty list if the table is not yet
  /// provisioned (PGRST205) so one missing catalog table cannot fail the
  /// whole screen.
  Future<List<dynamic>> _safeList(Future<dynamic> Function() query) async {
    try {
      final result = await query();
      return result is List ? result : const <dynamic>[];
    } on PostgrestException {
      return const <dynamic>[];
    }
  }

  @override
  Future<LoyaltyData> getLoyaltyData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated');
    }

    // 1. Points and wallet balance (core data).
    final accountResponse = await _supabase
        .from('loyalty_accounts')
        .select()
        .eq('client_id', user.id)
        .maybeSingle();

    // 2-4. Transactions, tiers and rewards are catalog/history data. Fetch
    // them defensively so a not-yet-provisioned table degrades to an empty
    // section instead of failing the whole screen.
    final responses = await Future.wait([
      _safeList(
        () => _supabase
            .from('loyalty_transactions')
            .select()
            .eq('client_id', user.id)
            .order('created_at', ascending: false),
      ),
      _safeList(
        () => _supabase
            .from('loyalty_tiers')
            .select()
            .order('points_required_val', ascending: true),
      ),
      _safeList(
        () => _supabase
            .from('loyalty_rewards')
            .select()
            .eq('is_active', true)
            .order('points_cost', ascending: true),
      ),
    ]);

    final txResponse = responses[0];
    final tiersResponse = responses[1];
    final rewardsResponse = responses[2];

    final currentPoints = accountResponse?['points'] as int? ?? 0;

    final transactions = txResponse.map((tx) {
      return PointsTransaction(
        title: tx['title']?.toString() ?? 'Transaction',
        date: tx['created_at'] != null
            ? tx['created_at'].toString().split('T')[0]
            : 'Unknown',
        points: tx['points'] as int? ?? 0,
        isEarned: tx['is_earned'] as bool? ?? true,
      );
    }).toList();

    final tiers = tiersResponse.map((tier) {
      final colors =
          (tier['gradient_colors'] as List<dynamic>?)
              ?.map((c) => int.tryParse(c.toString()) ?? 0xFFB0BEC5)
              .toList() ??
          [0xFFB0BEC5, 0xFF607D8B];

      return LoyaltyTier(
        name: tier['name']?.toString() ?? 'Tier',
        pointsRequired: tier['points_required']?.toString() ?? '0 pts',
        iconKey: tier['icon_key']?.toString() ?? 'stars',
        gradientColors: colors,
        perks:
            (tier['perks'] as List<dynamic>?)
                ?.map((p) => p.toString())
                .toList() ??
            [],
      );
    }).toList();

    final rewards = rewardsResponse.map((reward) {
      return RedeemableReward(
        id: reward['id']?.toString() ?? '',
        title: reward['title']?.toString() ?? '',
        description: reward['description']?.toString() ?? '',
        pointsCost: reward['points_cost'] as int? ?? 0,
        valueLabel: reward['value_label']?.toString() ?? '',
        category: reward['category']?.toString() ?? 'Discount',
        couponCode: reward['coupon_code']?.toString() ?? '',
      );
    }).toList();

    return LoyaltyData(
      currentPoints: currentPoints,
      currentTierName: _calculateTier(currentPoints),
      tiers: tiers,
      transactions: transactions,
      rewards: rewards,
    );
  }

  @override
  Future<void> redeemReward({
    required String rewardId,
    required String rewardTitle,
    required int pointsCost,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User is not authenticated');

    final account = await _supabase
        .from('loyalty_accounts')
        .select('points')
        .eq('client_id', user.id)
        .maybeSingle();

    final currentPoints = account?['points'] as int? ?? 0;
    if (currentPoints < pointsCost) {
      throw Exception('Insufficient points balance to redeem this reward');
    }

    await Future.wait([
      _supabase
          .from('loyalty_accounts')
          .update({'points': currentPoints - pointsCost})
          .eq('client_id', user.id),
      _supabase.from('loyalty_transactions').insert({
        'client_id': user.id,
        'title': 'Redeemed: $rewardTitle',
        'points': -pointsCost,
        'is_earned': false,
      }),
    ]);
  }
}
