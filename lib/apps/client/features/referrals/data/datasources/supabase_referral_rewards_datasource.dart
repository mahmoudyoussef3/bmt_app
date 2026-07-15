import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/referral_rewards.dart';

class SupabaseReferralRewardsDatasource {
  const SupabaseReferralRewardsDatasource(this._supabase);

  final SupabaseClient _supabase;

  Future<int> redeemWalletBalance() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final account = await _supabase
        .from('loyalty_accounts')
        .select('wallet_balance')
        .eq('client_id', user.id)
        .maybeSingle();

    final balance = account?['wallet_balance'] as int? ?? 0;
    if (balance <= 0) return 0;

    await _supabase
        .from('loyalty_accounts')
        .update({'wallet_balance': 0})
        .eq('client_id', user.id);

    return balance;
  }

  Future<ReferralRewardsData> getReferralRewardsData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Loyalty account holds the wallet balance (core data).
    final accountData = await _supabase
        .from('loyalty_accounts')
        .select()
        .eq('client_id', user.id)
        .maybeSingle();

    // Rewards catalog is optional — degrade to no vouchers if the table is
    // not yet provisioned instead of failing the whole screen.
    List<dynamic> rewardsData = const [];
    try {
      rewardsData = await _supabase
          .from('loyalty_rewards')
          .select()
          .eq('is_active', true)
          .order('points_cost', ascending: true)
          .limit(5);
    } on PostgrestException {
      rewardsData = const [];
    }

    final walletBalance = accountData?['wallet_balance'] as int? ?? 0;

    // Referral history — safe fetch; table may not exist yet.
    List<ReferralHistoryItem> history = [];
    int totalInvites = 0;
    int successfulReferrals = 0;
    int earnedRewardsTotal = 0;

    int pendingReferrals = 0;

    try {
      final referrals = await _supabase
          .from('referrals')
          .select()
          .eq('referrer_id', user.id)
          .order('created_at', ascending: false);

      totalInvites = referrals.length;
      for (final ref in referrals) {
        final rawStatus = (ref['status']?.toString() ?? 'pending_registration')
            .toLowerCase();
        final reward =
            (ref['reward_value'] as num?)?.toInt() ??
            (ref['reward_amount'] as num?)?.toInt() ??
            0;
        if (_isSuccessful(rawStatus)) {
          successfulReferrals++;
          earnedRewardsTotal += reward;
        } else {
          pendingReferrals++;
        }
        history.add(
          ReferralHistoryItem(
            name: ref['referred_name']?.toString() ?? 'Guest',
            date: _formatDate(ref['created_at']?.toString()),
            status: _statusLabel(rawStatus),
            rewardAmount: reward,
          ),
        );
      }
    } catch (_) {
      // referrals table not provisioned yet — show empty state
    }

    // Top referrers leaderboard — backed by the `referral_leaderboard` view.
    List<ReferralLeaderboardEntry> leaderboard = [];
    try {
      final rows = await _supabase
          .from('referral_leaderboard')
          .select()
          .order('successful_count', ascending: false)
          .limit(10);
      var rank = 1;
      for (final r in rows) {
        leaderboard.add(
          ReferralLeaderboardEntry(
            rank: rank++,
            name: r['name']?.toString() ?? 'Member',
            successfulCount: (r['successful_count'] as num?)?.toInt() ?? 0,
            totalRewards: (r['total_rewards'] as num?)?.toInt() ?? 0,
            isCurrentUser: r['referrer_id']?.toString() == user.id,
          ),
        );
      }
    } catch (_) {
      // leaderboard view not provisioned yet — hide the section
    }

    // Derive a deterministic referral code from the user's UUID.
    final codeBase = user.id.replaceAll('-', '').toUpperCase().substring(0, 8);
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
      pendingReferrals: pendingReferrals,
      earnedRewardsTotal: earnedRewardsTotal,
      walletBalance: walletBalance,
      contacts: const [],
      history: history,
      vouchers: vouchers,
      leaderboard: leaderboard,
    );
  }

  /// A referral counts as successful once the referred user reaches the first
  /// paid order (or the reward has been granted).
  static bool _isSuccessful(String rawStatus) {
    return rawStatus == 'completed' ||
        rawStatus == 'first_order_completed' ||
        rawStatus == 'reward_granted';
  }

  static String _statusLabel(String rawStatus) {
    return switch (rawStatus) {
      'registered' => 'Registered',
      'first_order_completed' => 'First Order Completed',
      'reward_granted' || 'completed' => 'Reward Granted',
      _ => 'Pending Registration',
    };
  }

  /// Returns a plain `yyyy-MM-dd` date. Locale-aware display formatting
  /// (month names, ordering) happens in the presentation layer, which has
  /// the `BuildContext` this data layer must stay free of.
  static String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      return DateTime.parse(iso).toIso8601String().split('T').first;
    } catch (_) {
      return iso.split('T').first;
    }
  }
}
