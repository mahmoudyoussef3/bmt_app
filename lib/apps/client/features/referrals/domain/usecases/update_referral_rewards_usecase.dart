import '../entities/referral_rewards.dart';
import '../repositories/referral_rewards_repository.dart';

/// Local-only: marks a contact as invited in the in-memory list.
/// Contact invite tracking is not persisted to Supabase in the current schema.
class InviteContactUseCase {
  const InviteContactUseCase();

  void call(ReferralRewardsData data, ReferralContact contact) {
    if (contact.isInvited) return;
    contact.isInvited = true;
    data.totalInvites++;
  }
}

/// Persists wallet balance redemption to Supabase via the repository.
/// Returns the amount actually redeemed.
class RedeemRewardsUseCase {
  const RedeemRewardsUseCase(this._repository);

  final ReferralRewardsRepository _repository;

  Future<int> call() => _repository.redeemWalletBalance();
}

/// Local-only: reveals a scratch voucher in the UI.
/// Voucher reveal state is not persisted to Supabase in the current schema.
class RevealVoucherUseCase {
  const RevealVoucherUseCase();

  void call(ScratchVoucher voucher) {
    voucher.isRevealed = true;
  }
}
