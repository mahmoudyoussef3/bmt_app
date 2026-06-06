import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/referral_rewards.dart';
import '../../domain/usecases/get_referral_rewards_data_usecase.dart';
import '../../domain/usecases/update_referral_rewards_usecase.dart';
import 'referral_rewards_state.dart';

class ReferralRewardsCubit extends Cubit<ReferralRewardsState> {
  ReferralRewardsCubit({
    required GetReferralRewardsDataUseCase getData,
    required InviteContactUseCase inviteContact,
    required RedeemRewardsUseCase redeemRewards,
    required RevealVoucherUseCase revealVoucher,
  }) : _getData = getData,
       _inviteContact = inviteContact,
       _redeemRewards = redeemRewards,
       _revealVoucher = revealVoucher,
       super(const ReferralRewardsLoading());

  final GetReferralRewardsDataUseCase _getData;
  final InviteContactUseCase _inviteContact;
  final RedeemRewardsUseCase _redeemRewards;
  final RevealVoucherUseCase _revealVoucher;

  Future<void> load() async {
    emit(const ReferralRewardsLoading());
    try {
      emit(ReferralRewardsLoaded(await _getData()));
    } catch (error) {
      emit(ReferralRewardsError(error.toString()));
    }
  }

  void invite(MockContact contact) {
    final current = state;
    if (current is! ReferralRewardsLoaded) return;
    _inviteContact(current.data, contact);
    emit(ReferralRewardsLoaded(current.data));
  }

  int redeem() {
    final current = state;
    if (current is! ReferralRewardsLoaded) return 0;
    final redeemed = _redeemRewards(current.data);
    emit(ReferralRewardsLoaded(current.data));
    return redeemed;
  }

  void reveal(ScratchVoucher voucher) {
    final current = state;
    if (current is! ReferralRewardsLoaded) return;
    _revealVoucher(voucher);
    emit(ReferralRewardsLoaded(current.data));
  }
}
