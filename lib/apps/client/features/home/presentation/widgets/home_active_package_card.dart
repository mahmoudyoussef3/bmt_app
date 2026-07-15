import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/badge.dart';

/// The subscription the rider is riding on. Home renders this only when one
/// exists — plans they have not bought are left to the subscription screen.
class HomeActivePackageCard extends StatelessWidget {
  const HomeActivePackageCard({
    super.key,
    required this.package,
    required this.onTap,
  });

  final HomeActivePackageData package;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withAlpha(isDark ? 40 : 60)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: scheme.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.card_membership_rounded,
                        color: scheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _Titles(package: package, scheme: scheme),
                    ),
                    const AppBadge(text: 'ACTIVE'),
                  ],
                ),
                if (package.endDate != null) ...[
                  const SizedBox(height: 24),
                  _Validity(package: package, scheme: scheme),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Titles extends StatelessWidget {
  const _Titles({required this.package, required this.scheme});

  final HomeActivePackageData package;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          package.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (package.routeLabel.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            package.routeLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall?.copyWith(
              color: scheme.onSurface.withAlpha(160),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

/// How much of the subscription window is left — the only progress the
/// `subscriptions` table can honestly report.
class _Validity extends StatelessWidget {
  const _Validity({required this.package, required this.scheme});

  final HomeActivePackageData package;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final remaining = package.remainingDays;
    final l10n = context.l10n;
    final label = remaining == 0
        ? l10n.home_expiresToday
        : remaining == 1
        ? l10n.home_dayLeft
        : l10n.home_daysLeft(remaining);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Valid until ${_formatDate(package.endDate!)}',
              style: text.bodySmall?.copyWith(
                color: scheme.onSurface.withAlpha(160),
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: text.titleSmall?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        if (package.totalDays > 0) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: package.remainingRatio,
              minHeight: 8,
              backgroundColor: scheme.primary.withAlpha(20),
              valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
            ),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
}
