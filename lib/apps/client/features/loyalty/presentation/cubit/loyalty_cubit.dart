import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/loyalty_data.dart';
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

  void redeem(RedeemableReward reward) {
    final current = state;
    if (current is! LoyaltyLoaded) return;
    emit(LoyaltyLoaded(_redeemReward(current.data, reward)));
  }
}
