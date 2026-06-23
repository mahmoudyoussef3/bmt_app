import '../../domain/entities/referral_analytics.dart';
import '../../domain/entities/referral_leaderboard_item.dart';
import '../../domain/entities/referral_record.dart';
import '../../domain/entities/referral_reward_config.dart';
import '../../domain/entities/referral_reward_transaction.dart';

abstract class ReferralDatasource {
  Future<ReferralRewardConfig> getRewardConfig();
  Future<ReferralRewardConfig> updateRewardConfig(ReferralRewardConfig config);
  Future<ReferralAnalytics> getAnalytics();
  Future<List<ReferralLeaderboardItem>> getLeaderboard();
  Future<List<ReferralRecord>> getHistory();
  Future<List<ReferralRewardTransaction>> getRewardTransactions();
}
