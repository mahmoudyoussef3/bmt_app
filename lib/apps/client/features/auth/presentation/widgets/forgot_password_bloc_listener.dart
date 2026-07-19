import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/app_dialogs.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

import '../cubit/forgot_password_cubit.dart';
import '../cubit/forgot_password_state.dart';

/// Surfaces a "reset link failed" dialog when the request errors. Retry
/// re-sends to the email already held by the cubit, so it works from either the
/// request form or the success view.
class ForgotPasswordBlocListener extends StatelessWidget {
  const ForgotPasswordBlocListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ForgotPasswordCubit, ForgotPasswordState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        if (state.status != ForgotPasswordStatus.failure) return;
        final l10n = context.l10n;
        AppDialogs.showErrorDialog(
          context,
          title: l10n.auth_recoveryLinkFailed,
          message: _localizedError(l10n, state.errorMessage),
          onRetry: () => context.read<ForgotPasswordCubit>().submitEmail(),
        );
      },
      child: child,
    );
  }

  String _localizedError(AppLocalizations l10n, String? error) {
    if (error == 'RateLimit') return l10n.auth_rateLimited;
    if (error == null || error.trim().isEmpty) return l10n.auth_unknownError;
    return error;
  }
}
