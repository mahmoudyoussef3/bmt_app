import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/routes/client_routes.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/cubit/auth_state.dart';
import 'package:bmt_app/apps/client/features/profile/domain/entities/client_profile.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/widgets/logout_button.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/widgets/profile_account_section.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/widgets/profile_header_card.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/widgets/profile_legal_section.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/widgets/profile_notice_card.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/widgets/profile_preferences_section.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/widgets/profile_stats_row.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/widgets/profile_support_section.dart';
import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

/// The hub, top to bottom: who you are, your numbers, anything that needs
/// doing, then what you can change — and finally the way out.
class ProfileHubBody extends StatelessWidget {
  const ProfileHubBody({
    super.key,
    required this.profile,
    required this.onOpenRoute,
    required this.onEdit,
    required this.onLanguage,
    required this.onAppearance,
    required this.onLogout,
  });

  final ClientProfile profile;
  final void Function(String route, [Object? arguments]) onOpenRoute;
  final VoidCallback onEdit;
  final VoidCallback onLanguage;
  final VoidCallback onAppearance;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isSigningOut =
        context.watch<ClientAuthCubit>().state.signOutStatus ==
        AuthSubmissionStatus.loading;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppLayout.pagePaddingWithTop,
      children: [
        ProfileHeaderCard(profile: profile, onEdit: onEdit),
        const SizedBox(height: AppLayout.spaceLg),
        ProfileStatsRow(profile: profile),

        ..._notices(context, l10n),

        const SizedBox(height: AppLayout.spaceXl),
        ProfileAccountSection(onEdit: onEdit, onOpenRoute: onOpenRoute),
        const SizedBox(height: AppLayout.spaceXl),
        ProfilePreferencesSection(
          onLanguage: onLanguage,
          onAppearance: onAppearance,
        ),
        const SizedBox(height: AppLayout.spaceXl),
        ProfileSupportSection(onOpenRoute: onOpenRoute),
        const SizedBox(height: AppLayout.spaceXl),
        ProfileLegalSection(onOpenRoute: onOpenRoute),

        const SizedBox(height: AppLayout.spaceXl),
        LogoutButton(isLoading: isSigningOut, onPressed: onLogout),

        // Clears the bottom navigation bar.
        const SizedBox(height: 96),
      ],
    );
  }

  /// Nudges appear only when the rider has something to act on, so the hub does
  /// not nag an account that is already in order.
  List<Widget> _notices(BuildContext context, AppLocalizations l10n) {
    final package = profile.activePackage;

    return [
      if (!profile.isComplete) ...[
        const SizedBox(height: AppLayout.spaceLg),
        ProfileNoticeCard(
          icon: Icons.person_search_outlined,
          title: l10n.profile_completeTitle,
          body: l10n.profile_completeBody,
          actionLabel: l10n.profile_completeAction,
          onAction: onEdit,
        ),
      ],
      if (package != null && package.isExpiringSoon) ...[
        const SizedBox(height: AppLayout.spaceLg),
        ProfileNoticeCard(
          icon: Icons.schedule_rounded,
          title: l10n.profile_statPackage,
          body: l10n.profile_packageExpiringSoon(
            package.name,
            package.routeName,
            package.daysRemaining ?? 0,
          ),
          actionLabel: l10n.profile_packageRenew,
          onAction: () => onOpenRoute(ClientRoutes.subscription),
        ),
      ],
    ];
  }
}
