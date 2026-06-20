import 'dart:async';

import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/domain/entities/assigned_trip.dart';
import 'package:bmt_app/apps/captain/features/check_in/presentation/pages/check_in_page.dart';
import 'package:bmt_app/apps/captain/features/communication/presentation/pages/chats_page.dart';
import 'package:bmt_app/apps/captain/features/incidents/domain/entities/incident_report.dart';
import 'package:bmt_app/apps/captain/features/incidents/presentation/pages/report_incident_page.dart';
import 'package:bmt_app/apps/captain/features/live_location/presentation/pages/live_location_page.dart';
import 'package:bmt_app/apps/captain/features/passenger_manifest/presentation/pages/passenger_list_page.dart';
import 'package:bmt_app/apps/captain/features/trip_status_updates/presentation/pages/status_update_page.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/trip_execution_state.dart';
import '../cubit/trip_execution_cubit.dart';
import '../cubit/trip_execution_state.dart';

class TripExecutionPage extends StatelessWidget {
  const TripExecutionPage({super.key, required this.trip});

  final AssignedTrip trip;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TripExecutionCubit>(
      create: (_) =>
          captainGetIt<TripExecutionCubit>()
            ..setInitialStatus(_executionStatusFromTrip(trip.status)),
      child: BlocBuilder<TripExecutionCubit, TripExecutionCubitState>(
        builder: (context, state) {
          final status = _statusFromState(state);
          return Scaffold(
            appBar: AppBar(title: const Text('تنفيذ الرحلة')),
            floatingActionButton: status == TripExecutionStatus.inProgress
                ? _SosButton(tripId: trip.id)
                : null,
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              children: [
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              trip.route,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          StatusChip(
                            label: _statusLabel(status),
                            color: _statusColor(status).withAlpha(28),
                            textColor: _statusColor(status),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'المركبة ${trip.vehicleNumber} • ${trip.plateNumber}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _TripFact(
                            icon: Icons.schedule_rounded,
                            value: _timeRange(trip),
                          ),
                          const SizedBox(width: 10),
                          _TripFact(
                            icon: Icons.people_alt_rounded,
                            value:
                                '${trip.boardedCount}/${trip.passengerCount} صعد',
                          ),
                        ],
                      ),
                      if (state is TripExecutionError) ...[
                        const SizedBox(height: 12),
                        _InlineError(message: state.message),
                      ],
                      const SizedBox(height: 16),
                      if (state is TripExecutionLoading)
                        const Center(child: CircularProgressIndicator())
                      else
                        SizedBox(
                          width: double.infinity,
                          child: _actionButton(context, status),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (status == TripExecutionStatus.inProgress &&
                    trip.stops.isNotEmpty)
                  _NextStopBanner(stops: trip.stops),
                if (status == TripExecutionStatus.inProgress &&
                    trip.stops.isNotEmpty)
                  const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: MediaQuery.sizeOf(context).width > 520
                      ? 3
                      : 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.5,
                  children: [
                    _ActionTile(
                      label: 'قائمة الركاب',
                      icon: Icons.people_alt_rounded,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PassengerListPage(tripId: trip.id),
                        ),
                      ),
                    ),
                    _ActionTile(
                      label: 'تسجيل الدخول',
                      icon: Icons.qr_code_scanner_rounded,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CheckInPage(tripId: trip.id),
                        ),
                      ),
                    ),
                    _ActionTile(
                      label: 'مشاركة الموقع',
                      icon: Icons.location_on_rounded,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LiveLocationPage(tripId: trip.id),
                        ),
                      ),
                    ),
                    _ActionTile(
                      label: 'التواصل',
                      icon: Icons.chat_bubble_outline_rounded,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatsPage(tripId: trip.id),
                        ),
                      ),
                    ),
                    _ActionTile(
                      label: 'تحديث الحالة',
                      icon: Icons.sync_rounded,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => StatusUpdatePage(tripId: trip.id),
                        ),
                      ),
                    ),
                    _ActionTile(
                      label: 'بلاغ',
                      icon: Icons.report_problem_outlined,
                      destructive: true,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReportIncidentPage(tripId: trip.id),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _statusLabel(TripExecutionStatus status) {
    return switch (status) {
      TripExecutionStatus.scheduled => 'مجدولة',
      TripExecutionStatus.boarding => 'صعود الركاب',
      TripExecutionStatus.inProgress => 'جارية',
      TripExecutionStatus.completed => 'مكتملة',
      TripExecutionStatus.cancelled => 'ملغاة',
    };
  }

  Widget _actionButton(BuildContext context, TripExecutionStatus status) {
    return switch (status) {
      TripExecutionStatus.scheduled => AppButton(
        label: 'بدء صعود الركاب',
        onPressed: () => context.read<TripExecutionCubit>().board(trip.id),
      ),
      TripExecutionStatus.boarding => AppButton(
        label: 'بدء الرحلة',
        onPressed: () => context.read<TripExecutionCubit>().start(trip.id),
      ),
      TripExecutionStatus.inProgress => AppButton(
        label: 'إنهاء الرحلة',
        outline: true,
        onPressed: () => context.read<TripExecutionCubit>().complete(trip.id),
      ),
      TripExecutionStatus.completed || TripExecutionStatus.cancelled =>
        AppButton(label: _statusLabel(status), onPressed: () {}),
    };
  }

  TripExecutionStatus _statusFromState(TripExecutionCubitState state) {
    return switch (state) {
      TripExecutionIdle(:final status) => status,
      TripExecutionLoading(:final previousStatus) => previousStatus,
      TripExecutionError(:final previousStatus) => previousStatus,
    };
  }

  TripExecutionStatus _executionStatusFromTrip(AssignedTripStatus status) {
    return switch (status) {
      AssignedTripStatus.scheduled => TripExecutionStatus.scheduled,
      AssignedTripStatus.boarding => TripExecutionStatus.boarding,
      AssignedTripStatus.inProgress => TripExecutionStatus.inProgress,
      AssignedTripStatus.completed => TripExecutionStatus.completed,
    };
  }

  Color _statusColor(TripExecutionStatus status) {
    return switch (status) {
      TripExecutionStatus.scheduled => Colors.blue,
      TripExecutionStatus.boarding => Colors.orange,
      TripExecutionStatus.inProgress => Colors.green,
      TripExecutionStatus.completed => Colors.grey,
      TripExecutionStatus.cancelled => Colors.red,
    };
  }

  String _timeRange(AssignedTrip trip) {
    return '${_time(trip.departureTime)} - ${_time(trip.expectedArrivalTime)}';
  }

  String _time(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _SosButton extends StatefulWidget {
  const _SosButton({required this.tripId});
  final String tripId;

  @override
  State<_SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<_SosButton> {
  Timer? _holdTimer;
  double _progress = 0;
  Timer? _progressTimer;

  void _onLongPressStart(LongPressStartDetails _) {
    setState(() => _progress = 0);
    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      setState(() => _progress += 50 / 3000);
      if (_progress >= 1) {
        _cancel();
        _triggerSos();
      }
    });
  }

  void _cancel() {
    _holdTimer?.cancel();
    _progressTimer?.cancel();
    if (mounted) setState(() => _progress = 0);
  }

  void _triggerSos() {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReportIncidentPage(
          tripId: widget.tripId,
          initialType: IncidentType.emergency,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: _onLongPressStart,
      onLongPressEnd: (_) => _cancel(),
      onLongPressCancel: _cancel,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_progress > 0)
            SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                value: _progress,
                strokeWidth: 4,
                color: Colors.red,
                backgroundColor: Colors.red.withAlpha(60),
              ),
            ),
          FloatingActionButton(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('اضغط مطولاً 3 ثوانٍ لإرسال نداء الاستغاثة'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              'SOS',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextStopBanner extends StatefulWidget {
  const _NextStopBanner({required this.stops});
  final List<String> stops;

  @override
  State<_NextStopBanner> createState() => _NextStopBannerState();
}

class _NextStopBannerState extends State<_NextStopBanner> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final remaining = widget.stops.length - _currentIndex;
    final isLast = _currentIndex >= widget.stops.length;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_rounded, color: scheme.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                isLast ? 'تم الوصول إلى الوجهة النهائية' : 'المحطة القادمة',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: scheme.primary),
              ),
              const Spacer(),
              if (!isLast)
                Text(
                  '$remaining محطة متبقية',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
          if (!isLast) ...[
            const SizedBox(height: 6),
            Text(
              widget.stops[_currentIndex],
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => setState(() => _currentIndex++),
                child: const Text('تم الوصول'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = destructive ? scheme.error : scheme.primary;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color),
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ],
      ),
    );
  }
}

class _TripFact extends StatelessWidget {
  const _TripFact({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outline.withAlpha(70)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: scheme.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: scheme.onErrorContainer),
      ),
    );
  }
}
