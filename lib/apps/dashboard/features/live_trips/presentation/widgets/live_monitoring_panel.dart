import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/progress_bar.dart';
import '../../domain/entities/live_trip.dart';
import '../cubit/live_trips_cubit.dart';

class LiveMonitoringPanel extends StatelessWidget {
  const LiveMonitoringPanel({
    super.key,
    required this.trip,
    required this.actionLoading,
  });

  final LiveTrip trip;
  final bool actionLoading;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<LiveTripsCubit>();

    return ListView(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      children: [
        LiveTripActionsBar(
          trip: trip,
          actionLoading: actionLoading,
          onStart: cubit.startSelectedTrip,
          onPause: cubit.pauseSelectedTrip,
          onResume: cubit.resumeSelectedTrip,
          onComplete: cubit.completeSelectedTrip,
          onCallDriver: cubit.callSelectedDriver,
          onMessageDriver: cubit.messageSelectedDriver,
        ),
        const SizedBox(height: AppSpacing.medium),
        LiveTripMapPanel(trip: trip),
        const SizedBox(height: AppSpacing.medium),
        LiveTripRouteTimeline(
          trip: trip,
          onArrived: cubit.markCurrentPointArrived,
          onCompleted: cubit.markCurrentPointCompleted,
          onSkipped: cubit.skipCurrentPoint,
        ),
        const SizedBox(height: AppSpacing.medium),
        LiveTripAlertsPanel(
          alerts: trip.alerts,
          onResolve: cubit.resolveAlert,
          onReportDelay: cubit.reportDelayAlert,
          onReportEmergency: cubit.reportEmergencyAlert,
        ),
        const SizedBox(height: AppSpacing.medium),
        LiveTripPassengersPanel(passengers: trip.passengers),
      ],
    );
  }
}

class LiveTripActionsBar extends StatelessWidget {
  const LiveTripActionsBar({
    super.key,
    required this.trip,
    required this.actionLoading,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onComplete,
    required this.onCallDriver,
    required this.onMessageDriver,
  });

  final LiveTrip trip;
  final bool actionLoading;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onComplete;
  final VoidCallback onCallDriver;
  final VoidCallback onMessageDriver;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Wrap(
        spacing: AppSpacing.small,
        runSpacing: AppSpacing.small,
        children: [
          if (trip.status == LiveTripStatus.notStarted ||
              trip.status == LiveTripStatus.preparing)
            _ActionButton(
              label: 'بدء الرحلة',
              icon: Icons.play_arrow_rounded,
              onPressed: actionLoading ? null : onStart,
              filled: true,
            ),
          if (trip.status == LiveTripStatus.inProgress) ...[
            _ActionButton(
              label: 'إيقاف مؤقت',
              icon: Icons.pause_rounded,
              onPressed: actionLoading ? null : onPause,
            ),
            _ActionButton(
              label: 'إنهاء الرحلة',
              icon: Icons.flag_rounded,
              onPressed: actionLoading ? null : onComplete,
              danger: true,
            ),
          ],
          if (trip.status == LiveTripStatus.paused)
            _ActionButton(
              label: 'استكمال الرحلة',
              icon: Icons.play_arrow_rounded,
              onPressed: actionLoading ? null : onResume,
              filled: true,
            ),
          _ActionButton(
            label: 'اتصال بالسائق',
            icon: Icons.call_rounded,
            onPressed: actionLoading ? null : onCallDriver,
          ),
          _ActionButton(
            label: 'رسالة للسائق',
            icon: Icons.message_rounded,
            onPressed: actionLoading ? null : onMessageDriver,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = false,
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool filled;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (filled) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: danger ? scheme.error : null),
      label: Text(
        label,
        style: TextStyle(color: danger ? scheme.error : null),
      ),
    );
  }
}

class LiveTripMapPanel extends StatelessWidget {
  const LiveTripMapPanel({super.key, required this.trip});

  final LiveTrip trip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الخريطة الحية', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: AppSpacing.medium),
          Container(
            height: 260,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppTokens.radius),
              border: Border.all(color: scheme.outline.withAlpha(60)),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Center(
                    child: Icon(Icons.map_outlined, size: 78, color: scheme.onSurfaceVariant.withAlpha(130)),
                  ),
                ),
                PositionedDirectional(
                  top: 18,
                  start: 18,
                  child: _MapPill(label: trip.currentPoint?.name ?? 'غير محدد', icon: Icons.trip_origin_rounded),
                ),
                PositionedDirectional(
                  bottom: 18,
                  end: 18,
                  child: _MapPill(label: trip.nextPoint?.name ?? 'نهاية الرحلة', icon: Icons.location_on_rounded),
                ),
                Center(child: _VehicleMarker(label: trip.vehiclePlate)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          AppProgressBar(progress: trip.progressPercent / 100),
        ],
      ),
    );
  }
}

