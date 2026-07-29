import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/pressable_scale.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

/// The bottom call-to-action on the account-success screen: "get started" for a
/// live session, "back to sign in" when email confirmation is pending.
class AuthSuccessCta extends StatelessWidget {
  const AuthSuccessCta({
    super.key,
    required this.created,
    required this.onContinue,
  });

  final bool created;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PressableScale(
      onTap: onContinue,
      child: FilledButton(
        onPressed: onContinue,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          created ? l10n.authSuccess_getStarted : l10n.authSuccess_backToSignIn,
          style: ClientTypography.labelLarge(
            context,
          ).copyWith(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
