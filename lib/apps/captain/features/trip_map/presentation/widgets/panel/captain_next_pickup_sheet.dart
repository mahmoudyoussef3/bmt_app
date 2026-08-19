import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';
import 'package:bmt_app/apps/captain/core/widgets/captain_ticker.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/domain/entities/assigned_trip.dart';
import 'package:bmt_app/apps/captain/features/trip_execution/presentation/widgets/navigate_to_stop_button.dart';

import '../../../domain/entities/pickup_plan.dart';
import '../../cubit/captain_trip_map_state.dart';
import '../../formatters/captain_pickup_formats.dart';
import 'captain_pickup_progress_bar.dart';
import 'captain_pickup_rider_tile.dart';

class CaptainNextPickupSheet extends StatelessWidget {
  const CaptainNextPickupSheet({
    super.key,
    required this.state,
    required this.onConfirm,
    required this.onAbsent,
    required this.onReset,
    required this.onArrived,
  });

  final CaptainTripMapState state;
  final void Function(String riderId) onConfirm;
  final void Function(String riderId) onAbsent;
  final void Function(String riderId) onReset;
  final VoidCallback onArrived;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CaptainColors.surfaceFor(context),
        borderRadius: const BorderRadius.vertical(top: CaptainDesignTokens.r24),
        boxShadow: CaptainDesignTokens.floatingShadow(context),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Grabber(),
            Flexible(child: _body(context)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (state.phase.isFinished) return _FinishedCard(phase: state.phase);

    final active = state.pickup.active;
    if (active != null) {
      return _ActivePickup(
        state: state,
        active: active,
        onConfirm: onConfirm,
        onAbsent: onAbsent,
        onReset: onReset,
        onArrived: onArrived,
      );
    }

    if (state.pickup.isAllResolved) {
      return _AllResolvedCard(state: state);
    }

    return _EmptyPickupCard(hasRiders: state.riderCount > 0);
  }
}

class _ActivePickup extends StatelessWidget {
  const _ActivePickup({
    required this.state,
    required this.active,
    required this.onConfirm,
    required this.onAbsent,
    required this.onReset,
    required this.onArrived,
  });

  final CaptainTripMapState state;
  final PickupStop active;
  final void Function(String riderId) onConfirm;
  final void Function(String riderId) onAbsent;
  final void Function(String riderId) onReset;
  final VoidCallback onArrived;

