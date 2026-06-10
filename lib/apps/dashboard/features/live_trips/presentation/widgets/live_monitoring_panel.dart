import 'dart:async';
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

  void _showCallDialog(BuildContext context, LiveTrip trip) {
    showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<LiveTripsCubit>(),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: _SimulatedCallDialog(trip: trip),
        ),
      ),
    );
  }

  void _showChatDialog(BuildContext context, LiveTrip trip) {
    showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<LiveTripsCubit>(),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: _SimulatedChatDialog(trip: trip),
        ),
      ),
    );
  }

  void _showDelayDialog(BuildContext context, LiveTrip trip) {
    showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<LiveTripsCubit>(),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: _ReportDelayDialog(trip: trip),
        ),
      ),
    );
  }

  void _showEmergencyDialog(BuildContext context, LiveTrip trip) {
    showDialog<void>(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<LiveTripsCubit>(),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: _ReportEmergencyDialog(trip: trip),
        ),
      ),
    );
  }

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
          onCallDriver: () => _showCallDialog(context, trip),
          onMessageDriver: () => _showChatDialog(context, trip),
        ),
        const SizedBox(height: AppSpacing.medium),
        LiveTripMapPanel(trip: trip),
        const SizedBox(height: AppSpacing.medium),
        LiveTripRouteTimeline(
          trip: trip,
          onArrived: cubit.markPointArrived,
          onCompleted: cubit.markPointCompleted,
          onSkipped: cubit.skipPoint,
        ),
        const SizedBox(height: AppSpacing.medium),
        LiveTripAlertsPanel(
          alerts: trip.alerts,
          onResolve: cubit.resolveAlert,
          onReportDelay: () => _showDelayDialog(context, trip),
          onReportEmergency: () => _showEmergencyDialog(context, trip),
        ),
        const SizedBox(height: AppSpacing.medium),
        LiveTripPassengersPanel(
          passengers: trip.passengers,
          onToggleCheckin: cubit.togglePassengerCheckin,
        ),
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
  final ValueChanged<String> onArrived;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String> onSkipped;

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
              tripStatus: trip.status,
              onArrived: onArrived,
              onCompleted: onCompleted,
              onSkipped: onSkipped,
            );
          }),
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
    required this.tripStatus,
    required this.onArrived,
    required this.onCompleted,
    required this.onSkipped,
  });

  final LiveRoutePoint point;
  final bool isCurrent;
  final bool isLast;
  final LiveTripStatus tripStatus;
  final ValueChanged<String> onArrived;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String> onSkipped;

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
                height: isCurrent ? 68 : 34,
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
                if (isCurrent && tripStatus == LiveTripStatus.inProgress) ...[
                  const SizedBox(height: AppSpacing.small),
                  Wrap(
                    spacing: AppSpacing.xSmall,
                    runSpacing: AppSpacing.xSmall,
                    children: [
                      if (point.status == LivePointStatus.current)
                        FilledButton.icon(
                          onPressed: () => onArrived(point.id),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: const Size(0, 32),
                          ),
                          icon: const Icon(Icons.place_rounded, size: 14),
                          label: const Text('تسجيل وصول', style: TextStyle(fontSize: 11)),
                        ),
                      if (point.status == LivePointStatus.arrived || point.status == LivePointStatus.current)
                        FilledButton.tonalIcon(
                          onPressed: () => onCompleted(point.id),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: const Size(0, 32),
                          ),
                          icon: const Icon(Icons.check_rounded, size: 14),
                          label: const Text('إنهاء المحطة', style: TextStyle(fontSize: 11)),
                        ),
                      OutlinedButton.icon(
                        onPressed: () => onSkipped(point.id),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          minimumSize: const Size(0, 32),
                          foregroundColor: scheme.error,
                          side: BorderSide(color: scheme.error.withAlpha(100)),
                        ),
                        icon: Icon(Icons.skip_next_rounded, size: 14, color: scheme.error),
                        label: const Text('تخطي المحطة', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ],
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
  const LiveTripPassengersPanel({
    super.key,
    required this.passengers,
    required this.onToggleCheckin,
  });

  final List<LivePassengerCheckin> passengers;
  final ValueChanged<String> onToggleCheckin;

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
            ...passengers.map(
              (passenger) => _PassengerTile(
                passenger: passenger,
                onTap: () => onToggleCheckin(passenger.id),
              ),
            ),
        ],
      ),
    );
  }
}

