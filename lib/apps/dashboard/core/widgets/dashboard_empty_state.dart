import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

/// The "nothing here yet" state for a panel inside a dashboard screen.
///
/// Three deliberate differences from the app-wide [EmptyState]:
///
/// * **An icon, not an emoji.** A 56px 📭 is a picture of a mailbox rendered by
///   whatever font the OS ships; it reads as a sticker on an operations console
///   and changes shape per platform. This uses the same [DashboardIcons]
///   vocabulary as the rest of the screen.
/// * **Panel-sized, not page-sized.** It sits *inside* a [DashboardPanel] that
///   already carries the title, so it never repeats it at headline weight.
/// * **It can carry the way out.** An empty section that knows what the operator
///   should do next says so with [action] ("no trips today → create one"),
///   rather than leaving a dead rectangle.
class DashboardEmptyState extends StatelessWidget {
  const DashboardEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;

  /// Optional next step — usually a `TextButton.icon` or `FilledButton.tonal`.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.large,
        horizontal: AppSpacing.medium,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
            ),
            child: Icon(icon, size: 22, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            title,
            textAlign: TextAlign.center,
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.xSmall),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AppSpacing.small),
            action!,
          ],
        ],
      ),
    );
  }
}