  @override
  Widget build(BuildContext context) {
    final progress = state.activePickupProgress;
    final distance = CaptainPickupFormats.distance(progress?.remainingMeters);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        CaptainDesignTokens.s20,
        0,
        CaptainDesignTokens.s20,
        CaptainDesignTokens.s16,
      ),
      shrinkWrap: true,
      children: [
        Text(
          'المحطة القادمة للتجميع',
          style: CaptainTypography.labelMedium(
            context,
          ).copyWith(color: CaptainColors.primary, letterSpacing: 0.4),
        ),
        const SizedBox(height: CaptainDesignTokens.s4),
        Row(
          children: [
            const Icon(
              Icons.person_pin_circle_rounded,
              color: CaptainColors.primary,
            ),
            const SizedBox(width: CaptainDesignTokens.s8),
            Expanded(
              child: Text(
                active.name.trim().isEmpty ? 'نقطة تجميع' : active.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CaptainTypography.titleLarge(
                  context,
                ).copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
        const SizedBox(height: CaptainDesignTokens.s12),
        _MetricsRow(distance: distance, eta: progress?.eta),
        const SizedBox(height: CaptainDesignTokens.s16),
        _Actions(
          active: active,
          arriving: state.arrivingStopId == active.stopId,
          onArrived: onArrived,
        ),
        const SizedBox(height: CaptainDesignTokens.s20),
        Row(
          children: [
            Text(
              'الركاب هنا',
              style: CaptainTypography.titleSmall(
                context,
              ).copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(width: CaptainDesignTokens.s8),
            Text(
              '${active.boardedCount}/${active.total}',
              style: CaptainTypography.bodySmall(
                context,
              ).copyWith(color: CaptainColors.textSecondaryFor(context)),
            ),
          ],
        ),
        const SizedBox(height: CaptainDesignTokens.s12),
        for (final rider in active.riders) ...[
          CaptainPickupRiderTile(
            rider: rider,
            isBusy: state.pendingRiderId == rider.tripPassengerId,
            onConfirm: () => onConfirm(rider.tripPassengerId),
            onAbsent: () => onAbsent(rider.tripPassengerId),
            onReset: () => onReset(rider.tripPassengerId),
          ),
          const SizedBox(height: CaptainDesignTokens.s8),
        ],
        if (state.pickup.upcoming case final upcoming?)
          _UpcomingHint(stop: upcoming),
        const SizedBox(height: CaptainDesignTokens.s12),
        CaptainPickupProgressBar(
          boarded: state.boardedCount,
          total: state.riderCount,
        ),
      ],
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({required this.distance, required this.eta});

  final String? distance;
  final DateTime? eta;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Metric(
            icon: Icons.straighten_rounded,
            label: 'المسافة',
            value: distance ?? '—',
          ),
        ),
        const SizedBox(width: CaptainDesignTokens.s12),
        Expanded(
          child: CaptainTicker(
            builder: (context, now) => _Metric(
              icon: Icons.schedule_rounded,
              label: 'الوصول',
              value: CaptainPickupFormats.countdown(eta, now: now),
            ),
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(CaptainDesignTokens.s12),
      decoration: BoxDecoration(
        color: CaptainColors.backgroundFor(context),
        borderRadius: CaptainDesignTokens.br16,
        border: Border.all(color: CaptainColors.dividerFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 15,
                color: CaptainColors.textSecondaryFor(context),
              ),
              const SizedBox(width: CaptainDesignTokens.s4),
              Text(label, style: CaptainTypography.labelSmall(context)),
            ],
          ),
          const SizedBox(height: CaptainDesignTokens.s4),
          Text(
            value,
            style: CaptainTypography.titleMedium(
              context,
            ).copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.active,
    required this.arriving,
    required this.onArrived,
  });

  final PickupStop active;
  final bool arriving;
  final VoidCallback onArrived;

  @override
  Widget build(BuildContext context) {
    final navStop = active.stopIndex == null
        ? null
        : AssignedTripStop(
            id: active.stopId ?? '',
            name: active.name,
            latitude: active.latitude,
            longitude: active.longitude,
          );

    return Row(
      children: [
        if (navStop != null && navStop.hasCoordinates)
          Expanded(child: NavigateToStopButton(stop: navStop)),
        if (navStop != null && navStop.hasCoordinates && active.stopId != null)
          const SizedBox(width: CaptainDesignTokens.s8),
        if (active.stopId != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: arriving ? null : onArrived,
              icon: arriving
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.flag_circle_rounded, size: 18),
              label: const Text('وصلت المحطة'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: CaptainDesignTokens.s12,
                ),
                shape: const RoundedRectangleBorder(
                  borderRadius: CaptainDesignTokens.br16,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _UpcomingHint extends StatelessWidget {
  const _UpcomingHint({required this.stop});

  final PickupStop stop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CaptainDesignTokens.s12),
      child: Row(
        children: [
          Icon(
            Icons.more_horiz_rounded,
            size: 18,
            color: CaptainColors.textSecondaryFor(context),
          ),
          const SizedBox(width: CaptainDesignTokens.s8),
          Expanded(
            child: Text(
              'التالي: ${stop.name} · ${stop.total} راكب',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CaptainTypography.bodySmall(
                context,
              ).copyWith(color: CaptainColors.textSecondaryFor(context)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllResolvedCard extends StatelessWidget {
  const _AllResolvedCard({required this.state});

  final CaptainTripMapState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CaptainDesignTokens.s20,
        CaptainDesignTokens.s8,
        CaptainDesignTokens.s20,
        CaptainDesignTokens.s24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.task_alt_rounded, color: CaptainColors.success),
              const SizedBox(width: CaptainDesignTokens.s8),
              Text(
                'تم تجميع كل الركاب',
                style: CaptainTypography.titleMedium(
                  context,
                ).copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: CaptainDesignTokens.s8),
          Text(
            'واصل السير إلى الوجهة. لا توجد نقاط تجميع متبقية.',
            style: CaptainTypography.bodySmall(
              context,
            ).copyWith(color: CaptainColors.textSecondaryFor(context)),
          ),
          const SizedBox(height: CaptainDesignTokens.s16),
          CaptainPickupProgressBar(
            boarded: state.boardedCount,
            total: state.riderCount,
          ),
        ],
      ),
    );
  }
}

class _EmptyPickupCard extends StatelessWidget {
  const _EmptyPickupCard({required this.hasRiders});

  final bool hasRiders;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CaptainDesignTokens.s20,
        CaptainDesignTokens.s8,
        CaptainDesignTokens.s20,
        CaptainDesignTokens.s24,
      ),
      child: Row(
        children: [
          Icon(
            hasRiders ? Icons.people_outline_rounded : Icons.event_seat_rounded,
            color: CaptainColors.textSecondaryFor(context),
          ),
          const SizedBox(width: CaptainDesignTokens.s12),
          Expanded(
            child: Text(
              hasRiders
                  ? 'جارٍ تحميل قائمة الركاب…'
                  : 'لا يوجد ركاب على هذه الرحلة.',
              style: CaptainTypography.bodyMedium(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinishedCard extends StatelessWidget {
  const _FinishedCard({required this.phase});

  final CaptainMapPhase phase;

  @override
  Widget build(BuildContext context) {
    final cancelled = phase == CaptainMapPhase.cancelled;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        CaptainDesignTokens.s20,
        CaptainDesignTokens.s8,
        CaptainDesignTokens.s20,
        CaptainDesignTokens.s24,
      ),
      child: Row(
        children: [
          Icon(
            cancelled ? Icons.cancel_rounded : Icons.check_circle_rounded,
            color: CaptainColors.primary,
          ),
          const SizedBox(width: CaptainDesignTokens.s12),
          Expanded(
            child: Text(
              cancelled
                  ? 'أُلغيت الرحلة. توقف التتبع.'
                  : 'اكتملت الرحلة. توقف التتبع.',
              style: CaptainTypography.titleSmall(
                context,
              ).copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: CaptainDesignTokens.s12),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: CaptainColors.dividerFor(context),
          borderRadius: CaptainDesignTokens.brPill,
        ),
      ),
    );
  }
}
