import 'package:flutter/material.dart';

import 'package:bmt_app/core/widgets/app_card.dart';

class MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Widget? icon;
  final String? trend;

  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.trend,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: scheme.primary.withAlpha(18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: icon!),
                ),
              ],
              const Spacer(),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer.withAlpha(170),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    trend!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSecondaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withAlpha(170),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
