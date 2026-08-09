import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../widgets/auth_hero.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/phone_otp/phone_login_form.dart';

/// Step one of signing in by SMS: which number should the code go to.
///
/// Sits on the same [AuthScaffold] as sign-in and sign-up, so a rider who
/// arrives here from either of them stays in one product rather than landing on
/// a screen that looks borrowed.
class PhoneLoginScreen extends StatelessWidget {
  const PhoneLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuthScaffold(
      title: l10n.auth_phoneLoginTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHero(subtitle: l10n.auth_phoneLoginSubtitle),
          const SizedBox(height: ClientSpacing.lg),
          const PhoneLoginForm(),
        ],
      ),
    );
  }
}
