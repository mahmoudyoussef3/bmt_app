import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import '../widgets/kpi_card.dart';
import '../widgets/app_card.dart';
import '../widgets/status_chip.dart';
import '../cubit/kpi_cubit.dart';
import '../cubit/kpi_state.dart';

class OpsHomePage extends StatefulWidget {
  const OpsHomePage({super.key});

  @override
  State<OpsHomePage> createState() => _OpsHomePageState();
}

class _OpsHomePageState extends State<OpsHomePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<KpiCubit>().loadKpis());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Operations Home')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final isNarrow = w < 860;
            final actionCols = w < 680 ? 1 : (w < 1100 ? 2 : 4);
            final kpiWidth = math.min(300, math.max(180, w * 0.24)).toDouble();

            return Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.large),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        scheme.primary.withOpacity(0.16),
                        scheme.secondary.withOpacity(0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
                    border: Border.all(color: scheme.outline.withOpacity(0.28)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Operations Command Center',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: AppSpacing.xSmall),
                                Text(
                                  'Live service quality, ticket backlog, and field performance in one place.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: scheme.onSurface.withOpacity(
                                          0.78,
                                        ),
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.medium),
                          StatusChip(
                            label: 'Live',
                            color: Colors.green.shade600,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      Wrap(
                        spacing: AppSpacing.small,
                        runSpacing: AppSpacing.small,
                        children: const [
                          _MiniStat(label: 'SLA Today', value: '96.8%'),
                          _MiniStat(label: 'Backlog', value: '42'),
                          _MiniStat(label: 'Escalations', value: '3'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.large),
                _SectionHeader(
                  title: 'Operational KPIs',
                  subtitle:
                      'Realtime indicators for trips, drivers, and service health',
                  trailing: IconButton(
                    onPressed: () => context.read<KpiCubit>().loadKpis(),
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh KPIs',
                  ),
                ),
                const SizedBox(height: AppSpacing.small),
                _KpiStrip(
                  isNarrow: isNarrow,
                  cardWidth: kpiWidth,
                  mapKpiToStyle: _mapKpiToStyle,
                ),
                const SizedBox(height: AppSpacing.large),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: actionCols,
                    crossAxisSpacing: AppSpacing.medium,
                    mainAxisSpacing: AppSpacing.medium,
                    childAspectRatio: w < 680 ? 3.8 : 2.2,
                    children: [
                      _ActionTile(
                        title: 'Open Ticket',
                        subtitle:
                            'Create a new support case and assign priority.',
                        icon: Icons.support_agent_rounded,
                        tone: scheme.primary,
                        onPressed: () => _showActionToast('Open Ticket'),
                      ),
                      _ActionTile(
                        title: 'Assign Driver',
                        subtitle:
                            'Re-route and assign nearest available driver.',
                        icon: Icons.route_rounded,
                        tone: scheme.tertiary,
                        onPressed: () => _showActionToast('Assign Driver'),
                      ),
                      _ActionTile(
                        title: 'Escalation Queue',
                        subtitle: 'Review priority incidents requiring action.',
                        icon: Icons.priority_high_rounded,
                        tone: Colors.orange,
                        onPressed: () => _showActionToast('Escalation Queue'),
                      ),
                      _ActionTile(
                        title: 'Broadcast Alert',
                        subtitle:
                            'Notify field teams and impacted riders quickly.',
                        icon: Icons.campaign_rounded,
                        tone: Colors.red.shade400,
                        onPressed: () => _showActionToast('Broadcast Alert'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showActionToast(String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label action clicked')));
  }

  Map<String, Object> _mapKpiToStyle(String id) {
    switch (id) {
      case 'active_trips':
        return {'color': Colors.blue, 'icon': Icons.directions_bus};
      case 'delayed_trips':
        return {'color': Colors.orange, 'icon': Icons.timer};
      case 'completed_today':
        return {'color': Colors.green, 'icon': Icons.check_circle};
      case 'cancelled_bookings':
        return {'color': Colors.red, 'icon': Icons.cancel};
      case 'active_drivers':
        return {'color': Colors.teal, 'icon': Icons.person};
      case 'revenue_today':
        return {'color': Colors.purple, 'icon': Icons.attach_money};
      default:
        return {'color': Colors.grey, 'icon': Icons.info};
    }
  }
}

class _KpiStrip extends StatelessWidget {
  final bool isNarrow;
  final double cardWidth;
  final Map<String, Object> Function(String id) mapKpiToStyle;

  const _KpiStrip({
    required this.isNarrow,
    required this.cardWidth,
    required this.mapKpiToStyle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 116,
      child: BlocBuilder<KpiCubit, KpiState>(
        builder: (context, state) {
          if (state is KpiLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is KpiError) {
            return AppCard(title: 'KPI Error', child: Text(state.message));
          }

          final kpis = (state as KpiLoaded).kpis;
          if (kpis.isEmpty) {
            return const AppCard(
              title: 'KPIs',
              child: Text('No KPI data available'),
            );
          }

          if (isNarrow) {
            return ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kpis.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppSpacing.medium),
              itemBuilder: (context, i) {
                final k = kpis[i];
                final mapped = mapKpiToStyle(k.id);
                return SizedBox(
                  width: cardWidth,
                  child: KpiCard(
                    title: k.label,
                    value: k.value,
                    color: mapped['color'] as Color,
                    icon: mapped['icon'] as IconData,
                  ),
                );
              },
            );
          }

          final colCount = kpis.length >= 4 ? 4 : kpis.length;
          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: kpis.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: colCount,
              crossAxisSpacing: AppSpacing.medium,
              mainAxisSpacing: AppSpacing.medium,
              childAspectRatio: 2.6,
            ),
            itemBuilder: (context, i) {
              final k = kpis[i];
              final mapped = mapKpiToStyle(k.id);
              return KpiCard(
                title: k.label,
                value: k.value,
                color: mapped['color'] as Color,
                icon: mapped['icon'] as IconData,
              );
            },
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xSmall),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.72),
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color tone;
  final VoidCallback onPressed;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tone,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tone.withOpacity(0.14),
              borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
            ),
            child: Icon(icon, color: tone),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xSmall),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onPressed,
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: title,
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(0.52),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: scheme.outline.withOpacity(0.18)),
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall,
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(color: scheme.onSurface.withOpacity(0.72)),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
