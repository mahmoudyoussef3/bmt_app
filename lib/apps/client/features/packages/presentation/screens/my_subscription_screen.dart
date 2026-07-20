import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../cubit/my_subscription_cubit.dart';
import '../cubit/my_subscription_state.dart';
import '../routes/packages_routes.dart';
import '../widgets/my_subscription/my_subscription_empty_view.dart';
import '../widgets/my_subscription/my_subscription_header_card.dart';
import '../widgets/my_subscription/my_subscription_trips_card.dart';
import '../widgets/my_subscription/my_subscription_validity_card.dart';

/// The rider's own subscription: what they hold, how much of the window is
/// left, and how many trips they have used. Reached from Home's active-package
/// card — buying a *new* package is [PackagesRoutes.subscription], a separate
/// flow this screen never opens except as a fallback when the rider has none.
class MySubscriptionScreen extends StatelessWidget {
  const MySubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          context.l10n.mySubscription_title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocBuilder<MySubscriptionCubit, MySubscriptionState>(
        builder: (context, state) {
          return switch (state) {
            MySubscriptionLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            MySubscriptionError(:final message) => ClientErrorCard.fullScreen(
              message: message,
              onRetry: () => context.read<MySubscriptionCubit>().load(),
            ),
            MySubscriptionEmpty() => MySubscriptionEmptyView(
              onBrowsePackages: () => Navigator.of(
                context,
              ).pushReplacementNamed(PackagesRoutes.subscription),
            ),
            MySubscriptionLoaded(:final subscription) => ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                MySubscriptionHeaderCard(subscription: subscription),
                const SizedBox(height: 20),
                MySubscriptionValidityCard(subscription: subscription),
                const SizedBox(height: 20),
                MySubscriptionTripsCard(subscription: subscription),
                const SizedBox(height: 40),
              ],
            ),
          };
        },
      ),
    );
  }
}
