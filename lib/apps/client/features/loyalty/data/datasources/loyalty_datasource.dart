import '../models/loyalty_snapshot_model.dart';

abstract class LoyaltyDatasource {
  /// Reads the rider's balance, ledger, tier catalog and reward catalog.
  Future<LoyaltySnapshotModel> fetchSnapshot();

  /// Debits [pointsCost] and records the redemption of [rewardTitle].
  ///
  /// Throws when the balance no longer covers the cost.
  Future<void> redeemReward({
    required String rewardTitle,
    required int pointsCost,
  });
}
