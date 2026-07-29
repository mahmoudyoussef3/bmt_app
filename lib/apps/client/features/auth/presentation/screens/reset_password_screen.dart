import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../cubit/reset_password_cubit.dart';
import '../cubit/reset_password_state.dart';
import '../widgets/auth_hero.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/reset_password_bloc_listener.dart';
import '../widgets/reset_password_form.dart';
import '../widgets/reset_password_link_invalid_notice.dart';
import '../widgets/reset_password_verifying_notice.dart';

/// Reached only via the `easyway://reset-password/` deep link. Waits for
/// Supabase to turn the emailed recovery link into a session, then shows the
/// new-password form.
class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ResetPasswordBlocListener(
      child: BlocBuilder<ResetPasswordCubit, ResetPasswordState>(
        buildWhen: (previous, current) =>
            previous.status != current.status &&
            (previous.status == ResetPasswordStatus.verifying ||
                current.status == ResetPasswordStatus.verifying ||
                previous.status == ResetPasswordStatus.linkInvalid ||
                current.status == ResetPasswordStatus.linkInvalid),
        builder: (context, state) {
          return AuthScaffold(
            title: l10n.auth_resetPasswordTitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthHero(subtitle: l10n.auth_resetPasswordSubtitle),
                const SizedBox(height: ClientSpacing.lg),
                switch (state.status) {
                  ResetPasswordStatus.verifying =>
                    const ResetPasswordVerifyingNotice(),
                  ResetPasswordStatus.linkInvalid =>
                    const ResetPasswordLinkInvalidNotice(),
                  _ => const ResetPasswordForm(),
                },
              ],
            ),
          );
        },
      ),
    );
  }
}
