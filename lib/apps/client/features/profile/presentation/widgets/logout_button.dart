import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

/// Ends the session. Deliberately not a primary button: it is the one action on
/// this screen the rider cannot undo with the same tap, so it reads as
/// destructive rather than as the screen's happy path.
class LogoutButton extends StatelessWidget {
  const LogoutButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    ClientColors.journeyRed,
                  ),
                ),
              )
            : const Icon(Icons.logout_rounded, size: 20),
        label: Text(l10n.profile_logout),
        style: OutlinedButton.styleFrom(
          foregroundColor: ClientColors.journeyRed,
          side: BorderSide(
            color: ClientColors.journeyRed.withAlpha(isLoading ? 90 : 160),
          ),
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ClientRadius.pill),
          ),
          textStyle: ClientTypography.labelLarge(context),
        ),
      ),
    );
  }
}
