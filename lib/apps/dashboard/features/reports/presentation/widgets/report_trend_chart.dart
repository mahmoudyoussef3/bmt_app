import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import '../cubit/reports_state.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';

class ReportTrendChart extends StatelessWidget {
  final ReportsLoaded state;
  const ReportTrendChart({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final trends = state.reportData.trends;
    final occupancy = state.reportData.occupancyTrends;

    if (trends.isEmpty && occupancy.isEmpty) {
      return const SizedBox();
    }

    return Column(
      children: [
        if (trends.isNotEmpty)
          _BarChart(title: 'الاتجاهات', dataPoints: trends, suffix: ''),
        if (trends.isNotEmpty && occupancy.isNotEmpty)
          const SizedBox(height: AppSpacing.medium),
        if (occupancy.isNotEmpty)
          _BarChart(
            title: 'معدل الإشغال بالخط (%)',
            dataPoints: occupancy,
            suffix: '%',
            maxCeiling: 100,
          ),
      ],
    );
  }
}

class _BarChart extends StatelessWidget {
  final String title;
  final List<MapEntry<String, double>> dataPoints;
  final String suffix;
  final double? maxCeiling;

  const _BarChart({
    required this.title,
    required this.dataPoints,
    required this.suffix,
    this.maxCeiling,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final double maxVal = dataPoints
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);
    final double computedCeiling =
        maxCeiling ??
        (maxVal == 0 ? 1000 : ((maxVal / 50).ceil() * 50).toDouble());

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.large),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Y-Axis labels
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(4, (index) {
                    final double val = computedCeiling * (3 - index) / 3;
                    return Text(
                      '${val.toStringAsFixed(0)}$suffix',
                      style: TextStyle(
                        fontSize: 8,
                        color: context.status(AppStatusTone.neutral).ink,
                      ),
                    );
                  }),
                ),
                const SizedBox(width: AppSpacing.small),

                // Chart Bars
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, box) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: dataPoints.map((e) {
                          final double barPct = computedCeiling == 0
                              ? 0.0
                              : e.value / computedCeiling;
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                e.value.toStringAsFixed(0),
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: scheme.primary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                width: 18,
                                height: (box.maxHeight - 30) * barPct,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      scheme.primary,
                                      scheme.primary.withValues(alpha: 0.47),
                                    ], // ~120/255
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    topRight: Radius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                e.key.length > 6
                                    ? e.key.substring(0, 6)
                                    : e.key,
                                style: TextStyle(
                                  fontSize: 8,
                                  color: context
                                      .status(AppStatusTone.neutral)
                                      .ink,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
