import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
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
/// The pass leads, in brand blue on the same letterhead the rest of the app
/// uses; the two things it can run out of follow as titled blocks. Buying a
/// *new* package happens in the booking wizard's package step, which is where a
/// route exists to price a plan against, so the empty state sends the rider to
/// pick a trip rather than to a catalogue.
class MySubscriptionScreen extends StatelessWidget {
  const MySubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClientColors.backgroundFor(context),
      appBar: ClientAppBar(title: context.l10n.mySubscription_title),
      body: BlocBuilder<MySubscriptionCubit, MySubscriptionState>(
        builder: (context, state) {
          return switch (state) {
            
            MySubscriptionLoading() => ListView(
              padding: const EdgeInsets.all(ClientSpacing.md),
              children: const [
                ClientSkeleton(height: 190, borderRadius: ClientRadius.lg),
                SizedBox(height: ClientSpacing.lg),
                _SkeletonBlock(),
                SizedBox(height: ClientSpacing.lg),
                _SkeletonBlock(),
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
              padding: const EdgeInsets.fromLTRB(
                ClientSpacing.md,
                ClientSpacing.md,
                ClientSpacing.md,
                ClientSpacing.xl,
              ),
              children: [
                MySubscriptionHeaderCard(subscription: subscription),
                const SizedBox(height: ClientSpacing.lg),
                MySubscriptionValidityCard(subscription: subscription),
                const SizedBox(height: ClientSpacing.lg),
                MySubscriptionTripsCard(subscription: subscription),
              ],
            ),
          };
        },
      ),
    );
  }
}

/// A heading and the card under it, in placeholder form.
class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ClientSkeleton(
            height: 34,
            width: 170,
            borderRadius: ClientRadius.sm,
          ),
        ),
        SizedBox(height: ClientSpacing.sm),
        ClientSkeleton(height: 108, borderRadius: ClientRadius.lg),
      ],
    );
  }
}
