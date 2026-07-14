import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

/// Asks before ending the session. Returns `true` only when the rider
/// explicitly confirms; dismissing the dialog is a "no".
class LogoutConfirmDialog extends StatelessWidget {
  const LogoutConfirmDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const LogoutConfirmDialog(),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppLayout.radiusLg),
      ),
      backgroundColor: ClientColors.surfaceFor(context),
      icon: Container(
        padding: const EdgeInsets.all(AppLayout.spaceMd),
        decoration: BoxDecoration(
          color: ClientColors.journeyRed.withAlpha(28),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.logout_rounded,
          color: ClientColors.journeyRed,
          size: 26,
        ),
      ),
      title: Text(
        l10n.profile_logoutTitle,
        textAlign: TextAlign.center,
        style: ClientTypography.headingSmall(context),
      ),
      content: Text(
        l10n.profile_logoutBody,
        textAlign: TextAlign.center,
        style: ClientTypography.bodySmall(
          context,
        ).copyWith(color: ClientColors.textSecondaryFor(context), height: 1.5),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: ClientColors.journeyRed,
            foregroundColor: ClientColors.textInverse,
          ),
          child: Text(l10n.profile_logout),
        ),
      ],
    );
  }
}
