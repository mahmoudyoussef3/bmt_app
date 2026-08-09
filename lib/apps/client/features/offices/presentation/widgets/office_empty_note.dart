import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// One section of an office profile with nothing in it.
///
/// A bare sentence floating between two card stacks read as a rendering glitch;
/// giving the note the same panel shape as the cards it replaces keeps the
/// column's rhythm and says "this section is empty", not "this section broke".
class OfficeEmptyNote extends StatelessWidget {
  const OfficeEmptyNote({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ClientSpacing.md),
      decoration: BoxDecoration(
        color: ClientColors.primaryContainerFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: ClientColors.onPrimaryContainerFor(context).withAlpha(180)),
          const SizedBox(width: ClientSpacing.md),
          Expanded(
            child: Text(
              message,
              style: ClientTypography.bodyMedium(context).copyWith(
                color: ClientColors.onPrimaryContainerFor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
