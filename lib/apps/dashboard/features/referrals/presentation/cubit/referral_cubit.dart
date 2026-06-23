import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/referral_dashboard_data.dart';
import '../../domain/entities/referral_reward_config.dart';
import '../../domain/usecases/referral_usecases.dart';
import 'referral_state.dart';

class ReferralCubit extends Cubit<ReferralState> {
  ReferralCubit({
    required GetReferralRewardConfigUseCase getConfig,
    required UpdateReferralRewardConfigUseCase updateConfig,
    required GetReferralAnalyticsUseCase getAnalytics,
    required GetReferralLeaderboardUseCase getLeaderboard,
    required GetReferralHistoryUseCase getHistory,
    required GetReferralRewardTransactionsUseCase getTransactions,
  }) : _getConfig = getConfig,
       _updateConfig = updateConfig,
       _getAnalytics = getAnalytics,
       _getLeaderboard = getLeaderboard,
       _getHistory = getHistory,
       _getTransactions = getTransactions,
       super(const ReferralInitial());

  final GetReferralRewardConfigUseCase _getConfig;
  final UpdateReferralRewardConfigUseCase _updateConfig;
  final GetReferralAnalyticsUseCase _getAnalytics;
  final GetReferralLeaderboardUseCase _getLeaderboard;
  final GetReferralHistoryUseCase _getHistory;
  final GetReferralRewardTransactionsUseCase _getTransactions;

  Future<void> load() async {
    emit(const ReferralLoading());
    try {
      final config = await _getConfig();
      final analytics = await _getAnalytics();
      final leaderboard = await _getLeaderboard();
      final records = await _getHistory();
      final transactions = await _getTransactions();
      emit(
        ReferralLoaded(
          ReferralDashboardData(
            config: config,
            analytics: analytics,
            leaderboard: leaderboard,
            records: records,
            transactions: transactions,
          ),
        ),
      );
    } catch (error) {
      emit(ReferralError(error.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> saveConfig(ReferralRewardConfig config) async {
    final data = _data();
    if (data == null) return;
    emit(ReferralLoaded(data, isSaving: true));
    try {
      final updated = await _updateConfig(config);
      final newData = data.copyWith(config: updated);
      emit(ReferralActionSuccess('تم حفظ إعدادات المكافآت', newData));
      emit(ReferralLoaded(newData));
    } catch (error) {
      emit(ReferralError(error.toString().replaceAll('Exception: ', '')));
    }
  }

  ReferralDashboardData? _data() {
    final current = state;
    return switch (current) {
      ReferralLoaded() => current.data,
      ReferralActionSuccess() => current.data,
      _ => null,
    };
  }
}
