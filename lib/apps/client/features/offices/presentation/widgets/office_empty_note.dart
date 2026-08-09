import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// One section of an office profile with nothing in it.
///
/// A bare sentence floating between two card stacks read as a rendering glitch;
/// giving the note the same panel shape as the cards it replaces keeps the
/// column's rhythm and says "this section is empty", not "this section broke".
///
/// Quiet on purpose: an empty section is a fact, not an alert, so it takes the
/// muted surface rather than the brand colour the cards around it use for the
/// things a rider can actually buy.
class OfficeEmptyNote extends StatelessWidget {
  const OfficeEmptyNote({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ClientSpacing.md),
      decoration: BoxDecoration(
        color: ClientColors.surfaceMutedFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.lg),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ClientColors.surfaceFor(context),
            ),
            child: Icon(
              icon,
              size: 20,
              color: ClientColors.textTertiaryFor(context),
            ),
          ),
          const SizedBox(width: ClientSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: ClientTypography.bodyMedium(context).copyWith(
                color: ClientColors.textSecondaryFor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
