import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

import '../cubit/forgot_password_cubit.dart';
import 'forgot_password_email_help_card.dart';
import 'forgot_password_success_mail_card.dart';
import 'premium_auth_button.dart';

/// The forgot-password success view body: confirmation card, back-to-login,
/// and a resend button gated by the cubit's cooldown.
class ForgotPasswordSuccessBody extends StatelessWidget {
  const ForgotPasswordSuccessBody({
    super.key,
    required this.email,
    required this.cooldownRemaining,
    required this.onBackToLogin,
  });

  final String email;
  final int cooldownRemaining;
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canResend = cooldownRemaining == 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ForgotPasswordSuccessMailCard(email: email),
        const SizedBox(height: 24),
        PremiumAuthButton(
          text: l10n.auth_backToLogin,
          onPressed: onBackToLogin,
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: canResend
              ? () => context.read<ForgotPasswordCubit>().submitEmail()
              : null,
          icon: Icon(
            canResend ? Icons.refresh_rounded : Icons.hourglass_bottom_rounded,
            size: 18,
          ),
          label: Text(
            canResend
                ? l10n.auth_resendLink
                : l10n.auth_resendIn(cooldownRemaining),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const ForgotPasswordEmailHelpCard(),
      ],
    );
  }
}
