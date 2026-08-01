import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_search_query.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../cubit/packages_state.dart';
import '../../routes/subscription_arguments.dart';
import '../subscription_sticky_cta.dart';
import 'package_benefits_section.dart';
import 'package_detail_header_card.dart';
import 'package_how_it_works_card.dart';
import 'package_price_note_card.dart';
import 'package_provider_office_card.dart';
import 'package_route_limits_card.dart';
import 'package_terms_card.dart';

/// Step two: what the chosen package is, how buying it works, and who provides
/// it — ending at a route picker, because a subscription is always bound to a
/// route and priced on it.
///
/// The blocks run in the order a rider's questions arrive: which plan is this,
/// what does it cost, how do I get it, what do I actually get, whose is it, and
/// what am I agreeing to.
class PackageDetailsView extends StatelessWidget {
  const PackageDetailsView({
    super.key,
    required this.state,
    required this.arguments,
  });

  final PackagesLoaded state;
  final SubscriptionArguments arguments;

  /// A subscription needs a route to price and bind to, so the rider picks one
  /// first and buys the plan inside the booking wizard's package step. There is
  /// no package-only checkout to branch to — see [SubscriptionArguments]. The
  /// reviewed package rides along as [BookingSearchQuery.initialPackageId] so
  /// it opens pre-selected once the wizard reaches its package step.
  void _onSubscribe(BuildContext context) {
    final package = state.selectedPackage;
    Navigator.of(context).pushNamed(
      BookingRoutes.popularRoutes,
      arguments: BookingSearchQuery(
        initialPackageId: package?.id,
      ).toArguments(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final package = state.selectedPackage;
    if (package == null) return const SizedBox.shrink();

    final l10n = context.l10n;

    return Column(
      children: [
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              ClientSpacing.md,
              ClientSpacing.sm,
              ClientSpacing.md,
              ClientSpacing.lg,
            ),
            children: [
              _Block(child: PackageDetailHeaderCard(package: package)),
              const _Block(child: PackagePriceNoteCard()),
              _Block(child: PackageProviderOfficeCard(package: package)),
              const _Block(child: PackageHowItWorksCard()),
              const _Block(child: PackageBenefitsSection()),
              _Block(child: PackageRouteLimitsCard(package: package)),
              _Block(child: PackageTermsCard(package: package)),
            ],
          ),
        ),
        SubscriptionStickyCta(
          label: l10n.packages_chooseTripToSubscribe,
          note: l10n.packages_priceAtBooking,
          onPressed: () => _onSubscribe(context),
        ),
      ],
    );
  }
}

/// Uniform spacing between blocks, so a block never has to know what follows
/// it.
class _Block extends StatelessWidget {
  const _Block({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ClientSpacing.md),
      child: child,
    );
  }
}
