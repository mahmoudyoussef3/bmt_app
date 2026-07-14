import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/routes/client_routes.dart';
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
          onTap: () => onOpenRoute(ClientRoutes.support),
        ),

        // ── Messages: deferred, by request ──────────────────────────────────
        // The rider ↔ captain / support chat is built and routable at
        // `/communication`, but the hub does not advertise it yet. Restore the
        // tile once the chat carries a real unread count and push delivery —
        // until then it would ask the rider to keep opening a screen to check
        // for replies.
        //
        // ProfileHubTile(
        //   icon: Icons.chat_bubble_outline_rounded,
        //   title: l10n.profile_messages,
        //   subtitle: l10n.profile_messagesSubtitle,
        //   onTap: () => onOpenRoute('/communication'),
        // ),
      ],
    );
  }
}

// ── Rewards & loyalty: deferred, by request ───────────────────────────────
// `/rewards` (referrals) and `/loyalty` (points, tiers, wallet) both have
// screens and Supabase tables behind them, but the earning and redemption
// rules are not signed off. The hub therefore shows no balance the rider
// cannot yet spend, and the wallet/points figures were removed from the stats
// row for the same reason. Restore this section — and add the stat back — once
// the rules are settled.
//
// class ProfileRewardsSection extends StatelessWidget {
//   const ProfileRewardsSection({super.key, required this.onOpenRoute});
//
//   final void Function(String route, [Object? arguments]) onOpenRoute;
//
//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//
//     return ProfileSection(
//       title: l10n.profile_sectionRewards,
//       children: [
//         ProfileHubTile(
//           icon: Icons.emoji_events_outlined,
//           title: l10n.profile_rewards,
//           subtitle: l10n.profile_rewardsSubtitle,
//           onTap: () => onOpenRoute('/rewards'),
//         ),
//         ProfileHubTile(
//           icon: Icons.stars_outlined,
//           title: l10n.profile_loyalty,
//           subtitle: l10n.profile_loyaltySubtitle,
//           onTap: () => onOpenRoute('/loyalty'),
//         ),
//       ],
//     );
//   }
// }