class _PassengerTile extends StatelessWidget {
  const _PassengerTile({
    required this.passenger,
    required this.onTap,
  });

  final LivePassengerCheckin passenger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = passenger.checkedIn ? scheme.primary : scheme.tertiary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.small),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(70),
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.small),
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
                    Text(
                      passenger.passengerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${passenger.passengerPhone} · ${passenger.pickupPointName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Row(
                children: [
                  Text(
                    passenger.checkedIn ? 'صعد' : 'منتظر',
                    style: TextStyle(color: color, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Switch.adaptive(
                    value: passenger.checkedIn,
                    onChanged: (_) => onTap(),
                    activeColor: scheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimulatedCallDialog extends StatefulWidget {
  const _SimulatedCallDialog({required this.trip});
  final LiveTrip trip;

  @override
  State<_SimulatedCallDialog> createState() => _SimulatedCallDialogState();
}

class _SimulatedCallDialogState extends State<_SimulatedCallDialog> {
  Timer? _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(int totalSecs) {
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('اتصال جاري...', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.large),
            CircleAvatar(
              radius: 40,
              backgroundColor: scheme.primaryContainer,
              child: Text(
                widget.trip.driverName.substring(0, 1),
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: scheme.onPrimaryContainer),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(widget.trip.driverName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(widget.trip.driverPhone, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.large),
            Text(
              _formatDuration(_seconds),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
            ),
            const SizedBox(height: AppSpacing.large),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final double height = 10 + (index % 2 == 0 ? (_seconds % 4) * 6.0 : (4 - (_seconds % 4)) * 6.0);
                return Container(
                  width: 4,
                  height: height,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.large),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(backgroundColor: scheme.error),
              icon: const Icon(Icons.call_end_rounded),
              label: const Text('إنهاء المكالمة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimulatedChatDialog extends StatefulWidget {
  const _SimulatedChatDialog({required this.trip});
  final LiveTrip trip;

  @override
  State<_SimulatedChatDialog> createState() => _SimulatedChatDialogState();
}

class _SimulatedChatDialogState extends State<_SimulatedChatDialog> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _messages.addAll([
      {'isMe': false, 'text': 'مرحباً، بدأت التحرك للمحطة التالية.', 'time': '١٠:٤٢ ص'},
      {'isMe': true, 'text': 'تمام، يرجى إبلاغنا عند الوصول.', 'time': '١٠:٤٣ ص'},
    ]);
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add({
        'isMe': true,
        'text': text.trim(),
        'time': 'الآن',
      });
    });
    _controller.clear();
    context.read<LiveTripsCubit>().messageSelectedDriver(text);

    Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'isMe': false,
          'text': 'علم، جاري التنفيذ الآن.',
          'time': 'الآن',
        });
      });
      _scrollToBottom();
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SizedBox(
        width: 500,
        height: 600,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(child: Text(widget.trip.driverName.substring(0, 1))),
                  const SizedBox(width: AppSpacing.medium),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.trip.driverName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('نشط الآن', style: TextStyle(color: scheme.primary, fontSize: 11)),
                    ],
                  ),
                  const Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isMe = msg['isMe'] as bool;
                    return Align(
                      alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isMe ? scheme.primaryContainer : scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(12),
                            topRight: const Radius.circular(12),
                            bottomLeft: isMe ? Radius.zero : const Radius.circular(12),
                            bottomRight: isMe ? const Radius.circular(12) : Radius.zero,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(msg['text'] as String),
                            const SizedBox(height: 2),
                            Text(
                              msg['time'] as String,
                              style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              Wrap(
                spacing: 4,
                children: [
                  'أين أنت الآن؟',
                  'هل تواجه زحاماً؟',
                  'تأكيد الوصول للمحطة',
                ].map((reply) {
                  return ActionChip(
                    label: Text(reply, style: const TextStyle(fontSize: 11)),
                    onPressed: () => _sendMessage(reply),
                  );
                }).toList(),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'اكتب رسالة للسائق...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _sendMessage(_controller.text),
                    icon: Icon(Icons.send_rounded, color: scheme.primary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportDelayDialog extends StatefulWidget {
  const _ReportDelayDialog({required this.trip});
  final LiveTrip trip;

  @override
  State<_ReportDelayDialog> createState() => _ReportDelayDialogState();
}

class _ReportDelayDialogState extends State<_ReportDelayDialog> {
  int _selectedMinutes = 15;
  final TextEditingController _reasonController = TextEditingController(text: 'كثافة مرورية على الطريق');

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تسجيل تأخير جديد', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.medium),
            const Text('مدة التأخير:'),
            const SizedBox(height: AppSpacing.small),
            Wrap(
              spacing: 8,
              children: [5, 10, 15, 30, 45].map((mins) {
                final selected = _selectedMinutes == mins;
                return ChoiceChip(
                  label: Text('$mins دقائق'),
                  selected: selected,
                  onSelected: (val) {
                    if (val) setState(() => _selectedMinutes = mins);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.medium),
            const Text('السبب:'),
            const SizedBox(height: AppSpacing.small),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(hintText: 'مثال: زحام مروري، عطل بسيط'),
            ),
            const SizedBox(height: AppSpacing.large),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
                const SizedBox(width: AppSpacing.small),
                FilledButton(
                  onPressed: () {
                    context.read<LiveTripsCubit>().reportDelayAlert(
                          minutes: _selectedMinutes,
                          reason: _reasonController.text.trim(),
                        );
                    Navigator.pop(context);
                  },
                  child: const Text('تسجيل التأخير'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportEmergencyDialog extends StatefulWidget {
  const _ReportEmergencyDialog({required this.trip});
  final LiveTrip trip;

  @override
  State<_ReportEmergencyDialog> createState() => _ReportEmergencyDialogState();
}

class _ReportEmergencyDialogState extends State<_ReportEmergencyDialog> {
  LiveTripAlertType _selectedType = LiveTripAlertType.emergency;
  final TextEditingController _descController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_rounded, color: scheme.error),
                const SizedBox(width: 8),
                Text('إبلاغ عن حالة طوارئ', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: scheme.error)),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            const Text('نوع الطوارئ:'),
            const SizedBox(height: AppSpacing.small),
            DropdownButtonFormField<LiveTripAlertType>(
              value: _selectedType,
              items: const [
                DropdownMenuItem(value: LiveTripAlertType.emergency, child: Text('حالة طوارئ عامة')),
                DropdownMenuItem(value: LiveTripAlertType.vehicleIssue, child: Text('عطل فني في الأتوبيس')),
                DropdownMenuItem(value: LiveTripAlertType.routeDeviation, child: Text('انحراف عن المسار المقدر')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedType = val);
              },
            ),
            const SizedBox(height: AppSpacing.medium),
            const Text('تفاصيل البلاغ:'),
            const SizedBox(height: AppSpacing.small),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'يرجى كتابة تفاصيل المشكلة بدقة ليتم إرسال الدعم.'),
            ),
            const SizedBox(height: AppSpacing.large),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
                const SizedBox(width: AppSpacing.small),
                FilledButton(
                  onPressed: () {
                    context.read<LiveTripsCubit>().reportEmergencyAlert(
                          type: _selectedType,
                          reason: _descController.text.trim().isEmpty ? 'بلاغ طوارئ جديد' : _descController.text.trim(),
                        );
                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(backgroundColor: scheme.error),
                  child: const Text('إرسال البلاغ عاجل'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}