class _MapPill extends StatelessWidget {
  const _MapPill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 190),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: scheme.onPrimaryContainer),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleMarker extends StatelessWidget {
  const _VehicleMarker({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.directions_bus_rounded, color: scheme.onPrimary),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: scheme.onPrimary, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class LiveTripRouteTimeline extends StatelessWidget {
  const LiveTripRouteTimeline({
    super.key,
    required this.trip,
    required this.onArrived,
    required this.onCompleted,
    required this.onSkipped,
  });

  final LiveTrip trip;
  final VoidCallback onArrived;
  final VoidCallback onCompleted;
  final VoidCallback onSkipped;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('مسار الرحلة', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: AppSpacing.medium),
          ...List.generate(trip.routePoints.length, (index) {
            final point = trip.routePoints[index];
            return _PointTile(
              point: point,
              isCurrent: index == trip.currentPointIndex,
              isLast: index == trip.routePoints.length - 1,
            );
          }),
          const SizedBox(height: AppSpacing.small),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: [
              FilledButton.icon(
                onPressed: onArrived,
                icon: const Icon(Icons.place_rounded),
                label: const Text('وصول للمحطة'),
              ),
              OutlinedButton.icon(
                onPressed: onCompleted,
                icon: const Icon(Icons.check_rounded),
                label: const Text('إنهاء المحطة'),
              ),
              OutlinedButton.icon(
                onPressed: onSkipped,
                icon: const Icon(Icons.skip_next_rounded),
                label: const Text('تخطي المحطة'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PointTile extends StatelessWidget {
  const _PointTile({
    required this.point,
    required this.isCurrent,
    required this.isLast,
  });

  final LiveRoutePoint point;
  final bool isCurrent;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (point.status) {
      LivePointStatus.completed => scheme.primary,
      LivePointStatus.arrived => scheme.secondary,
      LivePointStatus.current => scheme.tertiary,
      LivePointStatus.skipped => scheme.error,
      LivePointStatus.pending => scheme.outline,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: isCurrent ? 15 : 13,
              backgroundColor: color.withAlpha(25),
              child: Icon(
                point.status == LivePointStatus.completed
                    ? Icons.check_rounded
                    : isCurrent
                        ? Icons.directions_bus_rounded
                        : Icons.circle_rounded,
                size: 14,
                color: color,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 30,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: scheme.outline.withAlpha(80),
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.medium),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(point.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(
                  '${point.status.label} · منتظرين ${point.waitingPassengersCount} · صعدوا ${point.boardedPassengersCount}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class LiveTripAlertsPanel extends StatelessWidget {
  const LiveTripAlertsPanel({
    super.key,
    required this.alerts,
    required this.onResolve,
    required this.onReportDelay,
    required this.onReportEmergency,
  });

  final List<LiveTripAlert> alerts;
  final ValueChanged<String> onResolve;
  final VoidCallback onReportDelay;
  final VoidCallback onReportEmergency;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('التنبيهات', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: AppSpacing.medium),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: [
              OutlinedButton.icon(
                onPressed: onReportDelay,
                icon: const Icon(Icons.schedule_rounded),
                label: const Text('إضافة تأخير'),
              ),
              FilledButton.icon(
                onPressed: onReportEmergency,
                icon: const Icon(Icons.warning_rounded),
                label: const Text('تنبيه طوارئ'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          if (alerts.isEmpty)
            const Text('لا توجد تنبيهات على هذه الرحلة.')
          else
            ...alerts.map((alert) => _AlertTile(alert: alert, onResolve: onResolve)),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert, required this.onResolve});

  final LiveTripAlert alert;
  final ValueChanged<String> onResolve;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = alert.severity == LiveTripAlertSeverity.critical
        ? scheme.error
        : alert.severity == LiveTripAlertSeverity.warning
            ? scheme.tertiary
            : scheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.small),
      padding: const EdgeInsets.all(AppSpacing.small),
      decoration: BoxDecoration(
        color: color.withAlpha(14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notifications_active_outlined, color: color),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(alert.message, maxLines: 3, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Text('${alert.type.label} · ${alert.severity.label}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          if (!alert.resolved)
            TextButton(
              onPressed: () => onResolve(alert.id),
              child: const Text('حل'),
            )
          else
            const Icon(Icons.check_circle_rounded),
        ],
      ),
    );
  }
}

class LiveTripPassengersPanel extends StatelessWidget {
  const LiveTripPassengersPanel({super.key, required this.passengers});

  final List<LivePassengerCheckin> passengers;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الركاب', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: AppSpacing.medium),
          if (passengers.isEmpty)
            const Text('لا توجد بيانات ركاب لهذه الرحلة.')
          else
            ...passengers.map((passenger) => _PassengerTile(passenger: passenger)),
        ],
      ),
    );
  }
}

class _PassengerTile extends StatelessWidget {
  const _PassengerTile({required this.passenger});

  final LivePassengerCheckin passenger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = passenger.checkedIn ? scheme.primary : scheme.tertiary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.small),
      padding: const EdgeInsets.all(AppSpacing.small),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(70),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withAlpha(20),
            child: Icon(
              passenger.checkedIn ? Icons.check_rounded : Icons.schedule_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(passenger.passengerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text('${passenger.passengerPhone} · ${passenger.pickupPointName}', maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          Text(
            passenger.checkedIn ? 'صعد' : 'منتظر',
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}