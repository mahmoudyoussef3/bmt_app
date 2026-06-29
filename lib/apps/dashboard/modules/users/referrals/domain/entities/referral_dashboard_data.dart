import 'referral_analytics.dart';
import 'referral_leaderboard_item.dart';
import 'referral_record.dart';
import 'referral_reward_config.dart';
import 'referral_reward_transaction.dart';

/// Everything the Referral Management screen needs, loaded in one pass.
class ReferralDashboardData {
  const ReferralDashboardData({
    required this.config,
    required this.analytics,
    required this.leaderboard,
    required this.records,
    required this.transactions,
  });

  final ReferralRewardConfig config;
  final ReferralAnalytics analytics;
  final List<ReferralLeaderboardItem> leaderboard;
  final List<ReferralRecord> records;
  final List<ReferralRewardTransaction> transactions;

  ReferralDashboardData copyWith({ReferralRewardConfig? config}) {
    return ReferralDashboardData(
      config: config ?? this.config,
      analytics: analytics,
      leaderboard: leaderboard,
      records: records,
      transactions: transactions,
    );
  }
}
