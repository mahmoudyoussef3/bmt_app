import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/fleet_workspace.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/domain/entities/driver_operations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class FleetAnalyticsCharts extends StatelessWidget {
  final FleetWorkspace workspace;

  const FleetAnalyticsCharts({super.key, required this.workspace});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;
        
        Widget chart1 = SizedBox(
          width: isNarrow ? double.infinity : null,
          height: 320,
          child: _DriverStatusChart(workspace: workspace),
        );
        
        Widget chart2 = SizedBox(
          width: isNarrow ? double.infinity : null,
          height: 320,
          child: _VehicleStatusChart(workspace: workspace),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              chart1,
              const SizedBox(height: 24),
              chart2,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: chart1),
            const SizedBox(width: 24),
            Expanded(child: chart2),
          ],
        );
      },
    );
  }
}

class _DriverStatusChart extends StatelessWidget {
  final FleetWorkspace workspace;

  const _DriverStatusChart({required this.workspace});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    int available = 0;
    int assigned = 0;
    int needsAttention = 0;
    int suspended = 0;

    for (final driver in workspace.drivers) {
      if (driver.status == FleetDriverStatus.suspended) {
        suspended++;
        continue;
      }
      final snapshot = DriverOperations.snapshot(driver, workspace);
      if (snapshot.canAssign) {
        available++;
      } else if (snapshot.status == DriverOperationalStatus.assigned) {
        assigned++;
      } else if (snapshot.requiresAttention) {
        needsAttention++;
      }
    }

    final total = available + assigned + needsAttention + suspended;

    return _ChartCard(
      title: 'حالة السائقين',
      icon: Icons.people_alt_rounded,
      child: total == 0
          ? const Center(child: Text('لا توجد بيانات'))
          : Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 40,
                      sections: [
                        if (available > 0)
                          PieChartSectionData(
                            color: Colors.green.shade400,
                            value: available.toDouble(),
                            title: '$available',
                            radius: 50,
                            titleStyle: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        if (assigned > 0)
                          PieChartSectionData(
                            color: scheme.primary,
                            value: assigned.toDouble(),
                            title: '$assigned',
                            radius: 50,
                            titleStyle: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        if (needsAttention > 0)
                          PieChartSectionData(
                            color: Colors.orange.shade400,
                            value: needsAttention.toDouble(),
                            title: '$needsAttention',
                            radius: 50,
                            titleStyle: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        if (suspended > 0)
                          PieChartSectionData(
                            color: scheme.error,
                            value: suspended.toDouble(),
                            title: '$suspended',
                            radius: 50,
                            titleStyle: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Indicator(color: Colors.green.shade400, text: 'متاح الآن'),
                      const SizedBox(height: 8),
                      _Indicator(color: scheme.primary, text: 'معين لمركبة'),
                      const SizedBox(height: 8),
                      _Indicator(color: Colors.orange.shade400, text: 'يحتاج متابعة'),
                      const SizedBox(height: 8),
                      _Indicator(color: scheme.error, text: 'موقوف'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _VehicleStatusChart extends StatelessWidget {
  final FleetWorkspace workspace;

  const _VehicleStatusChart({required this.workspace});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    int available = 0;
    int maintenance = 0;
    int suspended = 0;
    int archived = 0;

    for (final vehicle in workspace.vehicles) {
      switch (vehicle.status) {
        case FleetVehicleStatus.active:
          available++;
          break;
        case FleetVehicleStatus.maintenance:
          maintenance++;
          break;
        case FleetVehicleStatus.suspended:
          suspended++;
          break;
        case FleetVehicleStatus.archived:
          archived++;
          break;
      }
    }

    final maxY = [available, maintenance, suspended, archived].reduce((a, b) => a > b ? a : b).toDouble();

    return _ChartCard(
      title: 'حالة المركبات',
      icon: Icons.directions_bus_rounded,
      child: Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 8, right: 8, left: 16),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY == 0 ? 5 : maxY + (maxY * 0.2),
            barTouchData: BarTouchData(enabled: false),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final text = switch (value.toInt()) {
                      0 => 'نشطة',
                      1 => 'صيانة',
                      2 => 'خارج الخدمة',
                      3 => 'مباعة',
                      _ => '',
                    };
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        text,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: scheme.outlineVariant.withAlpha(50),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: [
              _makeGroupData(0, available.toDouble(), Colors.green.shade400),
              _makeGroupData(1, maintenance.toDouble(), Colors.orange.shade400),
              _makeGroupData(2, suspended.toDouble(), scheme.error),
              _makeGroupData(3, archived.toDouble(), scheme.outline),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 24,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 0,
            color: color.withAlpha(20),
          ),
        ),
      ],
      showingTooltipIndicators: y > 0 ? [0] : [],
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withAlpha(80)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withAlpha(10),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: scheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  final Color color;
  final String text;

  const _Indicator({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
