import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import 'auth_text_field.dart';
import 'auth_validators.dart';

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
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          onFieldSubmitted: (_) => onSubmit(),
          validator: (value) => AuthValidators.required(value, l10n),
        ),
      ],
    );
  }
}
