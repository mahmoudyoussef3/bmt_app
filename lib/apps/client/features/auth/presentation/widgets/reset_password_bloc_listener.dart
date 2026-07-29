import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/app_dialogs.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

import '../cubit/reset_password_cubit.dart';
import '../cubit/reset_password_state.dart';
import '../routes/auth_routes.dart';

/// Surfaces the outcome of a password-update attempt: a confirming snackbar
/// then a hard navigation to sign-in on success, an error dialog on failure.
class ResetPasswordBlocListener extends StatelessWidget {
  const ResetPasswordBlocListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocListener<ResetPasswordCubit, ResetPasswordState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        final l10n = context.l10n;
        if (state.status == ResetPasswordStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.auth_passwordUpdatedSnack),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AuthRoutes.signIn, (_) => false);
          return;
        }
        if (state.status == ResetPasswordStatus.failure) {
          AppDialogs.showErrorDialog(
            context,
            title: l10n.auth_resetPasswordFailed,
            message: _localizedError(l10n, state.errorMessage),
          );
        }
      },
      child: child,
    );
  }

  String _localizedError(AppLocalizations l10n, String? error) {
    if (error == null || error.trim().isEmpty) return l10n.auth_unknownError;
    return error;
  }
}
