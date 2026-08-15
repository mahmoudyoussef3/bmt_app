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
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 40.0,
        horizontal: AppSpacing.large,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(50),
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        border: Border.all(
          color: scheme.outlineVariant.withAlpha(80),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.large),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primaryContainer.withAlpha(80),
              border: Border.all(
                color: scheme.primary.withAlpha(40),
                width: 6,
              ),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withAlpha(20),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Icon(icon, size: 36, color: scheme.primary),
          ),
          const SizedBox(height: AppSpacing.xLarge),
          Text(
            title,
            textAlign: TextAlign.center,
            style: text.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.small),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xLarge),
              child: Text(
                message!,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AppSpacing.xLarge),
            action!,
          ],
        ],
      ),
    );
  }
}
