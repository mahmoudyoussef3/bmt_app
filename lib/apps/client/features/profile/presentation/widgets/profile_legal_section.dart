import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/routes/client_routes.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/widgets/profile_hub_tile.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/widgets/profile_section.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

/// What the rider agreed to. Both documents ship with the build, so they open
/// even when the rider is offline.
class ProfileLegalSection extends StatelessWidget {
  const ProfileLegalSection({super.key, required this.onOpenRoute});

  final void Function(String route, [Object? arguments]) onOpenRoute;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ProfileSection(
      title: l10n.profile_sectionLegal,
      children: [
        ProfileHubTile(
          icon: Icons.description_outlined,
          title: l10n.profile_terms,
          onTap: () => onOpenRoute(ClientRoutes.terms),
        ),
        ProfileHubTile(
          icon: Icons.privacy_tip_outlined,
          title: l10n.profile_privacy,
          onTap: () => onOpenRoute(ClientRoutes.privacy),
        ),
      ],
    );
  }
}
