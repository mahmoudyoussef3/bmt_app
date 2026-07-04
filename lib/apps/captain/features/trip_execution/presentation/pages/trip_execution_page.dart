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
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_spacing.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_button.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_card.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_status_chip.dart';

import '../../domain/entities/trip_execution_state.dart';
import '../cubit/trip_execution_cubit.dart';
import '../cubit/trip_execution_state.dart';

class TripExecutionPage extends StatelessWidget {
  const TripExecutionPage({super.key, required this.trip});

  final AssignedTrip trip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocProvider<TripExecutionCubit>(
      create: (_) =>
          captainGetIt<TripExecutionCubit>()
            ..watch(trip.id, _executionStatusFromTrip(trip.status)),
      child: BlocBuilder<TripExecutionCubit, TripExecutionCubitState>(
        builder: (context, state) {
          final status = _statusFromState(state);

          return Scaffold(
            backgroundColor: scheme.surfaceContainerLowest,
            floatingActionButton: status == TripExecutionStatus.inProgress
                ? _SosButton(tripId: trip.id)
                : null,
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 80,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: scheme.surface,
                  iconTheme: IconThemeData(color: scheme.onSurface),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(color: scheme.surface),
                    titlePadding: const EdgeInsets.symmetric(
                      horizontal: CaptainSpacing.xxxl,
                      vertical: CaptainSpacing.lg,
                    ),
                    title: Text(
                      'تنفيذ الرحلة',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      CaptainSpacing.xl,
                      CaptainSpacing.lg,
                      CaptainSpacing.xl,
                      CaptainSpacing.xxxl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ExecutionHeaderCard(
                          trip: trip,
                          status: status,
                          state: state,
                        ),
                        const SizedBox(height: CaptainSpacing.xl),
                        if (status == TripExecutionStatus.inProgress &&
                            trip.stops.isNotEmpty) ...[
                          _NextStopBanner(stops: trip.stops),
                          const SizedBox(height: CaptainSpacing.xl),
                        ],
                        Text(
                          'إجراءات الرحلة',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: CaptainSpacing.lg),
                        GridView.count(
                          crossAxisCount: MediaQuery.sizeOf(context).width > 520
                              ? 3
                              : 2,
                          mainAxisSpacing: CaptainSpacing.lg,
                          crossAxisSpacing: CaptainSpacing.lg,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 1.2,
                          children: [
                            _ActionTile(
                              label: 'الركاب',
                              icon: Icons.people_alt_rounded,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PassengerListPage(tripId: trip.id),
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
                              label: 'إرسال الموقع',
                              icon: Icons.my_location_rounded,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      LocationUpdatePage(tripId: trip.id),
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
                                  builder: (_) =>
                                      StatusUpdatePage(tripId: trip.id),
                                ),
                              ),
                            ),
                            _ActionTile(
                              label: 'بلاغ طارئ',
                              icon: Icons.report_problem_outlined,
                              destructive: true,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ReportIncidentPage(tripId: trip.id),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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
}

class _ExecutionHeaderCard extends StatelessWidget {
  const _ExecutionHeaderCard({
    required this.trip,
    required this.status,
    required this.state,
  });

  final AssignedTrip trip;
  final TripExecutionStatus status;
  final TripExecutionCubitState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return CaptainCard(
      color: scheme.surface,
      padding: const EdgeInsets.all(CaptainSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  trip.route,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: CaptainSpacing.md),
              _StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: CaptainSpacing.md),
          Text(
            'المركبة ${trip.vehicleNumber} • ${trip.plateNumber}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: CaptainSpacing.xl),
          Row(
            children: [
              _TripFact(icon: Icons.schedule_rounded, value: _timeRange(trip)),
              const SizedBox(width: CaptainSpacing.md),
              _TripFact(
                icon: Icons.people_alt_rounded,
                value: '${trip.boardedCount}/${trip.passengerCount} صعدوا',
              ),
            ],
          ),
          if (state is TripExecutionError) ...[
            const SizedBox(height: CaptainSpacing.lg),
            _InlineError(message: (state as TripExecutionError).message),
          ],
          const SizedBox(height: CaptainSpacing.xl),
          if (state is TripExecutionLoading)
            const Center(child: CircularProgressIndicator())
          else
            _actionButton(context, status, trip.id),
        ],
      ),
    );
  }

  Widget _actionButton(
    BuildContext context,
    TripExecutionStatus status,
    String tripId,
  ) {
    return switch (status) {
      TripExecutionStatus.scheduled => FilledButton.icon(
        onPressed: () => context.read<TripExecutionCubit>().board(tripId),
        style: _actionStyle(context),
        icon: const Icon(Icons.people_alt_rounded, size: 22),
        label: const Text(
          'بدء صعود الركاب',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      TripExecutionStatus.boarding => FilledButton.icon(
        onPressed: () => context.read<TripExecutionCubit>().start(tripId),
        style: _actionStyle(context, color: Colors.orange),
        icon: const Icon(Icons.play_circle_fill_rounded, size: 22),
        label: const Text(
          'بدء الرحلة',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      TripExecutionStatus.inProgress => FilledButton.icon(
        onPressed: () => context.read<TripExecutionCubit>().complete(tripId),
        style: _actionStyle(context, color: Colors.green),
        icon: const Icon(Icons.check_circle_rounded, size: 22),
        label: const Text(
          'إنهاء الرحلة',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      TripExecutionStatus.completed ||
      TripExecutionStatus.cancelled => OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          status == TripExecutionStatus.completed ? 'مكتملة' : 'ملغاة',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
    };
  }

  ButtonStyle _actionStyle(BuildContext context, {Color? color}) {
    final scheme = Theme.of(context).colorScheme;
    return FilledButton.styleFrom(
      backgroundColor: color ?? scheme.primary,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
    );
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final TripExecutionStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, variant, icon) = switch (status) {
      TripExecutionStatus.scheduled => (
        'مجدولة',
        CaptainStatusVariant.info,
        Icons.event_rounded,
      ),
      TripExecutionStatus.boarding => (
        'صعود',
        CaptainStatusVariant.warning,
        Icons.people_rounded,
      ),
      TripExecutionStatus.inProgress => (
        'جارية',
        CaptainStatusVariant.success,
        Icons.electric_car_rounded,
      ),
      TripExecutionStatus.completed => (
        'مكتملة',
        CaptainStatusVariant.neutral,
        Icons.check_circle_rounded,
      ),
      TripExecutionStatus.cancelled => (
        'ملغاة',
        CaptainStatusVariant.error,
        Icons.cancel_rounded,
      ),
    };

    return CaptainStatusChip(label: label, variant: variant, icon: icon);
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

    return CaptainCard(
      color: scheme.primary.withAlpha(15),
      borderColor: scheme.primary.withAlpha(40),
      padding: const EdgeInsets.all(CaptainSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_rounded, color: scheme.primary, size: 20),
              const SizedBox(width: CaptainSpacing.md),
              Text(
                isLast ? 'تم الوصول للوجهة' : 'المحطة القادمة',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (!isLast)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CaptainSpacing.md,
                    vertical: CaptainSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: CaptainRadius.rSm,
                  ),
                  child: Text(
                    '$remaining',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          if (!isLast) ...[
            const SizedBox(height: CaptainSpacing.md),
            Text(
              widget.stops[_currentIndex],
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: CaptainSpacing.lg),
            CaptainButton(
              label: 'تم الوصول للمحطة',
              icon: Icons.check_rounded,
              onPressed: () => setState(() => _currentIndex++),
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: CaptainRadius.rLg,
        child: Container(
          padding: const EdgeInsets.all(CaptainSpacing.lg),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: CaptainRadius.rLg,
            border: Border.all(
              color: destructive
                  ? scheme.error.withAlpha(50)
                  : scheme.outlineVariant.withAlpha(50),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(CaptainSpacing.md),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: CaptainSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: destructive ? scheme.error : scheme.onSurface,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
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
        padding: const EdgeInsets.symmetric(
          horizontal: CaptainSpacing.md,
          vertical: CaptainSpacing.md,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withAlpha(100),
          borderRadius: CaptainRadius.rLg,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: scheme.primary),
            const SizedBox(width: CaptainSpacing.md),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
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
      padding: const EdgeInsets.all(CaptainSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: CaptainRadius.rLg,
        border: Border.all(color: scheme.error.withAlpha(50)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: scheme.error),
          const SizedBox(width: CaptainSpacing.md),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
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
              width: 72,
              height: 72,
              child: CircularProgressIndicator(
                value: _progress,
                strokeWidth: 6,
                color: Colors.red,
                backgroundColor: Colors.red.withAlpha(60),
              ),
            ),
          FloatingActionButton.extended(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
            elevation: 8,
            icon: const Icon(Icons.sos_rounded, size: 24),
            label: const Text(
              'طوارئ',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'اضغط مطولاً 3 ثوانٍ لإرسال نداء الاستغاثة',
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
