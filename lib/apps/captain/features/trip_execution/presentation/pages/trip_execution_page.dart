import 'dart:async';

import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/core/routes/captain_nav.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/domain/entities/assigned_trip.dart';
import 'package:bmt_app/apps/captain/features/incidents/domain/entities/incident_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_button.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_confirm_dialog.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_connectivity_banner.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_sliver_header.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_status_chip.dart';
import 'package:bmt_app/core/widgets/app_snackbar.dart';

import '../../domain/entities/trip_execution_state.dart';
import '../cubit/trip_execution_cubit.dart';
import '../cubit/trip_execution_state.dart';
import '../widgets/navigate_to_stop_button.dart';
import '../widgets/route_progress_timeline.dart';
import '../widgets/trip_gps_status_card.dart';

class TripExecutionPage extends StatelessWidget {
  const TripExecutionPage({super.key, required this.trip});

  final AssignedTrip trip;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TripExecutionCubit>(
      create: (_) => captainGetIt<TripExecutionCubit>()
        ..watch(
          tripId: trip.id,
          routePointCount: trip.stops.length,
          initialSnapshot: _initialSnapshotFromTrip(trip),
        ),
      child: BlocBuilder<TripExecutionCubit, TripExecutionCubitState>(
        builder: (context, state) {
          final snapshot = _snapshotFromState(state);
          final status = snapshot.status;

          return Scaffold(
            backgroundColor: CaptainColors.backgroundFor(context),
            floatingActionButton: status == TripExecutionStatus.inProgress
                ? _SosButton(tripId: trip.id)
                : null,
            body: CustomScrollView(
              slivers: [
                const CaptainSliverHeader(title: 'تنفيذ الرحلة'),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      CaptainDesignTokens.s24,
                      CaptainDesignTokens.s16,
                      CaptainDesignTokens.s24,
                      CaptainDesignTokens.s32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const CaptainConnectivityBanner(),
                        _ExecutionHeaderCard(
                          trip: trip,
                          snapshot: snapshot,
                          state: state,
                        ),
                        const SizedBox(height: CaptainDesignTokens.s24),
                        if (status == TripExecutionStatus.inProgress &&
                            trip.stops.isNotEmpty) ...[
                          _NextStopBanner(
                            tripId: trip.id,
                            stops: trip.stops,
                            arrivedStationsCount: snapshot.arrivedStationsCount,
                          ),
                          const SizedBox(height: CaptainDesignTokens.s24),
                          RouteProgressTimeline(
                            stops: trip.stops,
                            arrivedStationsCount: snapshot.arrivedStationsCount,
                          ),
                          const SizedBox(height: CaptainDesignTokens.s24),
                          TripGpsStatusCard(
                            lastLocation: snapshot.lastLocation,
                            destination: trip.stops.last,
                            expectedArrivalTime: trip.expectedArrivalTime,
                            onSendLocation: () =>
                                context.openLocationUpdate(trip.id),
                          ),
                          const SizedBox(height: CaptainDesignTokens.s16),
                          NavigateToStopButton(stop: _nextStop(trip, snapshot)),
                          const SizedBox(height: CaptainDesignTokens.s24),
                        ],
                        Text(
                          'إجراءات الرحلة',
                          style: CaptainTypography.titleLarge(
                            context,
                          ).copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: CaptainDesignTokens.s16),
                        GridView.count(
                          crossAxisCount: MediaQuery.sizeOf(context).width > 520
                              ? 3
                              : 2,
                          mainAxisSpacing: CaptainDesignTokens.s16,
                          crossAxisSpacing: CaptainDesignTokens.s16,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 1.2,
                          children: [
                            _ActionTile(
                              label: 'الركاب',
                              icon: Icons.people_alt_rounded,
                              onTap: () =>
                                  context.openPassengerManifest(trip.id),
                            ),
                            _ActionTile(
                              label: 'تسجيل الدخول',
                              icon: Icons.qr_code_scanner_rounded,
                              onTap: () => context.openCheckIn(trip.id),
                            ),
                            _ActionTile(
                              label: 'إرسال الموقع',
                              icon: Icons.my_location_rounded,
                              onTap: () => context.openLocationUpdate(trip.id),
                            ),
                            _ActionTile(
                              label: 'التواصل',
                              icon: Icons.chat_bubble_outline_rounded,
                              onTap: () => context.openChats(trip.id),
                            ),
                            _ActionTile(
                              label: 'تحديث الحالة',
                              icon: Icons.sync_rounded,
                              onTap: () => context.openStatusUpdate(trip.id),
                            ),
                            _ActionTile(
                              label: 'بلاغ طارئ',
                              icon: Icons.report_problem_outlined,
                              destructive: true,
                              onTap: () => context.openReportIncident(trip.id),
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

  /// The next stop the captain hasn't reported arrived yet, or null once
  /// every station on the route has been reported (nothing left to
  /// navigate to).
  AssignedTripStop? _nextStop(
    AssignedTrip trip,
    TripExecutionSnapshot snapshot,
  ) {
    final index = snapshot.arrivedStationsCount;
    if (index >= trip.stops.length) return null;
    return trip.stops[index];
  }

  TripExecutionSnapshot _snapshotFromState(TripExecutionCubitState state) {
    return switch (state) {
      TripExecutionIdle(:final snapshot) => snapshot,
      TripExecutionLoading(:final previousSnapshot) => previousSnapshot,
      TripExecutionError(:final previousSnapshot) => previousSnapshot,
    };
  }

  TripExecutionSnapshot _initialSnapshotFromTrip(AssignedTrip trip) {
    return TripExecutionSnapshot(
      status: switch (trip.status) {
        AssignedTripStatus.scheduled => TripExecutionStatus.scheduled,
        AssignedTripStatus.boarding => TripExecutionStatus.boarding,
        AssignedTripStatus.inProgress => TripExecutionStatus.inProgress,
        AssignedTripStatus.completed => TripExecutionStatus.completed,
      },
      passengerCount: trip.passengerCount,
      boardedCount: trip.boardedCount,
      arrivedStationsCount: trip.arrivedStationsCount,
    );
  }
}

class _ExecutionHeaderCard extends StatelessWidget {
  const _ExecutionHeaderCard({
    required this.trip,
    required this.snapshot,
    required this.state,
  });

  final AssignedTrip trip;
  final TripExecutionSnapshot snapshot;
  final TripExecutionCubitState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CaptainColors.surfaceFor(context),
        borderRadius: CaptainDesignTokens.br24,
        boxShadow: CaptainDesignTokens.floatingShadow(context),
      ),
      padding: const EdgeInsets.all(CaptainDesignTokens.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  trip.route,
                  style: CaptainTypography.headlineSmall(context).copyWith(
                    fontWeight: FontWeight.w900,
                    color: CaptainColors.textPrimaryFor(context),
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: CaptainDesignTokens.s12),
              _StatusBadge(status: snapshot.status),
            ],
          ),
          const SizedBox(height: CaptainDesignTokens.s12),
          Text(
            'المركبة ${trip.vehicleNumber} • ${trip.plateNumber}',
            style: CaptainTypography.titleMedium(context).copyWith(
              color: CaptainColors.textSecondaryFor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: CaptainDesignTokens.s24),
          Row(
            children: [
              _TripFact(icon: Icons.schedule_rounded, value: _timeRange(trip)),
              const SizedBox(width: CaptainDesignTokens.s12),
              _TripFact(
                icon: Icons.people_alt_rounded,
                value:
                    '${snapshot.boardedCount}/${snapshot.passengerCount} صعدوا',
              ),
            ],
          ),
          if (state is TripExecutionError) ...[
            const SizedBox(height: CaptainDesignTokens.s16),
            _InlineError(message: (state as TripExecutionError).message),
          ],
          const SizedBox(height: CaptainDesignTokens.s24),
          if (state is TripExecutionLoading)
            const Center(child: CircularProgressIndicator())
          else
            _actionButton(context, snapshot.status, trip.id),
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
      TripExecutionStatus.scheduled => _PremiumActionButton(
        onPressed: () => context.read<TripExecutionCubit>().board(tripId),
        icon: Icons.people_alt_rounded,
        label: 'بدء صعود الركاب',
        color: CaptainColors.primary,
      ),
      TripExecutionStatus.boarding => _PremiumActionButton(
        onPressed: () => context.read<TripExecutionCubit>().start(tripId),
        icon: Icons.play_circle_fill_rounded,
        label: 'بدء الرحلة',
        color: Colors.orange,
      ),
      TripExecutionStatus.inProgress => _PremiumActionButton(
        onPressed: () => _confirmAndComplete(context, tripId),
        icon: Icons.check_circle_rounded,
        label: 'إنهاء الرحلة',
        color: CaptainColors.success,
      ),
      // A terminal state, not an action — disabled (not a live button that
      // silently does nothing) so it reads as "this trip is done" rather
      // than as a tappable control.
      TripExecutionStatus.completed ||
      TripExecutionStatus.cancelled => OutlinedButton(
        onPressed: null,
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

  /// Completing a trip is a terminal, irreversible transition — confirm
  /// before firing it so one mis-tap while driving can't end the trip.
  Future<void> _confirmAndComplete(BuildContext context, String tripId) async {
    final confirmed = await CaptainConfirmDialog.show(
      context,
      title: 'إنهاء الرحلة',
      message: 'هل أنت متأكد من إنهاء الرحلة؟ لا يمكن التراجع عن هذا الإجراء.',
      confirmLabel: 'إنهاء الرحلة',
      confirmColor: CaptainColors.success,
    );
    if (confirmed && context.mounted) {
      context.read<TripExecutionCubit>().complete(tripId);
    }
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
  const _NextStopBanner({
    required this.tripId,
    required this.stops,
    required this.arrivedStationsCount,
  });

  final String tripId;
  final List<AssignedTripStop> stops;

  /// The live count of stations confirmed arrived (the shared `trip_events`
  /// arrival floor), read fresh from the cubit on every rebuild rather than
  /// captured once — so reopening this screen mid-trip always resumes at the
  /// correct next station instead of replaying a snapshot from whenever the
  /// trip was first loaded.
  final int arrivedStationsCount;

  @override
  State<_NextStopBanner> createState() => _NextStopBannerState();
}

class _NextStopBannerState extends State<_NextStopBanner> {
  bool _isSubmitting = false;

  /// A local bump ahead of [widget.arrivedStationsCount] so a successful tap
  /// advances the banner immediately, without waiting for the realtime round
  /// trip back through the live watch. Cleared automatically once the live
  /// count catches up to (or passes) it.
  int? _optimisticIndex;

  int get _currentIndex {
    final live = widget.arrivedStationsCount.clamp(0, widget.stops.length);
    final optimistic = _optimisticIndex;
    if (optimistic == null || live >= optimistic) return live;
    return optimistic;
  }

  Future<void> _markCurrentStopArrived() async {
    final index = _currentIndex;
    if (_isSubmitting || index >= widget.stops.length) return;
    final stop = widget.stops[index];
    setState(() => _isSubmitting = true);
    try {
      await context.read<TripExecutionCubit>().markStationArrived(
        tripId: widget.tripId,
        pointId: stop.id,
        pointName: stop.name,
      );
      if (!mounted) return;
      setState(() {
        _optimisticIndex = index + 1;
        _isSubmitting = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      AppSnackbar.error(context, 'تعذر تسجيل الوصول للمحطة، حاول مجدداً');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex;
    final remaining = widget.stops.length - currentIndex;
    final isLast = currentIndex >= widget.stops.length;

    return Container(
      decoration: BoxDecoration(
        color: CaptainColors.primary.withValues(alpha: 0.1),
        borderRadius: CaptainDesignTokens.br24,
        border: Border.all(color: CaptainColors.primary.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(CaptainDesignTokens.s24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: CaptainColors.primary,
                size: 20,
              ),
              const SizedBox(width: CaptainDesignTokens.s12),
              Text(
                isLast ? 'تم الوصول للوجهة' : 'المحطة القادمة',
                style: CaptainTypography.titleSmall(context).copyWith(
                  color: CaptainColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (!isLast)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: CaptainDesignTokens.s12,
                    vertical: CaptainDesignTokens.s8,
                  ),
                  decoration: BoxDecoration(
                    color: CaptainColors.primary,
                    borderRadius: CaptainDesignTokens.br16,
                  ),
                  child: Text(
                    '$remaining',
                    style: CaptainTypography.labelSmall(context).copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          if (!isLast) ...[
            const SizedBox(height: CaptainDesignTokens.s16),
            Text(
              widget.stops[currentIndex].name,
              style: CaptainTypography.titleLarge(context).copyWith(
                fontWeight: FontWeight.w800,
                color: CaptainColors.textPrimaryFor(context),
              ),
            ),
            const SizedBox(height: CaptainDesignTokens.s24),
            CaptainButton(
              label: 'تم الوصول للمحطة',
              icon: Icons.check_rounded,
              isLoading: _isSubmitting,
              onPressed: _isSubmitting ? null : _markCurrentStopArrived,
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
    final color = destructive ? CaptainColors.error : CaptainColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: CaptainDesignTokens.br24,
        child: Container(
          padding: const EdgeInsets.all(CaptainDesignTokens.s16),
          decoration: BoxDecoration(
            color: CaptainColors.surfaceFor(context),
            borderRadius: CaptainDesignTokens.br24,
            border: Border.all(
              color: destructive
                  ? CaptainColors.error.withValues(alpha: 0.1)
                  : CaptainColors.dividerFor(context).withValues(alpha: 0.5),
            ),
            boxShadow: CaptainDesignTokens.softShadow(context),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(CaptainDesignTokens.s12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: CaptainDesignTokens.s12),
              // Flexible so a larger text scale shrinks into whatever room
              // is left in the tile's fixed aspect-ratio height instead of
              // overflowing it; maxLines/ellipsis still apply within that.
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CaptainTypography.titleSmall(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: destructive
                        ? CaptainColors.error
                        : CaptainColors.textPrimaryFor(context),
                  ),
                ),
              ),
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: CaptainDesignTokens.s12,
          vertical: CaptainDesignTokens.s12,
        ),
        decoration: BoxDecoration(
          color: CaptainColors.primary.withValues(alpha: 0.05),
          borderRadius: CaptainDesignTokens.br16,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: CaptainColors.primary),
            const SizedBox(width: CaptainDesignTokens.s12),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CaptainTypography.labelLarge(context).copyWith(
                  fontWeight: FontWeight.w700,
                  color: CaptainColors.textSecondaryFor(context),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(CaptainDesignTokens.s16),
      decoration: BoxDecoration(
        color: CaptainColors.error.withValues(alpha: 0.1),
        borderRadius: CaptainDesignTokens.br16,
        border: Border.all(color: CaptainColors.error.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: CaptainColors.error),
          const SizedBox(width: CaptainDesignTokens.s12),
          Expanded(
            child: Text(
              message,
              style: CaptainTypography.bodyMedium(context).copyWith(
                color: CaptainColors.error,
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
  double _progress = 0;
  Timer? _progressTimer;

  void _onLongPressStart(LongPressStartDetails _) {
    // A stray duplicate long-press-start (without an intervening end/cancel)
    // would otherwise leave the previous periodic timer running unreferenced
    // — never cancelled, ticking `_progress` up twice as fast.
    _progressTimer?.cancel();
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
    _progressTimer?.cancel();
    if (mounted) setState(() => _progress = 0);
  }

  void _triggerSos() {
    if (!mounted) return;
    context.openReportIncident(
      widget.tripId,
      initialType: IncidentType.emergency,
    );
  }

  @override
  void dispose() {
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
            onPressed: () => AppSnackbar.warning(
              context,
              'اضغط مطولاً 3 ثوانٍ لإرسال نداء الاستغاثة',
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumActionButton extends StatelessWidget {
  const _PremiumActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            vertical: CaptainDesignTokens.s20,
          ),
          shape: RoundedRectangleBorder(borderRadius: CaptainDesignTokens.br24),
          elevation: 0,
        ),
        icon: Icon(icon, size: 28),
        label: Text(
          label,
          style: CaptainTypography.titleMedium(
            context,
          ).copyWith(fontWeight: FontWeight.w900, color: Colors.white),
        ),
      ),
    );
  }
}
