import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/cubit/auth_state.dart';
import 'package:bmt_app/apps/client/features/auth/presentation/routes/auth_routes.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/cubit/profile_state.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/widgets/logout_confirm_dialog.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/widgets/profile_hub_body.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/widgets/profile_sheets.dart';
import 'package:bmt_app/apps/client/features/profile/presentation/widgets/profile_skeleton.dart';
import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

/// The rider's account hub: identity, their own numbers, everything they can
/// change about the app, the legal documents, and the way out.
///
/// This screen absorbed what used to be a separate Settings screen. A rider
/// does not think of "my details" and "my language" as living in different
/// places, and the split cost them a tap to reach either.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.onOpenRoute});

  final void Function(String route, [Object? arguments]) onOpenRoute;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final maxW = AppLayout.maxContentWidth(MediaQuery.sizeOf(context).width);

    return Scaffold(
      backgroundColor: ClientColors.backgroundFor(context),
      body: MultiBlocListener(
        listeners: [
          BlocListener<ClientAuthCubit, ClientAuthState>(
            listenWhen: (previous, current) =>
                previous.signOutStatus != current.signOutStatus,
            listener: _onSignOutStateChanged,
          ),
          BlocListener<ProfileCubit, ProfileState>(
            listenWhen: (previous, current) =>
                current is ProfileLoaded &&
                (current.editStatus == ProfileEditStatus.success ||
                    current.refreshFailed),
            listener: _onProfileFeedback,
          ),
        ],
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: BlocBuilder<ProfileCubit, ProfileState>(
              builder: (context, state) => switch (state) {
                ProfileLoading() => const ProfileSkeleton(),
                ProfileUnauthenticated() => const _SignInRequiredPrompt(),
                ProfileError(:final message) => ClientErrorCard.fullScreen(
                  message: message,
                  retryLabel: l10n.common_tryAgain,
                  onRetry: () => context.read<ProfileCubit>().load(),
                ),
                ProfileLoaded(:final profile) => RefreshIndicator(
                  onRefresh: () => context.read<ProfileCubit>().load(),
                  child: ProfileHubBody(
                    profile: profile,
                    onOpenRoute: widget.onOpenRoute,
                    onEdit: () => ProfileSheets.edit(context, profile),
                    onLanguage: () => ProfileSheets.language(context),
                    onAppearance: () => ProfileSheets.appearance(context),
                    onLogout: _confirmLogout,
                  ),
                ),
              },
            ),
          ),
        ),
      ),
    );
  }

  /// The session is gone, so the rider must leave every authenticated screen
  /// with it. Signing in makes the shell the root of the navigation stack, so
  /// clearing the Supabase session alone would leave the rider sitting on a
  /// signed-out profile — the stack has to be reset explicitly.
  void _onSignOutStateChanged(BuildContext context, ClientAuthState state) {
    if (state.signOutStatus == AuthSubmissionStatus.success) {
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamedAndRemoveUntil(AuthRoutes.welcome, (_) => false);
      return;
    }

    if (state.signOutStatus == AuthSubmissionStatus.failure) {
      final l10n = AppLocalizations.of(context)!;
      _showSnack(state.signOutError ?? l10n.profile_logoutFailed);
    }
  }

  void _onProfileFeedback(BuildContext context, ProfileState state) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<ProfileCubit>();
    final loaded = state as ProfileLoaded;

    if (loaded.editStatus == ProfileEditStatus.success) {
      cubit.resetEditStatus();
      _showSnack(l10n.profile_saved);
    } else if (loaded.refreshFailed) {
      cubit.dismissRefreshFailure();
      _showSnack(l10n.profile_refreshFailed);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await LogoutConfirmDialog.show(context);
    if (!confirmed || !mounted) return;
    context.read<ClientAuthCubit>().signOut();
  }
}

/// Shown instead of [ClientErrorCard] when the rider is in guest mode: there
/// is no session for Retry to recover, so the only honest affordance is a
/// path to sign in.
class _SignInRequiredPrompt extends StatelessWidget {
  const _SignInRequiredPrompt();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppLayout.spaceLg,
          vertical: AppLayout.spaceXl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: ClientColors.primaryFor(context).withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_outline_rounded,
                size: 32,
                color: ClientColors.primaryFor(context),
              ),
            ),
            const SizedBox(height: AppLayout.spaceLg),
            Text(
              l10n.profile_signInRequiredTitle,
              textAlign: TextAlign.center,
              style: ClientTypography.headingSmall(
                context,
              ).copyWith(color: ClientColors.textPrimaryFor(context)),
            ),
            const SizedBox(height: AppLayout.spaceSm),
            Text(
              l10n.profile_signInRequiredBody,
              textAlign: TextAlign.center,
              style: ClientTypography.bodySmall(
                context,
              ).copyWith(color: ClientColors.textSecondaryFor(context)),
            ),
            const SizedBox(height: AppLayout.spaceXl),
            ClientButton(
              label: l10n.profile_signInCta,
              onPressed: () =>
                  Navigator.of(context).pushNamed(AuthRoutes.signIn),
            ),
          ],
        ),
      ),
    );
  }
}
