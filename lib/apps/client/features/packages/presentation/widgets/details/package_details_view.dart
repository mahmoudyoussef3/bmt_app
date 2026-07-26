import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:bmt_app/apps/client/features/payments/presentation/routes/payment_routes.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../cubit/packages_state.dart';
import '../../routes/subscription_arguments.dart';
import '../subscription_sticky_cta.dart';
import 'package_benefits_section.dart';
import 'package_detail_header_card.dart';
import 'package_provider_office_card.dart';
import 'package_route_limits_card.dart';
import 'package_terms_card.dart';

/// Step two: what the chosen package includes and who provides it. From a
/// booking context it ends at checkout; opened as pure discovery it points the
/// rider at a trip first, since a subscription is always bound to a route.
class PackageDetailsView extends StatelessWidget {
  const PackageDetailsView({
    super.key,
    required this.state,
    required this.arguments,
  });

  final PackagesLoaded state;
  final SubscriptionArguments arguments;

  void _onSubscribe(BuildContext context) {
    if (arguments.hasBookingContext) {
      final package = state.selectedPackage;
      if (package == null) return;
      Navigator.of(context).pushNamed(
        PaymentRoutes.checkout,
        arguments: arguments.checkoutPayload(package),
      );
      return;
    }
    // No trip picked yet — a subscription needs a route to price and bind to,
    // so send the rider to choose one. This reuses the existing booking flow
    // rather than inventing a package-only checkout.
    Navigator.of(context).pushNamed(BookingRoutes.popularRoutes);
  }

  @override
  Widget build(BuildContext context) {
    final package = state.selectedPackage;
    if (package == null) return const SizedBox.shrink();

    final l10n = context.l10n;
    final ctaLabel = arguments.hasBookingContext
        ? l10n.packages_continueToPayment
        : l10n.packages_chooseTripToSubscribe;

    return Column(
      children: [
        Expanded(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              PackageDetailHeaderCard(package: package),
              const SizedBox(height: 18),
              PackageProviderOfficeCard(package: package),
              const SizedBox(height: 20),
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
          label: ctaLabel,
          onPressed: () => _onSubscribe(context),
        ),
      ],
    );
  }
}
