import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/loyalty/data/datasources/mock_loyalty_datasource.dart';
import 'package:bmt_app/apps/client/features/loyalty/data/repositories/loyalty_repository_impl.dart';
import 'package:bmt_app/apps/client/features/loyalty/domain/usecases/get_loyalty_data_usecase.dart';
import 'package:bmt_app/apps/client/features/loyalty/domain/usecases/redeem_loyalty_reward_usecase.dart';

void main() {
  group('Client loyalty', () {
    test('returns loyalty dashboard data', () async {
      const repository = LoyaltyRepositoryImpl(MockLoyaltyDatasource());

      final data = await GetLoyaltyDataUseCase(repository)();

      expect(data.currentPoints, 2450);
      expect(data.currentTierName, 'Gold');
      expect(data.tiers, hasLength(4));
      expect(data.transactions, hasLength(6));
      expect(data.rewards.last.pointsCost, 2800);
    });

    test('redeems reward and recalculates tier', () async {
      const repository = LoyaltyRepositoryImpl(MockLoyaltyDatasource());
      final data = await GetLoyaltyDataUseCase(repository)();

      final updated = const RedeemLoyaltyRewardUseCase()(data, data.rewards[2]);

      expect(updated.currentPoints, 1450);
      expect(updated.currentTierName, 'Silver');
    });
  });
}
