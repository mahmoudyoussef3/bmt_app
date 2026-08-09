import 'package:bmt_app/apps/client/features/packages/presentation/routes/packages_routes.dart';
import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/trips/presentation/routes/trips_routes.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/widgets/profile_hub_tile.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/widgets/profile_section.dart';
import 'package:bmt_app/apps/client/features/wallet/presentation/routes/wallet_routes.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

/// What the rider owns: their details, the package they pay for, their trips.
class ProfileAccountSection extends StatelessWidget {
  const ProfileAccountSection({
    super.key,
    required this.onEdit,
    required this.onOpenRoute,
  });

  final VoidCallback onEdit;
  final void Function(String route, [Object? arguments]) onOpenRoute;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ProfileSection(
      title: l10n.profile_sectionAccount,
      children: [
        ProfileHubTile(
          icon: Icons.person_outline_rounded,
          title: l10n.profile_editProfile,
          subtitle: l10n.profile_editProfileSubtitle,
          onTap: onEdit,
        ),
        // The rider's money. `/wallet` was built, routed and deep-linked from
        // every refund notification, but nothing in the hub opened it — a
        // rider who had not been sent a notification had no way to see what an
        // office owed them. The tile names the balance without printing a
        // figure: the wallet screen reads its numbers from the server, and the
        // hub must not quote a total it has not loaded.
        ProfileHubTile(
          icon: Icons.account_balance_wallet_outlined,
          title: l10n.profile_wallet,
          subtitle: l10n.profile_walletSubtitle,
          onTap: () => onOpenRoute(WalletRoutes.wallet),
        ),
        ProfileHubTile(
          icon: Icons.card_membership_outlined,
          title: l10n.profile_subscription,
          subtitle: l10n.profile_subscriptionSubtitle,
          onTap: () => onOpenRoute(PackagesRoutes.mySubscription),
        ),
        ProfileHubTile(
          icon: Icons.confirmation_number_outlined,
          title: l10n.profile_myTrips,
          subtitle: l10n.profile_myTripsSubtitle,
          onTap: () => onOpenRoute(TripsRoutes.myTrips),
        ),
      ],
    );
  }
}
