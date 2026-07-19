import 'package:flutter/material.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

import '../routes/auth_routes.dart';
import 'auth_security_note.dart';
import 'auth_switch_link.dart';
import 'premium_auth_button.dart';

/// The submit button, "already have an account" switch and security note at the
/// foot of the sign-up form.
class SignUpActions extends StatelessWidget {
  const SignUpActions({
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
        PremiumAuthButton(
          text: isLoading ? l10n.auth_creatingAccount : l10n.auth_createAccount,
          onPressed: isLoading ? null : onSubmit,
          isLoading: isLoading,
        ),
        const SizedBox(height: 18),
        AuthSwitchLink(
          text: l10n.auth_alreadyHaveAccount,
          actionText: l10n.auth_signIn,
          onTap: isLoading
              ? null
              : () => Navigator.of(
                  context,
                ).pushReplacementNamed(AuthRoutes.signIn),
        ),
        const SizedBox(height: 8),
        AuthSecurityNote(text: l10n.auth_signUpSecurityNote),
      ],
    );
  }
}
