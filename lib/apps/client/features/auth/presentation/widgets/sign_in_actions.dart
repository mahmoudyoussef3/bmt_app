import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../routes/auth_routes.dart';
import 'alternative_methods/auth_alternative_methods.dart';
import 'auth_security_note.dart';
import 'auth_switch_link.dart';

/// The controls below the sign-in card: the submit button, the alternative
/// sign-in methods, the create-account switch and the security note.
///
/// The order is the hierarchy. "Sign in" is the working method and gets the
/// filled button directly under the credentials the rider just typed; the "or"
/// divider and the provider rows come after it, so nothing competes with the
/// action that is one tap from done. The switch to sign-up stays last, where a
/// rider only looks once the sign-in attempt is not the answer.
///
/// Full-width rows here rather than the welcome screen's tiles: this screen
/// scrolls, so there is room for the form riders recognise from every other
/// app, and a label is worth more than an icon when a method is not yet live.
class SignInActions extends StatelessWidget {
  const SignInActions({
    super.key,
    required this.isLoading,
    required this.onSubmit,
  });

  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClientButton(
          label: isLoading ? l10n.auth_signingIn : l10n.auth_signIn,
          onPressed: isLoading ? null : onSubmit,
          isLoading: isLoading,
        ),
        const SizedBox(height: ClientSpacing.lg),
        const AuthAlternativeMethods(),
        const SizedBox(height: ClientSpacing.md),
        AuthSwitchLink(
          text: l10n.auth_noAccount,
          actionText: l10n.auth_signUp,
          onTap: isLoading
              ? null
              : () => Navigator.of(
                  context,
                ).pushReplacementNamed(AuthRoutes.signUp),
        ),
        const SizedBox(height: ClientSpacing.xs),
        AuthSecurityNote(text: l10n.auth_signInSecurityNote),
      ],
    );
  }
}
