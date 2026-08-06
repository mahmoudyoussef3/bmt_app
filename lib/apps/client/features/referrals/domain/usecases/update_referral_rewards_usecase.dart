import '../entities/referral_rewards.dart';

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

/// Local-only: reveals a scratch voucher in the UI.
/// Voucher reveal state is not persisted to Supabase in the current schema.
class RevealVoucherUseCase {
  const RevealVoucherUseCase();

  void call(ScratchVoucher voucher) {
    voucher.isRevealed = true;
  }
}
