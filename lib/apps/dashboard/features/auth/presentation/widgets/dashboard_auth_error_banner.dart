import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/tokens.dart';

/// A failed sign-in stated in place, above the fields that caused it.
///
/// Replaces the snackbar these screens used to show: a snackbar for a login
/// error times out while the operator is still re-reading what they typed, and
/// it lands at the bottom of a 900px-tall console window, nowhere near the
/// form. This stays until they change something.
class DashboardAuthErrorBanner extends StatelessWidget {
  const DashboardAuthErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
  });

  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final style = DashboardColors.status(context, AppStatusTone.error);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.spaceMd,
        AppTokens.spaceMd,
        AppTokens.spaceSm,
        AppTokens.spaceMd,
      ),
      decoration: BoxDecoration(
        color: style.tint,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(
          color: DashboardColors.statusLine(context, AppStatusTone.error),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(DashboardIcons.attention, size: 20, color: style.accent),
          const SizedBox(width: AppTokens.spaceSm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: style.ink, height: 1.5),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded, size: 18),
              color: style.ink,
              tooltip: 'إخفاء',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    );
  }
}
