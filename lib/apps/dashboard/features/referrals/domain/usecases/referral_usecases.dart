import '../entities/referral_analytics.dart';
import '../entities/referral_leaderboard_item.dart';
import '../entities/referral_record.dart';
import '../entities/referral_reward_config.dart';
import '../entities/referral_reward_transaction.dart';
import '../repositories/referral_repository.dart';

class GetReferralRewardConfigUseCase {
  const GetReferralRewardConfigUseCase(this._repository);
  final ReferralRepository _repository;
  Future<ReferralRewardConfig> call() => _repository.getRewardConfig();
}

class UpdateReferralRewardConfigUseCase {
  const UpdateReferralRewardConfigUseCase(this._repository);
  final ReferralRepository _repository;
  Future<ReferralRewardConfig> call(ReferralRewardConfig config) =>
      _repository.updateRewardConfig(config);
}

class GetReferralAnalyticsUseCase {
  const GetReferralAnalyticsUseCase(this._repository);
  final ReferralRepository _repository;
  Future<ReferralAnalytics> call() => _repository.getAnalytics();
}

class GetReferralLeaderboardUseCase {
  const GetReferralLeaderboardUseCase(this._repository);
  final ReferralRepository _repository;
  Future<List<ReferralLeaderboardItem>> call() => _repository.getLeaderboard();
}

class GetReferralHistoryUseCase {
  const GetReferralHistoryUseCase(this._repository);
  final ReferralRepository _repository;
  Future<List<ReferralRecord>> call() => _repository.getHistory();
}

class GetReferralRewardTransactionsUseCase {
  const GetReferralRewardTransactionsUseCase(this._repository);
  final ReferralRepository _repository;
  Future<List<ReferralRewardTransaction>> call() =>
      _repository.getRewardTransactions();
}
