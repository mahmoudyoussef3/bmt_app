import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/routes/client_routes.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../routes/auth_routes.dart';
import 'alternative_methods/auth_alternative_methods.dart';
import 'terms_footer.dart';

/// The welcome screen's call-to-action stack: sign in, create an account,
/// browse as a guest — then, below the divider, the methods that are coming.
///
/// ## The order is the message
///
/// Email/password is the only authentication this build actually performs, so
/// it takes the filled primary button and the outlined one under it. The
/// providers sit *after* the "or" rule in the quiet tile form, which is what
/// tells a first-time rider which door is open without a word of explanation.
///
/// A provider row lived here once before and was removed: every button opened a
/// "coming soon" bottom sheet, a dead end on the very first tap a brand-new
/// rider makes. The row is back because that failure has been designed out
/// rather than re-shipped — the tiles carry no gesture detector at all and say
/// "قريباً" up front, so nothing invites a tap that goes nowhere. They become
/// live the moment `AuthMethod.isAvailable` flips.
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
        const SizedBox(height: ClientSpacing.md),
        
        const AuthAlternativeMethods(compact: true),
        const SizedBox(height: ClientSpacing.sm),
        ClientButton.text(
          label: l10n.welcome_continueAsGuest,
          onPressed: () =>
              Navigator.of(context).pushReplacementNamed(ClientRoutes.home),
        ),
        const SizedBox(height: ClientSpacing.xs),
        const TermsFooter(),
      ],
    );
  }
}
