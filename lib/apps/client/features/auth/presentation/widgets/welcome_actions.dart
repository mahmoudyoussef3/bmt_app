import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/routes/client_routes.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../routes/auth_routes.dart';
import 'social_login_buttons.dart';
import 'terms_footer.dart';
import 'welcome_coming_soon_sheet.dart';
import 'welcome_or_divider.dart';

/// The welcome screen's call-to-action stack: email sign-in / create-account,
/// the social login row (mocked "coming soon"), guest entry and the terms.
class WelcomeActions extends StatelessWidget {
  const WelcomeActions({super.key});

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
        const WelcomeOrDivider(),
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
