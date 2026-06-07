import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/metric_tile.dart';

import '../cubit/vehicles_state.dart';

class VehicleTopDashboard extends StatelessWidget {
  final VehiclesLoaded state;

  const VehicleTopDashboard({required this.state, super.key});

  @override
  Widget build(BuildContext context) {
    final metrics = [
      ('إجمالي المركبات', '${state.vehicles.length}', 'كل الأسطول'),
      ('المركبات النشطة', '${state.activeCount}', 'جاهزة للتشغيل'),
      ('في الصيانة', '${state.maintenanceCount}', 'متابعة الورشة'),
      ('منتهية الرخصة', '${state.expiredLicenseCount}', 'تحتاج تجديد'),
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
