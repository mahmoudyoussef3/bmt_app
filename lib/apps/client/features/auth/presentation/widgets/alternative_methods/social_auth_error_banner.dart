import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../cubit/social_auth_cubit.dart';
import '../../cubit/social_auth_state.dart';
import '../auth_error_banner.dart';
import 'auth_method_failure_message.dart';

/// The error surface for the alternative sign-in methods.
///
/// Reuses [AuthErrorBanner] — the calm, dismissible, in-form banner the
/// email/password screens use — rather than a dialog, so a failed Google
/// attempt reads the same as a failed password and does not interrupt.
///
/// Collapses to nothing for [AuthMethodFailure.cancelled], because
/// [authMethodFailureMessage] returns null for it: the rider closed the
/// provider sheet themselves and does not need to be told.
///
/// Nothing can put a failure here in this build — the provider buttons are
/// inert — but the wiring is the point: the states are already rendered, so
/// switching a provider on does not also mean designing its error path.
class SocialAuthErrorBanner extends StatelessWidget {
  const SocialAuthErrorBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SocialAuthCubit, SocialAuthState>(
      buildWhen: (previous, current) => previous.failure != current.failure,
      builder: (context, state) {
        final failure = state.failure;
        return AuthErrorBanner(
          message: failure == null
              ? null
              : authMethodFailureMessage(failure, context.l10n),
          onDismiss: context.read<SocialAuthCubit>().dismissError,
        );
      },
    );
  }
}
