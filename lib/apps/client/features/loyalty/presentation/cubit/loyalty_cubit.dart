import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/redeemable_reward.dart';
import '../../domain/usecases/get_loyalty_data_usecase.dart';
import '../../domain/usecases/redeem_loyalty_reward_usecase.dart';
import 'loyalty_state.dart';

class LoyaltyCubit extends Cubit<LoyaltyState> {
  LoyaltyCubit({
    required GetLoyaltyDataUseCase getData,
    required RedeemLoyaltyRewardUseCase redeemReward,
  }) : _getData = getData,
       _redeemReward = redeemReward,
       super(const LoyaltyLoading());

  final GetLoyaltyDataUseCase _getData;
  final RedeemLoyaltyRewardUseCase _redeemReward;

  Future<void> load() async {
    emit(const LoyaltyLoading());
    try {
      emit(LoyaltyLoaded(await _getData()));
    } catch (error) {
      emit(LoyaltyError(error.toString()));
    }
  }

  void showView(LoyaltyView view) {
    final current = state;
    if (current is! LoyaltyLoaded || current.view == view) return;
    emit(current.copyWith(view: view));
  }

  /// Returns to the dashboard, reporting whether there was anywhere to go back
  /// to — the screen uses this to decide between closing a panel and leaving.
  bool popView() {
    final current = state;
    if (current is! LoyaltyLoaded || current.view == LoyaltyView.dashboard) {
      return false;
    }
    emit(current.copyWith(view: LoyaltyView.dashboard));
    return true;
  }

  /// Redeems [reward], returning `null` on success or the failure message.
  ///
  /// A failed redemption keeps the loaded panel on screen — replacing the whole
  /// hub with an error page over one unavailable reward loses the rider's
  /// place for no reason. Only [load] failures are fatal enough for that.
  Future<String?> redeem(RedeemableReward reward) async {
    final current = state;
    if (current is! LoyaltyLoaded || current.isRedeeming) return null;

    emit(current.copyWith(isRedeeming: true));
    try {
      await _redeemReward(reward);
      // Re-read rather than adjusting locally: the balance and ledger the
      // rider sees next must be what Supabase actually persisted.
      emit(LoyaltyLoaded(await _getData(), view: current.view));
      return null;
    } catch (error) {
      emit(current.copyWith(isRedeeming: false));
      return error.toString();
    }
  }
}
