import '../../domain/entities/referral_analytics.dart';
import '../../domain/entities/referral_leaderboard_item.dart';
import '../../domain/entities/referral_record.dart';
import '../../domain/entities/referral_reward_config.dart';
import '../../domain/entities/referral_reward_transaction.dart';
import '../../domain/repositories/referral_repository.dart';
import '../datasources/referral_datasource.dart';

class ReferralRepositoryImpl implements ReferralRepository {
  const ReferralRepositoryImpl(this._datasource);

  final ReferralDatasource _datasource;

  @override
  Future<ReferralRewardConfig> getRewardConfig() =>
      _datasource.getRewardConfig();

  @override
  Future<ReferralRewardConfig> updateRewardConfig(
    ReferralRewardConfig config,
  ) => _datasource.updateRewardConfig(config);

  @override
  Future<ReferralAnalytics> getAnalytics() => _datasource.getAnalytics();

  @override
  Future<List<ReferralLeaderboardItem>> getLeaderboard() =>
      _datasource.getLeaderboard();

  @override
  Future<List<ReferralRecord>> getHistory() => _datasource.getHistory();

  @override
  Future<List<ReferralRewardTransaction>> getRewardTransactions() =>
      _datasource.getRewardTransactions();
}
