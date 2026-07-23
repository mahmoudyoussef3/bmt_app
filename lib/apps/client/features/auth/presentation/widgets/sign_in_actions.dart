import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../routes/auth_routes.dart';
import 'auth_security_note.dart';
import 'auth_switch_link.dart';

/// The controls below the sign-in card: the submit button, the create-account
/// switch and the security note.
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
        const SizedBox(height: ClientSpacing.xs),
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
