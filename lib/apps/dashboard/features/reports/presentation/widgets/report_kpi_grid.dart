import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/text_themes.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import '../cubit/reports_state.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';

class ReportKpiGrid extends StatelessWidget {
  final ReportsLoaded state;
  const ReportKpiGrid({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final kpis = state.reportData.kpis;
    final keys = kpis.keys.toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double spacing = AppSpacing.small;
        final int columns = constraints.maxWidth < 650 ? 2 : 4;

        if (columns == 2) {
          return Column(
            children: [
              Row(
                children: [
                  if (keys.isNotEmpty)
                    Expanded(
                      child: _KpiCard(
                        label: keys[0],
                        value: kpis[keys[0]]!,
                        color: context.status(AppStatusTone.info).ink,
                      ),
                    ),
                  SizedBox(width: spacing),
                  if (keys.length > 1)
                    Expanded(
                      child: _KpiCard(
                        label: keys[1],
                        value: kpis[keys[1]]!,
                        color: context.status(AppStatusTone.warning).ink,
                      ),
                    ),
                ],
              ),
              SizedBox(height: spacing),
              Row(
                children: [
                  if (keys.length > 2)
                    Expanded(
                      child: _KpiCard(
                        label: keys[2],
                        value: kpis[keys[2]]!,
                        color: context.status(AppStatusTone.success).ink,
                      ),
                    ),
                  SizedBox(width: spacing),
                  if (keys.length > 3)
                    Expanded(
                      child: _KpiCard(
                        label: keys[3],
                        value: kpis[keys[3]]!,
                        color: context.status(AppStatusTone.special).ink,
                      ),
                    ),
                ],
              ),
            ],
          );
        }

        return Row(
          children: List.generate(keys.length, (index) {
            final key = keys[index];
            final color = [
              context.status(AppStatusTone.info).ink,
              context.status(AppStatusTone.warning).ink,
              context.status(AppStatusTone.success).ink,
              context.status(AppStatusTone.special).ink,
            ][index % 4];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: index == 0 ? 0 : spacing / 2,
                ),
                child: _KpiCard(label: key, value: kpis[key]!, color: color),
              ),
            );
          }),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: AppTextThemes.badgeText(
                Theme.of(context).colorScheme,
              ).copyWith(color: color),
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
