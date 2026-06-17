import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import '../cubit/reports_state.dart';

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
                  if (keys.isNotEmpty) Expanded(child: _KpiCard(label: keys[0], value: kpis[keys[0]]!, color: AppStatusColors.onInfoContainer)),
                  SizedBox(width: spacing),
                  if (keys.length > 1) Expanded(child: _KpiCard(label: keys[1], value: kpis[keys[1]]!, color: AppStatusColors.onWarningContainer)),
                ],
              ),
              SizedBox(height: spacing),
              Row(
                children: [
                  if (keys.length > 2) Expanded(child: _KpiCard(label: keys[2], value: kpis[keys[2]]!, color: AppStatusColors.onSuccessContainer)),
                  SizedBox(width: spacing),
                  if (keys.length > 3) Expanded(child: _KpiCard(label: keys[3], value: kpis[keys[3]]!, color: AppStatusColors.onSpecialContainer)),
                ],
              ),
            ],
          );
        }

        return Row(
          children: List.generate(keys.length, (index) {
            final key = keys[index];
            final color = [AppStatusColors.onInfoContainer, AppStatusColors.onWarningContainer, AppStatusColors.onSuccessContainer, AppStatusColors.onSpecialContainer][index % 4];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: index == 0 ? 0 : spacing / 2),
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.15 : 0.1), // ~40/255 or 25/255
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
