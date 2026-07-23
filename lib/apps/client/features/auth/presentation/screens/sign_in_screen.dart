import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../widgets/auth_hero.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/sign_in_bloc_listener.dart';
import '../widgets/sign_in_form.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SignInBlocListener(
      child: AuthScaffold(
        title: l10n.auth_signIn,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthHero(
              title: l10n.auth_welcomeBack,
              subtitle: l10n.auth_signInSubtitle,
            ),
            const SizedBox(height: ClientSpacing.lg),
            const SignInForm(),
          ],
        ),
      ),
    );
  }
}
