import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../cubit/forgot_password_cubit.dart';
import '../cubit/forgot_password_state.dart';
import '../widgets/auth_hero.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/forgot_password_bloc_listener.dart';
import '../widgets/forgot_password_request_form.dart';
import '../widgets/forgot_password_success_body.dart';

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
          final sent = state.status == ForgotPasswordStatus.success;
          return AuthScaffold(
            title: sent
                ? l10n.auth_checkEmailTitle
                : l10n.auth_forgotPasswordTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthHero(
                  subtitle: sent
                      ? l10n.auth_checkEmailMessage(state.email)
                      : l10n.auth_forgotPasswordSubtitle,
                ),
                const SizedBox(height: ClientSpacing.lg),
                if (sent)
                  ForgotPasswordSuccessBody(
                    email: state.email,
                    cooldownRemaining: state.cooldownRemaining,
                    onBackToLogin: () => Navigator.of(context).pop(),
                  )
                else
                  const ForgotPasswordRequestForm(),
              ],
            ),
          );
        },
      ),
    );
  }
}
