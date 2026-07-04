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

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_button.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_status_chip.dart';

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
            ..watch(trip.id, _executionStatusFromTrip(trip.status)),
      child: BlocBuilder<TripExecutionCubit, TripExecutionCubitState>(
        builder: (context, state) {
          final status = _statusFromState(state);

          return Scaffold(
            backgroundColor: CaptainColors.backgroundFor(context),
            floatingActionButton: status == TripExecutionStatus.inProgress
                ? _SosButton(tripId: trip.id)
                : null,
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 80,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: CaptainColors.backgroundFor(context),
                  iconTheme: IconThemeData(color: CaptainColors.textPrimaryFor(context)),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(color: CaptainColors.backgroundFor(context)),
                    titlePadding: const EdgeInsets.symmetric(
                      horizontal: CaptainDesignTokens.s32,
                      vertical: CaptainDesignTokens.s16,
                    ),
                    title: Text(
                      'تنفيذ الرحلة',
                      style: CaptainTypography.titleLarge(context).copyWith(
                        fontWeight: FontWeight.w800,
                        color: CaptainColors.textPrimaryFor(context),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      CaptainDesignTokens.s24,
                      CaptainDesignTokens.s16,
                      CaptainDesignTokens.s24,
                      CaptainDesignTokens.s32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ExecutionHeaderCard(
                          trip: trip,
                          status: status,
                          state: state,
                        ),
                        const SizedBox(height: CaptainDesignTokens.s24),
                        if (status == TripExecutionStatus.inProgress &&
                            trip.stops.isNotEmpty) ...[
                          _NextStopBanner(stops: trip.stops),
                          const SizedBox(height: CaptainDesignTokens.s24),
                        ],
                        Text(
                          'إجراءات الرحلة',
                          style: CaptainTypography.titleLarge(context)
                              .copyWith(fontWeight: FontWeight.w800),
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
              _StatusBadge(status: status),
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
                value: '${trip.boardedCount}/${trip.passengerCount} صعدوا',
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
        onPressed: () => context.read<TripExecutionCubit>().complete(tripId),
        icon: Icons.check_circle_rounded,
        label: 'إنهاء الرحلة',
        color: CaptainColors.success,
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
    final remaining = widget.stops.length - _currentIndex;
    final isLast = _currentIndex >= widget.stops.length;

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
              const Icon(Icons.location_on_rounded, color: CaptainColors.primary, size: 20),
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
              widget.stops[_currentIndex],
              style: CaptainTypography.titleLarge(context).copyWith(
                fontWeight: FontWeight.w800,
                color: CaptainColors.textPrimaryFor(context),
              ),
            ),
            const SizedBox(height: CaptainDesignTokens.s24),
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
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: CaptainTypography.titleSmall(context).copyWith(
                  fontWeight: FontWeight.w800,
                  color: destructive ? CaptainColors.error : CaptainColors.textPrimaryFor(context),
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
          padding: const EdgeInsets.symmetric(vertical: CaptainDesignTokens.s20),
          shape: RoundedRectangleBorder(borderRadius: CaptainDesignTokens.br24),
          elevation: 0,
        ),
        icon: Icon(icon, size: 28),
        label: Text(
          label,
          style: CaptainTypography.titleMedium(context).copyWith(
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
