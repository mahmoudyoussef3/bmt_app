import '../../domain/entities/loyalty_data.dart';
import '../../domain/repositories/loyalty_repository.dart';
import '../datasources/loyalty_datasource.dart';

class LoyaltyRepositoryImpl implements LoyaltyRepository {
  const LoyaltyRepositoryImpl(this._datasource);

  final LoyaltyDatasource _datasource;

  @override
  Future<LoyaltyData> getLoyaltyData() => _datasource.getLoyaltyData();

  @override
  Future<void> redeemReward({
    required String rewardId,
    required String rewardTitle,
    required int pointsCost,
  }) => _datasource.redeemReward(
    rewardId: rewardId,
    rewardTitle: rewardTitle,
    pointsCost: pointsCost,
  );
}
