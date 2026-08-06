import '../entities/referral_rewards.dart';

/// Read-only.
///
/// `redeemWalletBalance()` was removed on 2026-08-06 along with the rest of the
/// `loyalty_accounts.wallet_balance` path. It zeroed a balance client-side, was
/// denied by RLS without throwing, and reported a payout that never happened —
/// latent only because the balance was always 0. Referral money now arrives as a
/// real wallet entry (`kind = cashback, category = referral`) and is read on the
/// wallet screen.
abstract class ReferralRewardsRepository {
  Future<ReferralRewardsData> getReferralRewardsData();
}
