import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../routes/auth_routes.dart';

/// Shown when the recovery link never produced a session — expired, already
/// used, or opened outside the deep link (e.g. the screen reached directly).
class ResetPasswordLinkInvalidNotice extends StatelessWidget {
  const ResetPasswordLinkInvalidNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ClientErrorCard(
      message: l10n.auth_resetLinkInvalid,
      retryLabel: l10n.auth_backToLogin,
      onRetry: () => Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AuthRoutes.signIn, (_) => false),
    );
  }
}
