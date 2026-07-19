import '../../domain/entities/loyalty_data.dart';
import '../../domain/entities/redeemable_reward.dart';
import '../../domain/repositories/loyalty_repository.dart';
import '../datasources/loyalty_datasource.dart';
import '../mappers/loyalty_mappers.dart';

class LoyaltyRepositoryImpl implements LoyaltyRepository {
  const LoyaltyRepositoryImpl(this._datasource);

  final LoyaltyDatasource _datasource;

  @override
  Future<LoyaltyData> getLoyaltyData() async {
    final snapshot = await _datasource.fetchSnapshot();
    return snapshot.toEntity();
  }

  @override
  Future<void> redeemReward(RedeemableReward reward) => _datasource.redeemReward(
    rewardTitle: reward.title,
    pointsCost: reward.pointsCost,
  );
}
