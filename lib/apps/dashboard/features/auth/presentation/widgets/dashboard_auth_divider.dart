import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/core/theme/tokens.dart';

/// The hairline that separates a form's primary action from the door to the
/// *other* signed-out screen.
///
/// Shared by both screens so the hand-off reads the same in each direction:
/// sign-in offers "register an office" under it, registration offers "sign in".
class DashboardAuthDivider extends StatelessWidget {
  const DashboardAuthDivider({super.key, this.label = 'أو'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: Divider(color: DashboardColors.divider(context), height: 1),
    );
    return Row(
      children: [
        line,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.spaceMd),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: DashboardColors.faintInk(context),
            ),
          ),
        ),
        line,
      ],
    );
  }
}
