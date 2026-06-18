import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/referral_rewards.dart';

class SupabaseReferralRewardsDatasource {
  const SupabaseReferralRewardsDatasource(this._supabase);

  final SupabaseClient _supabase;

  Future<ReferralRewardsData> getReferralRewardsData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Query loyalty account and referral history in parallel.
    // referrals table is optional — swallow errors if it doesn't exist yet.
    final loyaltyFuture = _supabase
        .from('loyalty_accounts')
        .select()
        .eq('client_id', user.id)
        .maybeSingle();

    final rewardsFuture = _supabase
        .from('loyalty_rewards')
        .select()
        .eq('is_active', true)
        .order('points_cost', ascending: true)
        .limit(5);

    final results = await Future.wait([loyaltyFuture, rewardsFuture]);

    final accountData = results[0] as Map<String, dynamic>?;
    final rewardsData = results[1] as List<dynamic>;

    final walletBalance =
        accountData?['wallet_balance'] as int? ?? 0;

    // Referral history — safe fetch; table may not exist yet.
    List<ReferralHistoryItem> history = [];
    int totalInvites = 0;
    int successfulReferrals = 0;
    int earnedRewardsTotal = 0;

    try {
      final referrals = await _supabase
          .from('referrals')
          .select()
          .eq('referrer_id', user.id)
          .order('created_at', ascending: false);

      totalInvites = referrals.length;
      for (final ref in referrals) {
        final rawStatus = ref['status']?.toString() ?? 'pending';
        final status = _capitalize(rawStatus);
        final reward = ref['reward_amount'] as int? ?? 0;
        if (rawStatus.toLowerCase() == 'completed') {
          successfulReferrals++;
          earnedRewardsTotal += reward;
        }
        history.add(
          ReferralHistoryItem(
            name: ref['referred_name']?.toString() ?? 'Guest',
            date: _formatDate(ref['created_at']?.toString()),
            status: status,
            rewardAmount: reward,
          ),
        );
      }
    } catch (_) {
      // referrals table not provisioned yet — show empty state
    }

    // Derive a deterministic referral code from the user's UUID.
    final codeBase =
        user.id.replaceAll('-', '').toUpperCase().substring(0, 8);
    final referralCode = 'BMT-$codeBase';

    // Map loyalty_rewards catalog items to scratch vouchers so the
    // vouchers section shows real redeemable offers.
    final vouchers = rewardsData.map<ScratchVoucher>((r) {
      return ScratchVoucher(
        id: r['id']?.toString() ?? '',
        title: r['title']?.toString() ?? 'Reward',
        description: r['description']?.toString() ?? '',
        promoCode: r['coupon_code']?.toString() ?? '',
        amount: r['value_label']?.toString() ?? '',
      );
    }).toList();

    return ReferralRewardsData(
      referralCode: referralCode,
      totalInvites: totalInvites,
      successfulReferrals: successfulReferrals,
      earnedRewardsTotal: earnedRewardsTotal,
      walletBalance: walletBalance,
      contacts: const [],
      history: history,
      vouchers: vouchers,
    );
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  static String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return iso.split('T').first;
    }
  }
}
