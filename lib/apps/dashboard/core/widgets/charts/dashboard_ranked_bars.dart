import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'chart_models.dart';

/// A ranked list of horizontal bars (e.g. top routes). Expects [data] already
/// sorted in descending order. Pure Flutter — robust and dependency-free.
class DashboardRankedBars extends StatelessWidget {
  final List<ChartDatum> data;

  const DashboardRankedBars({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (data.isEmpty) {
      return Text(
        'لا توجد بيانات كافية',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      );
    }
    final maxValue = data
        .fold<double>(0, (m, d) => d.value > m ? d.value : m)
        .clamp(1, double.infinity);
    return Column(
      children: [
        for (final datum in data)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 130,
                  child: Text(
                    datum.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: (datum.value / maxValue).clamp(0, 1).toDouble(),
                      minHeight: 10,
                      backgroundColor: scheme.surfaceContainerHighest,
                      color: datum.color,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                Text(
                  '${datum.value.toInt()}',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
