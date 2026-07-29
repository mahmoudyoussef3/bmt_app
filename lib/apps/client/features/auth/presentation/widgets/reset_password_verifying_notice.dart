import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Shown while Supabase's deep-link handler is still exchanging the emailed
/// recovery link for a session, before the new-password form can appear.
class ResetPasswordVerifyingNotice extends StatelessWidget {
  const ResetPasswordVerifyingNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ClientSpacing.xxl),
      child: Column(
        children: [
          CircularProgressIndicator(color: ClientColors.primaryFor(context)),
          const SizedBox(height: ClientSpacing.md),
          Text(
            l10n.auth_verifyingResetLink,
            textAlign: TextAlign.center,
            style: ClientTypography.bodyMedium(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
        ],
      ),
    );
  }
}
