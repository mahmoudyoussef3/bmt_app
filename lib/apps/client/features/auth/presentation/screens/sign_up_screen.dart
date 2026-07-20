import 'package:flutter/material.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

import '../widgets/auth_brand_logo.dart';
import '../widgets/premium_auth_scaffold.dart';
import '../widgets/sign_up_form.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PremiumAuthScaffold(
      logo: const AuthBrandLogo(),
      title: l10n.auth_createAccountTitle,
      subtitle: l10n.auth_signUpHeroSubtitle,
      child: const SignUpForm(),
    );
  }
}
