import 'package:bmt_app/apps/client/features/support/presentation/routes/support_routes.dart';
import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/profile/presentation/widgets/profile_hub_tile.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/widgets/profile_section.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

/// How the rider reaches a human.
class ProfileSupportSection extends StatelessWidget {
  const ProfileSupportSection({super.key, required this.onOpenRoute});

  final void Function(String route, [Object? arguments]) onOpenRoute;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ProfileSection(
      title: l10n.profile_sectionSupport,
      children: [
        ProfileHubTile(
          icon: Icons.support_agent_outlined,
          title: l10n.profile_helpCenter,
          subtitle: l10n.profile_helpCenterSubtitle,
          onTap: () => onOpenRoute(SupportRoutes.center),
        ),

      ],
    );
  }
}
