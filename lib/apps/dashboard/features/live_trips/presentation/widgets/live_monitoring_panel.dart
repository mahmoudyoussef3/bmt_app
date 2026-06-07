import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/progress_bar.dart';

import '../../domain/entities/live_trip.dart';

class LiveMonitoringPanel extends StatelessWidget {
  final LiveTrip trip;

  const LiveMonitoringPanel({required this.trip, super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _MapPanel(trip: trip),
        const SizedBox(height: AppSpacing.medium),
        _DriverStatusPanel(trip: trip),
        const SizedBox(height: AppSpacing.medium),
        _TimelinePanel(trip: trip),
        const SizedBox(height: AppSpacing.medium),
        _AlertsPanel(alerts: trip.alerts),
      ],
    );
  }
}

class _MapPanel extends StatelessWidget {
  final LiveTrip trip;

  const _MapPanel({required this.trip});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Live Map', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.medium),
          Container(
            height: 280,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppTokens.radius),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Center(
                    child: Icon(
                      Icons.map_outlined,
                      size: 82,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Positioned(
                  top: 28,
                  right: 32,
                  child: _MapPill(label: trip.currentStation),
                ),
                Positioned(
                  bottom: 38,
                  left: 44,
                  child: _MapPill(label: trip.nextStation),
                ),
                Positioned(
                  right: 150,
                  bottom: 92,
                  child: _VehicleMarker(label: trip.vehicle),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverStatusPanel extends StatelessWidget {
  final LiveTrip trip;

  const _DriverStatusPanel({required this.trip});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Driver Status', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.medium),
          Row(
            children: [
              const CircleAvatar(radius: 24, child: Icon(Icons.person_outline)),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.driver,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xSmall),
                    Text(trip.driverStatus),
                  ],
                ),
              ),
              Text('ETA ${trip.eta}'),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          AppProgressBar(progress: trip.progress / 100),
        ],
      ),
    );
  }
}

class _TimelinePanel extends StatelessWidget {
  final LiveTrip trip;

  const _TimelinePanel({required this.trip});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Trip Timeline', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.medium),
          ...trip.timeline.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.medium),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: item.done
                        ? scheme.primaryContainer
                        : scheme.surfaceContainerHighest,
                    child: Icon(
                      item.done ? Icons.check : Icons.more_horiz,
                      size: 15,
                      color: item.done
                          ? scheme.onPrimaryContainer
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xSmall),
                        Text('${item.time} • ${item.status}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertsPanel extends StatelessWidget {
  final List<LiveTripAlert> alerts;

  const _AlertsPanel({required this.alerts});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Alerts', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.medium),
          if (alerts.isEmpty)
            const Text('لا توجد تنبيهات على هذه الرحلة.')
          else
            ...alerts.map(
              (alert) => ListTile(
                leading: Icon(
                  alert.urgent
                      ? Icons.priority_high_outlined
                      : Icons.notifications_outlined,
                ),
                title: Text(alert.type.label),
                subtitle: Text(alert.message),
                trailing: Text(alert.time),
              ),
            ),
        ],
      ),
    );
  }
}

class _MapPill extends StatelessWidget {
  final String label;

  const _MapPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.small,
          vertical: AppSpacing.xSmall,
        ),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: scheme.onPrimaryContainer),
        ),
      ),
    );
  }
}

class _VehicleMarker extends StatelessWidget {
  final String label;

  const _VehicleMarker({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.small),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_bus_outlined,
              color: scheme.onPrimary,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.xSmall),
            Text(label, style: TextStyle(color: scheme.onPrimary)),
          ],
        ),
      ),
    );
  }
}
