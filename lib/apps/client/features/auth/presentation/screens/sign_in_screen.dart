import 'package:flutter/material.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

import '../widgets/auth_brand_logo.dart';
import '../widgets/premium_auth_scaffold.dart';
import '../widgets/sign_in_bloc_listener.dart';
import '../widgets/sign_in_form.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SignInBlocListener(
      child: PremiumAuthScaffold(
        logo: const AuthBrandLogo(),
        title: l10n.auth_welcomeBack,
        subtitle: l10n.auth_signInHeroSubtitle,
        child: const SignInForm(),
      ),
    );
  }
}
