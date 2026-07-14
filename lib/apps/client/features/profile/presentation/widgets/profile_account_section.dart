import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/routes/client_routes.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/widgets/profile_hub_tile.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/widgets/profile_section.dart';
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
        ProfileHubTile(
          icon: Icons.card_membership_outlined,
          title: l10n.profile_subscription,
          subtitle: l10n.profile_subscriptionSubtitle,
          onTap: () => onOpenRoute(ClientRoutes.subscription),
        ),
        ProfileHubTile(
          icon: Icons.confirmation_number_outlined,
          title: l10n.profile_myTrips,
          subtitle: l10n.profile_myTripsSubtitle,
          onTap: () => onOpenRoute(ClientRoutes.myTrips),
        ),
      ],
    );
  }
}
