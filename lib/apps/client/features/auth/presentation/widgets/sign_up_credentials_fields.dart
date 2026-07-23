import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import 'auth_text_field.dart';
import 'auth_validators.dart';
import 'password_strength_meter.dart';

/// What the rider will sign in with: email, password and the live
/// password-strength meter.
class SignUpCredentialsFields extends StatelessWidget {
  const SignUpCredentialsFields({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.emailFocus,
    required this.passwordFocus,
    required this.onPasswordSubmitted,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocus;
  final FocusNode passwordFocus;
  final VoidCallback onPasswordSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthTextField(
          controller: emailController,
          focusNode: emailFocus,
          label: l10n.auth_email,
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          onFieldSubmitted: (_) => passwordFocus.requestFocus(),
          validator: (value) => AuthValidators.email(value, l10n),
        ),
        const SizedBox(height: ClientSpacing.sm),
        AuthTextField(
          controller: passwordController,
          focusNode: passwordFocus,
          label: l10n.auth_password,
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          onFieldSubmitted: (_) => onPasswordSubmitted(),
          validator: (value) => AuthValidators.password(value, l10n),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: passwordController,
          builder: (context, value, _) =>
              PasswordStrengthMeter(password: value.text),
        ),
      ],
    );
  }
}
