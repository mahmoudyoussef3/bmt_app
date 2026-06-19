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

  @override
  Future<LoyaltyData> getLoyaltyData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User is not authenticated');
    }

    // 1. Fetch points and wallet balance
    final accountFuture = _supabase
        .from('loyalty_accounts')
        .select()
        .eq('client_id', user.id)
        .maybeSingle();

    // 2. Fetch point transactions
    final txFuture = _supabase
        .from('loyalty_transactions')
        .select()
        .eq('client_id', user.id)
        .order('created_at', ascending: false);

    // 3. Fetch loyalty tiers
    final tiersFuture = _supabase
        .from('loyalty_tiers')
        .select()
        .order(
          'points_required_val',
          ascending: true,
        ); // Assuming a numeric field for sorting

    // 4. Fetch redeemable rewards
    final rewardsFuture = _supabase
        .from('loyalty_rewards')
        .select()
        .eq('is_active', true)
        .order('points_cost', ascending: true);

    final responses = await Future.wait([
      accountFuture,
      txFuture,
      tiersFuture,
      rewardsFuture,
    ]);

    final accountResponse = responses[0] as Map<String, dynamic>?;
    final txResponse = responses[1] as List<dynamic>;
    final tiersResponse = responses[2] as List<dynamic>;
    final rewardsResponse = responses[3] as List<dynamic>;

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
}
