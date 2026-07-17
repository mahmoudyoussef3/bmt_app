import 'package:bmt_app/apps/client/core/routes/client_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/localization/locale_cubit.dart';

import '../routes/auth_routes.dart';
import '../widgets/social_login_buttons.dart';
import '../widgets/terms_footer.dart';
import '../widgets/welcome_hero.dart';
import '../widgets/welcome_coming_soon_sheet.dart';

/// The entry screen after onboarding. Email/password is the only real path;
/// Google, Apple and Phone are presented but mocked ("coming soon").
///
/// The direction follows the app locale (RTL for Arabic) — the screen no longer
/// forces LTR, so the Arabic layout mirrors correctly.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClientColors.backgroundFor(context),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _TopBar(),
                        const Spacer(flex: 2),
                        const WelcomeHero(),
                        const Spacer(flex: 3),
                        _Actions(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A one-tap language toggle. With only two supported languages, tapping the
/// pill switches straight to the other one and persists the choice; the label
/// shows the language you'll get, in its own script.
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LocaleCubit>().state.languageCode == 'ar';
    final targetLabel = isArabic ? 'English' : 'العربية';

    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: GestureDetector(
        onTap: () =>
            context.read<LocaleCubit>().changeLocale(isArabic ? 'en' : 'ar'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: ClientColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(ClientRadius.pill),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.language_rounded,
                color: ClientColors.textSecondaryFor(context),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                targetLabel,
                style: ClientTypography.labelSmall(context).copyWith(
                  color: ClientColors.textPrimaryFor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  void _onSocial(BuildContext context, SocialProvider provider) {
    final name = switch (provider) {
      SocialProvider.google => 'Google',
      SocialProvider.apple => 'Apple',
      SocialProvider.phone => context.l10n.welcome_providerPhone,
    };
    showWelcomeComingSoonSheet(context, provider: name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClientButton(
          label: l10n.welcome_continueWithEmail,
          onPressed: () => Navigator.of(context).pushNamed(AuthRoutes.signIn),
          icon: const Icon(Icons.email_rounded, size: 20, color: Colors.white),
        ),
        const SizedBox(height: ClientSpacing.sm),
        ClientButton.secondary(
          label: l10n.welcome_createAccount,
          onPressed: () => Navigator.of(context).pushNamed(AuthRoutes.signUp),
        ),
        const SizedBox(height: ClientSpacing.lg),
        const _OrDivider(),
        const SizedBox(height: ClientSpacing.lg),
        SocialLoginButtons(onSelected: (p) => _onSocial(context, p)),
        const SizedBox(height: ClientSpacing.sm),
        ClientButton.text(
          label: l10n.welcome_continueAsGuest,
          onPressed: () =>
              Navigator.of(context).pushReplacementNamed(ClientRoutes.home),
        ),
        const SizedBox(height: ClientSpacing.sm),
        const TermsFooter(),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Divider(color: ClientColors.borderFor(context), thickness: 1),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            context.l10n.welcome_orContinueWith,
            style: ClientTypography.labelSmall(context).copyWith(
              color: ClientColors.textTertiaryFor(context),
              letterSpacing: 0.4,
            ),
          ),
        ),
        line,
      ],
    );
  }
}
