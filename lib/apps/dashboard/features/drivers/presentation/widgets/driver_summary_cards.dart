import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/metric_tile.dart';

import '../../domain/entities/driver.dart';

class DriverSummaryCards extends StatelessWidget {
  final List<Driver> drivers;

  const DriverSummaryCards({required this.drivers, super.key});

  @override
  Widget build(BuildContext context) {
    final active = drivers
        .where((driver) => driver.status == DriverStatus.active)
        .length;
    final pending = drivers
        .where((driver) => driver.status == DriverStatus.pendingDocuments)
        .length;
    final suspended = drivers
        .where((driver) => driver.status == DriverStatus.suspended)
        .length;
    final averageRating = drivers.isEmpty
        ? 0
        : drivers.map((driver) => driver.rating).reduce((a, b) => a + b) /
              drivers.length;

    final metrics = [
      ('سائقين نشطين', '$active', 'جاهزين للتشغيل'),
      ('مراجعة مستندات', '$pending', 'يحتاج تدخل إداري'),
      ('موقوفين', '$suspended', 'في الأرشيف'),
      ('متوسط التقييم', averageRating.toStringAsFixed(1), 'آخر ٣٠ يوم'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 4
            : constraints.maxWidth >= 640
            ? 2
            : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.medium,
            mainAxisSpacing: AppSpacing.medium,
            mainAxisExtent: 116,
          ),
          itemBuilder: (context, index) {
            final metric = metrics[index];
            return MetricTile(
              label: metric.$1,
              value: metric.$2,
              trend: metric.$3,
            );
          },
        );
      },
    );
  }
}
