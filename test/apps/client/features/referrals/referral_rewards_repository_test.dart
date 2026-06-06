import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/client/features/referrals/data/datasources/mock_referral_rewards_datasource.dart';
import 'package:bmt_app/apps/client/features/referrals/data/repositories/referral_rewards_repository_impl.dart';
import 'package:bmt_app/apps/client/features/referrals/domain/usecases/get_referral_rewards_data_usecase.dart';
import 'package:bmt_app/apps/client/features/referrals/domain/usecases/update_referral_rewards_usecase.dart';

void main() {
  group('Client referral rewards', () {
    test('returns referral rewards dashboard data', () async {
      const repository = ReferralRewardsRepositoryImpl(
        MockReferralRewardsDatasource(),
      );

      final data = await GetReferralRewardsDataUseCase(repository)();

      expect(data.referralCode, 'MEGA-SHUTTLE-77X');
      expect(data.contacts, hasLength(6));
      expect(data.history.first.status, 'Completed');
      expect(data.vouchers.last.isRevealed, isTrue);
    });

    test(
      'updates invite, redeem, and voucher state through use cases',
      () async {
        const repository = ReferralRewardsRepositoryImpl(
          MockReferralRewardsDatasource(),
        );
        final data = await GetReferralRewardsDataUseCase(repository)();

        const InviteContactUseCase()(data, data.contacts.first);
        final redeemed = const RedeemRewardsUseCase()(data);
        const RevealVoucherUseCase()(data.vouchers.first);

        expect(data.contacts.first.isInvited, isTrue);
        expect(data.totalInvites, 13);
        expect(redeemed, 100);
        expect(data.walletBalance, 0);
        expect(data.earnedRewardsTotal, 350);
        expect(data.vouchers.first.isRevealed, isTrue);
      },
    );
  });
}
