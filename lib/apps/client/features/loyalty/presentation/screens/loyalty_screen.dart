import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';

import '../cubit/loyalty_cubit.dart';
import '../cubit/loyalty_state.dart';
import '../widgets/loyalty_app_bar.dart';
import '../widgets/loyalty_body.dart';
import '../widgets/loyalty_celebration_host.dart';

/// The loyalty hub.
///
/// One route hosting three panels — dashboard, ledger, catalog — whose
/// selection lives in [LoyaltyCubit]'s loaded state rather than in a
/// [StatefulWidget], which is what lets this screen stay stateless. The cubit
/// is loaded by `ClientCubitScopes.loyalty`.
class LoyaltyScreen extends StatelessWidget {
  const LoyaltyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoyaltyCubit, LoyaltyState>(
      builder: (context, state) {
        final view = state is LoyaltyLoaded
            ? state.view
            : LoyaltyView.dashboard;

        return PopScope(
          // A system back closes the open panel first, matching what the app
          // bar's back arrow does — the two used to disagree.
          canPop: view == LoyaltyView.dashboard,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) context.read<LoyaltyCubit>().popView();
          },
          child: Scaffold(
            backgroundColor: ClientColors.backgroundFor(context),
            appBar: LoyaltyAppBar(view: view),
            body: SafeArea(
              child: LoyaltyCelebrationHost(child: LoyaltyBody(state: state)),
            ),
          ),
        );
      },
    );
  }
}
