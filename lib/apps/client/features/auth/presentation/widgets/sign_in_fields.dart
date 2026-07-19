import 'package:flutter/material.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

import 'auth_validators.dart';
import 'premium_auth_text_field.dart';

/// The email + password inputs of the sign-in form.
class SignInFields extends StatelessWidget {
  const SignInFields({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.emailFocus,
    required this.passwordFocus,
    required this.onSubmit,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocus;
  final FocusNode passwordFocus;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          onFieldSubmitted: (_) => onSubmit(),
          validator: (value) => AuthValidators.required(value, l10n),
        ),
      ],
    );
  }
}
