import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/packages_cubit.dart';
import '../cubit/packages_state.dart';
import '../routes/subscription_arguments.dart';
import '../widgets/subscription_app_bar.dart';
import '../widgets/subscription_background.dart';
import '../widgets/subscription_body.dart';

/// Package catalogue and detail flow. Payment lives in its own feature, so this
/// screen ends by handing the chosen plan to the checkout route.
class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key, required this.arguments});

  final SubscriptionArguments arguments;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PackagesCubit, PackagesState>(
      builder: (context, state) {
        final step = state is PackagesLoaded
            ? state.step
            : SubscriptionStep.listing;
        final scheme = Theme.of(context).colorScheme;

        // System back walks the flow back a pane before it leaves the screen,
        // matching the app bar's back button.
        return PopScope(
          canPop: step == SubscriptionStep.listing,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) context.read<PackagesCubit>().goBack();
          },
          child: Scaffold(
            backgroundColor: scheme.surfaceContainerHighest,
            appBar: SubscriptionAppBar(step: step),
            body: Stack(
              children: [
                const SubscriptionBackground(),
                Positioned.fill(
                  child: SubscriptionBody(state: state, arguments: arguments),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
