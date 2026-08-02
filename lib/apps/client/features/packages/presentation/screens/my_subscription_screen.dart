import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';

import '../cubit/my_subscription_cubit.dart';
import '../cubit/my_subscription_state.dart';
import '../widgets/my_subscription/my_subscription_empty_view.dart';
import '../widgets/my_subscription/my_subscription_header_card.dart';
import '../widgets/my_subscription/my_subscription_trips_card.dart';
import '../widgets/my_subscription/my_subscription_validity_card.dart';

/// The rider's own subscription: what they hold, how much of the window is
/// left, and how many trips they have used. Reached from Home's active-package
/// card and quick actions.
///
/// Buying a *new* package happens in the booking wizard's package step, which
/// is where a route exists to price a plan against, so the empty state sends
/// the rider to pick a trip rather than to a catalogue.
class MySubscriptionScreen extends StatelessWidget {
  const MySubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ClientAppBar(title: context.l10n.mySubscription_title),
      body: BlocBuilder<MySubscriptionCubit, MySubscriptionState>(
        builder: (context, state) {
          return switch (state) {
            // A skeleton in the shape of the loaded card stack, so the screen
            // does not jump from a centred spinner to a full list.
            MySubscriptionLoading() => ListView(
              padding: const EdgeInsets.all(20),
              children: const [
                ClientSkeleton(height: 150, borderRadius: 20),
                SizedBox(height: 20),
                ClientSkeleton(height: 120, borderRadius: 20),
                SizedBox(height: 20),
                ClientSkeleton(height: 120, borderRadius: 20),
              ],
            ),
            MySubscriptionError(:final message) => ClientErrorCard.fullScreen(
              message: message,
              onRetry: () => context.read<MySubscriptionCubit>().load(),
            ),
            MySubscriptionEmpty() => MySubscriptionEmptyView(
              onFindTrip: () => Navigator.of(
                context,
              ).pushReplacementNamed(BookingRoutes.popularRoutes),
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
