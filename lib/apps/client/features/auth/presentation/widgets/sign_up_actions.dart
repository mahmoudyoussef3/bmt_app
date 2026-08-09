import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../domain/entities/auth_method.dart';
import '../routes/auth_routes.dart';
import 'alternative_methods/auth_alternative_methods.dart';
import 'auth_security_note.dart';
import 'auth_switch_link.dart';

/// The submit button, the alternative ways to open an account, the "already
/// have an account" switch and the security note at the foot of the sign-up
/// form.
///
/// Google and Apple only — no phone here. Signing up needs a name and a phone
/// number to book a seat against, and Google and Apple both hand those over as
/// part of consent, so they genuinely shorten the form. An SMS code proves a
/// number and nothing else: the rider would verify, then be dropped into the
/// same fields they were trying to skip. Phone belongs on sign-*in*, where the
/// account already exists.
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
        ClientButton(
          label: isLoading
              ? l10n.auth_creatingAccount
              : l10n.auth_createAccount,
          onPressed: isLoading ? null : onSubmit,
          isLoading: isLoading,
        ),
        const SizedBox(height: ClientSpacing.lg),
        const AuthAlternativeMethods(
          methods: [AuthMethod.google, AuthMethod.apple],
        ),
        const SizedBox(height: ClientSpacing.md),
        AuthSwitchLink(
          text: l10n.auth_alreadyHaveAccount,
          actionText: l10n.auth_signIn,
          onTap: isLoading
              ? null
              : () => Navigator.of(
                  context,
                ).pushReplacementNamed(AuthRoutes.signIn),
        ),
        const SizedBox(height: ClientSpacing.xs),
        AuthSecurityNote(text: l10n.auth_signUpSecurityNote),
      ],
    );
  }
}
