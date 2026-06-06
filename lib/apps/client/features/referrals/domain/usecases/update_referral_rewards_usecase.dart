import '../entities/referral_rewards.dart';

class InviteContactUseCase {
  const InviteContactUseCase();

  void call(ReferralRewardsData data, MockContact contact) {
    if (contact.isInvited) return;
    contact.isInvited = true;
    data.totalInvites++;
  }
}

class RedeemRewardsUseCase {
  const RedeemRewardsUseCase();

  int call(ReferralRewardsData data) {
    final redeemed = data.walletBalance;
    if (redeemed == 0) return 0;
    data.earnedRewardsTotal += redeemed;
    data.walletBalance = 0;
    return redeemed;
  }
}

class RevealVoucherUseCase {
  const RevealVoucherUseCase();

  void call(ScratchVoucher voucher) {
    voucher.isRevealed = true;
  }
}
