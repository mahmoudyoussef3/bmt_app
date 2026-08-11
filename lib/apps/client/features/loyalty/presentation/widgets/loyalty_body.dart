import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

import '../cubit/loyalty_cubit.dart';
import '../cubit/loyalty_state.dart';
import 'dashboard/loyalty_dashboard_view.dart';
import 'history/loyalty_history_view.dart';
import 'rewards/loyalty_rewards_view.dart';

/// Renders whichever panel the cubit has selected.
class LoyaltyBody extends StatelessWidget {
  const LoyaltyBody({super.key, required this.state});

  final LoyaltyState state;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      LoyaltyLoading() => const Center(child: CircularProgressIndicator()),
      LoyaltyError(:final message) => ClientErrorCard.fullScreen(
        message: message,
        onRetry: () => context.read<LoyaltyCubit>().load(),
      ),
      final LoyaltyLoaded loaded => AnimatedSwitcher(
        duration: ClientMotion.base,
        
        child: KeyedSubtree(
          key: ValueKey(loaded.view),
          child: _panel(loaded),
        ),
      ),
    };
  }

  Widget _panel(LoyaltyLoaded state) => switch (state.view) {
    LoyaltyView.dashboard => LoyaltyDashboardView(data: state.data),
    LoyaltyView.history => LoyaltyHistoryView(
      transactions: state.data.transactions,
    ),
    LoyaltyView.rewards => LoyaltyRewardsView(
      data: state.data,
      isRedeeming: state.isRedeeming,
    ),
  };
}
