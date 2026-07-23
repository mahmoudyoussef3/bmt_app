import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// An inline, dismissible error surface for auth forms.
///
/// Replaces disruptive error dialogs with a calmer, in-context banner that
/// animates in above the form and can be retried or dismissed. Pass `null`
/// [message] to collapse it away.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message, this.onDismiss});

  final String? message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final text = message;

    return AnimatedSize(
      duration: ClientMotion.base,
      curve: ClientMotion.curve,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: ClientMotion.base,
        child: text == null
            ? const SizedBox(width: double.infinity)
            : Padding(
                key: const ValueKey('auth-error'),
                padding: const EdgeInsets.only(bottom: ClientSpacing.md),
                child: Container(
                  padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 6, 12),
                  decoration: BoxDecoration(
                    color: ClientColors.journeyRed.withAlpha(26),
                    borderRadius: BorderRadius.circular(ClientRadius.md),
                    border: Border.all(
                      color: ClientColors.journeyRed.withAlpha(70),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: ClientColors.journeyRed,
                        size: 20,
                      ),
                      const SizedBox(width: ClientSpacing.sm),
                      Expanded(
                        child: Text(
                          text,
                          style: ClientTypography.bodySmall(context).copyWith(
                            color: ClientColors.textPrimaryFor(context),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (onDismiss != null)
                        IconButton(
                          onPressed: onDismiss,
                          visualDensity: VisualDensity.compact,
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).closeButtonTooltip,
                          icon: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: ClientColors.textSecondaryFor(context),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
