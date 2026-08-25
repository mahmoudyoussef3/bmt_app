import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

/// One band of a console form: a named group of fields that reports its own
/// state on its header.
///
/// The header carries a completion badge rather than a decorative tick — it
/// counts the section's own required fields, so an operator scanning a long
/// dialog can see which band still owes something without opening or reading
/// it. A section with nothing mandatory in it says so ("اختياري") instead of
/// showing a permanently unfinished counter.
class DashboardFormSection extends StatelessWidget {
  const DashboardFormSection({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.filled,
    this.total,
    this.trailing,
    this.optional = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  /// Required fields in this section currently passing their rule.
  final int? filled;

  /// Required fields in this section.
  final int? total;

  /// An action that belongs to the section itself (a "reverse direction", an
  /// "add another"). Sits opposite the badge, never in place of it.
  final Widget? trailing;

  /// Marks a whole band as a refinement — documents, notes, images.
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final complete = optional || (total != null && (filled ?? 0) >= total!);
    final accent = complete ? scheme.primary : scheme.onSurfaceVariant;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: complete
                      ? scheme.primary.withAlpha(22)
                      : scheme.surfaceContainerHighest.withAlpha(110),
                  borderRadius: BorderRadius.circular(AppTokens.radius),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.small),
                trailing!,
              ],
              if (total != null || optional) ...[
                const SizedBox(width: AppSpacing.small),
                DashboardFormSectionBadge(
                  filled: filled ?? 0,
                  total: total ?? 0,
                  optional: optional,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          child,
        ],
      ),
    );
  }
}

/// The per-section completion readout — "٣/٤" while a band is unfinished, a
/// tick once it is done, "اختياري" when it never had a requirement.
class DashboardFormSectionBadge extends StatelessWidget {
  const DashboardFormSectionBadge({
    super.key,
    required this.filled,
    required this.total,
    this.optional = false,
  });

  final int filled;
  final int total;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    if (optional) {
      return _pill(
        context,
        label: 'اختياري',
        background: scheme.surfaceContainerHighest.withAlpha(120),
        foreground: scheme.onSurfaceVariant,
        border: scheme.outline.withAlpha(60),
      );
    }

    final done = total > 0 && filled >= total;
    final tone = context.status(
      done ? AppStatusTone.success : AppStatusTone.warning,
    );

    if (done) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.small,
          vertical: AppSpacing.xSmall,
        ),
        decoration: BoxDecoration(
          color: tone.tint,
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          border: Border.all(color: tone.ink.withAlpha(60)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded, size: 15, color: tone.ink),
            const SizedBox(width: 2),
            Text(
              'مكتمل',
              style: text.labelSmall?.copyWith(
                color: tone.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    return _pill(
      context,
      label: '$filled/$total',
      background: tone.tint,
      foreground: tone.ink,
      border: tone.ink.withAlpha(60),
    );
  }

  Widget _pill(
    BuildContext context, {
    required String label,
    required Color background,
    required Color foreground,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: AppSpacing.xSmall,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
