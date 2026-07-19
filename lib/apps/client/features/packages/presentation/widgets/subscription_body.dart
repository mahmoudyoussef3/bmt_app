import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

import '../cubit/packages_state.dart';
import '../routes/subscription_arguments.dart';
import 'details/package_details_view.dart';
import 'listing/packages_listing_view.dart';
import 'packages_loading_view.dart';

/// Renders the pane for the current state, cross-fading between steps.
class SubscriptionBody extends StatelessWidget {
  const SubscriptionBody({
    super.key,
    required this.state,
    required this.arguments,
  });

  final PackagesState state;
  final SubscriptionArguments arguments;

  @override
  Widget build(BuildContext context) {
    // Bound to a local so the sealed subtypes promote inside the switch and the
    // branches need no casts.
    final state = this.state;

    return AnimatedSwitcher(
      duration: ClientMotion.base,
      child: switch (state) {
        PackagesLoading() => const PackagesLoadingView(
          key: ValueKey('loading'),
        ),
        PackagesError() => Center(
          key: const ValueKey('error'),
          child: ClientErrorCard.fullScreen(message: state.message),
        ),
        PackagesLoaded(step: SubscriptionStep.listing) => PackagesListingView(
          key: const ValueKey('listing'),
          state: state,
          arguments: arguments,
        ),
        PackagesLoaded() => PackageDetailsView(
          key: const ValueKey('details'),
          state: state,
          arguments: arguments,
        ),
      },
    );
  }
}
