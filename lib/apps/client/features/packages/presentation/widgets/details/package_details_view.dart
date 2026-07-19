import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/payments/presentation/routes/payment_routes.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../cubit/packages_state.dart';
import '../../routes/subscription_arguments.dart';
import '../subscription_sticky_cta.dart';
import 'package_benefits_section.dart';
import 'package_detail_header_card.dart';
import 'package_route_limits_card.dart';
import 'package_terms_card.dart';

/// Step two: what the chosen package includes, ending at checkout.
class PackageDetailsView extends StatelessWidget {
  const PackageDetailsView({
    super.key,
    required this.state,
    required this.arguments,
  });

  final PackagesLoaded state;
  final SubscriptionArguments arguments;

  @override
  Widget build(BuildContext context) {
    final package = state.selectedPackage;
    if (package == null) return const SizedBox.shrink();

    return Column(
      children: [
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              PackageDetailHeaderCard(package: package),
              const SizedBox(height: 18),
              const PackageBenefitsSection(),
              const SizedBox(height: 20),
              PackageRouteLimitsCard(package: package),
              const SizedBox(height: 20),
              PackageTermsCard(package: package),
              const SizedBox(height: 40),
            ],
          ),
        ),
        SubscriptionStickyCta(
          label: context.l10n.packages_continueToPayment,
          onPressed: () => Navigator.of(context).pushNamed(
            PaymentRoutes.checkout,
            arguments: arguments.checkoutPayload(package),
          ),
        ),
      ],
    );
  }
}
