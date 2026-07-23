import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../widgets/auth_hero.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/sign_up_form.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthScaffold(
      title: l10n.auth_createAccountTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHero(
            title: l10n.auth_welcomeTitle,
            subtitle: l10n.auth_signUpSubtitle,
          ),
          const SizedBox(height: ClientSpacing.lg),
          const SignUpForm(),
        ],
      ),
    );
  }
}
