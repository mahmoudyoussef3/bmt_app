import '../entities/referral_analytics.dart';
import '../entities/referral_leaderboard_item.dart';
import '../entities/referral_record.dart';
import '../entities/referral_reward_config.dart';
import '../entities/referral_reward_transaction.dart';

abstract class ReferralRepository {
  Future<ReferralRewardConfig> getRewardConfig();
  Future<ReferralRewardConfig> updateRewardConfig(ReferralRewardConfig config);
  Future<ReferralAnalytics> getAnalytics();
  Future<List<ReferralLeaderboardItem>> getLeaderboard();
  Future<List<ReferralRecord>> getHistory();
  Future<List<ReferralRewardTransaction>> getRewardTransactions();
}
