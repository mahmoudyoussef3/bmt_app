import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/routes/client_routes.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../routes/auth_routes.dart';
import 'terms_footer.dart';

/// The welcome screen's call-to-action stack: sign in, create an account, or
/// browse as a guest.
///
/// Email/password is the only authentication this build actually has. A
/// Google/Apple/Phone row used to sit here, but every button opened a "coming
/// soon" sheet — a dead end on the first tap a brand-new user makes, which is
/// the worst possible place for one. It comes back when those providers are
/// really wired up, not before.
class WelcomeActions extends StatelessWidget {
  const WelcomeActions({super.key});

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
