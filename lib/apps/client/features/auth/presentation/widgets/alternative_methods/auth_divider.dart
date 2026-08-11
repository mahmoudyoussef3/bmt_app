import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// A rule with a word in the middle — `──────── أو ────────`.
///
/// It is the whole of the hierarchy message on these screens: everything above
/// it works today, everything below it is an alternative. Kept deliberately
/// quiet (hairline rules, tertiary text) so it separates without competing with
/// the primary call to action right above it.
class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Divider(
        height: 1,
        thickness: 1,
        color: ClientColors.borderFor(context),
      ),
    );

    return Row(
      children: [
        line,
        
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: ClientSpacing.sm),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ClientTypography.labelSmall(
                context,
              ).copyWith(color: ClientColors.textTertiaryFor(context)),
            ),
          ),
        ),
        line,
      ],
    );
  }
}
