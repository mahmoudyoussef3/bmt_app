import 'package:flutter/material.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

import 'auth_section_card.dart';
import 'auth_validators.dart';
import 'password_strength_meter.dart';
import 'premium_auth_text_field.dart';

/// The "login details" section of the sign-up form: email, password and the
/// live password-strength meter.
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
    return AuthSectionCard(
      title: l10n.auth_loginDetails,
      icon: Icons.lock_person_outlined,
      children: [
        PremiumAuthTextField(
          controller: emailController,
          focusNode: emailFocus,
          labelText: l10n.auth_email,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          onFieldSubmitted: (_) => passwordFocus.requestFocus(),
          validator: (value) => AuthValidators.email(value, l10n),
        ),
        const SizedBox(height: 14),
        PremiumAuthTextField(
          controller: passwordController,
          focusNode: passwordFocus,
          labelText: l10n.auth_password,
          prefixIcon: Icons.lock_outline,
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
