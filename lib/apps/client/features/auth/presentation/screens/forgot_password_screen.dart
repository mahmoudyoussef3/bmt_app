import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

import '../cubit/forgot_password_cubit.dart';
import '../cubit/forgot_password_state.dart';
import '../widgets/auth_brand_logo.dart';
import '../widgets/forgot_password_bloc_listener.dart';
import '../widgets/forgot_password_request_form.dart';
import '../widgets/forgot_password_success_body.dart';
import '../widgets/premium_auth_scaffold.dart';

/// Password recovery. A stateless shell that swaps between the request form and
/// the "check your email" success view; errors surface via a dialog listener.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ForgotPasswordBlocListener(
      child: BlocBuilder<ForgotPasswordCubit, ForgotPasswordState>(
        buildWhen: (previous, current) =>
            previous.status != current.status ||
            previous.email != current.email ||
            previous.cooldownRemaining != current.cooldownRemaining,
        builder: (context, state) {
          if (state.status == ForgotPasswordStatus.success) {
            return PremiumAuthScaffold(
              logo: const AuthBrandLogo(),
              title: l10n.auth_checkEmailTitle,
              subtitle: l10n.auth_checkEmailMessage(state.email),
              showBack: false,
              child: ForgotPasswordSuccessBody(
                email: state.email,
                cooldownRemaining: state.cooldownRemaining,
                onBackToLogin: () => Navigator.of(context).pop(),
              ),
            );
          }
          return PremiumAuthScaffold(
            logo: const AuthBrandLogo(),
            title: l10n.auth_forgotPasswordTitle,
            subtitle: l10n.auth_forgotPasswordSubtitle,
            child: const ForgotPasswordRequestForm(),
          );
        },
      ),
    );
  }
}
