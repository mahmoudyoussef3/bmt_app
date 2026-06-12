import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import '../cubit/reports_state.dart';

class ReportTrendChart extends StatelessWidget {
  final ReportsLoaded state;
  const ReportTrendChart({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final trends = state.reportData.trends;
    final scheme = Theme.of(context).colorScheme;

    if (trends.isEmpty) {
      return const SizedBox();
    }

    final double maxVal = trends.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final double maxCeiling = maxVal == 0 ? 1000 : ((maxVal / 50).ceil() * 50).toDouble();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('رسم بياني توضيحي للاتجاهات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                    final double val = maxCeiling * (3 - index) / 3;
                    return Text(
                      val.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 8, color: Colors.grey),
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
                        children: trends.map((e) {
                          final double barPct = maxCeiling == 0 ? 0.0 : e.value / maxCeiling;
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                e.value.toStringAsFixed(0),
                                style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: scheme.primary),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                width: 18,
                                height: (box.maxHeight - 30) * barPct,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [scheme.primary, scheme.primary.withValues(alpha: 0.47)], // ~120/255
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
                                e.key.length > 6 ? e.key.substring(0, 6) : e.key,
                                style: const TextStyle(fontSize: 8, color: Colors.grey),
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
