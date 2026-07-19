import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The "or continue with" divider between the primary auth buttons and the
/// social login row on the welcome screen.
class WelcomeOrDivider extends StatelessWidget {
  const WelcomeOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Divider(color: ClientColors.borderFor(context), thickness: 1),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            context.l10n.welcome_orContinueWith,
            style: ClientTypography.labelSmall(context).copyWith(
              color: ClientColors.textTertiaryFor(context),
              letterSpacing: 0.4,
            ),
          ),
        ),
        line,
      ],
    );
  }
}
