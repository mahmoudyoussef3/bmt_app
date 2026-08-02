import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/routes/dashboard_routes.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/entities/dashboard_home_summary.dart';

/// Which lines are filling and which are running empty, over the last month of
/// trips plus everything still scheduled.
///
/// Occupancy, not revenue: two routes can take the same money while one runs
/// half-empty at double the fare, and it is the empty one the operator has to
/// decide about. Cancelled trips are excluded upstream — see
/// [DashboardHomeSummary.topRoutes].
class TopRoutesSection extends StatelessWidget {
  const TopRoutesSection({
    super.key,
    required this.summary,
    required this.onOpenModule,
  });

  final DashboardHomeSummary summary;
  final ValueChanged<String> onOpenModule;

  @override
  Widget build(BuildContext context) {
    final routes = summary.topRoutes();

    return DashboardPanel(
      icon: DashboardIcons.ranking,
      title: 'أداء المسارات',
      subtitle: routes.isEmpty ? null : 'نسبة الإشغال خلال آخر ٣٠ يوماً',
      trailing: TextButton(
        onPressed: () => onOpenModule(DashboardRoutes.routes),
        child: const Text('كل المسارات'),
      ),
      child: routes.isEmpty
          ? const DashboardEmptyState(
              icon: DashboardIcons.routes,
              title: 'لا بيانات إشغال بعد',
              message: 'تحتاج رحلات منفّذة على المسارات لحساب نسبة الإشغال.',
            )
          : Column(
              children: [for (final route in routes) _RouteRow(route: route)],
            ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({required this.route});

  final RouteOccupancy route;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final palette = DashboardChartPalette.of(context);
    final rate = route.occupancyRate.clamp(0.0, 1.0);
    // Three bands, not a gradient: full enough, worth watching, losing money.
    final tone = rate >= 0.7
        ? palette.positive
        : rate >= 0.4
        ? palette.warning
        : palette.negative;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  route.route,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium,
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Text(
                '${(rate * 100).round()}%',
                style: text.labelLarge?.copyWith(
                  color: tone,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
              color: tone,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${route.bookedSeats} من ${route.capacity} مقعد · ${route.trips} رحلة',
            style: text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
