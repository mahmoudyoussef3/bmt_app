import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/core/tracking/progress/route_progress_snapshot.dart';
import 'package:bmt_app/core/tracking/progress/stop_progress.dart';

/// Smart per-stop timeline: visit states from the route progress engine,
/// per-stop ETAs, the rider's boarding point, and an animated check when the
/// bus clears a stop.
class TrackingStopsTimeline extends StatelessWidget {
  const TrackingStopsTimeline({
    super.key,
    required this.progress,
    this.riderPickupName,
    this.riderBoarded = false,
  });

  final RouteProgressSnapshot? progress;
  final String? riderPickupName;
  final bool riderBoarded;

  @override
  Widget build(BuildContext context) {
    final stops = progress?.stops ?? const <StopProgress>[];
    if (stops.isEmpty) return _EmptyStops();
    final remaining = progress!.remainingStopCount;
    final next = progress!.nextStop;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.route_rounded, size: 18, color: ClientColors.primary),
                const SizedBox(width: 6),
                Text(
                  '$remaining ${remaining == 1 ? 'Stop' : 'Stops'} Remaining',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (next != null)
              Flexible(
                child: Text(
                  'Next: ${next.stop.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: ClientColors.journeyGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: ClientColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < stops.length; i++)
                _StopRow(
                  stop: stops[i],
                  isLast: i == stops.length - 1,
                  isRiderPickup: _isRiderPickup(stops[i]),
                  riderBoarded: riderBoarded,
                ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isRiderPickup(StopProgress stop) {
    final pickup = riderPickupName?.trim().toLowerCase();
    if (pickup == null || pickup.isEmpty) return false;
    return stop.stop.name.trim().toLowerCase() == pickup;
  }
}

class _EmptyStops extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Text(
        'No route stations were found for this trip.',
        style: TextStyle(color: ClientColors.textSecondaryFor(context)),
      ),
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.stop,
    required this.isLast,
    required this.isRiderPickup,
    required this.riderBoarded,
  });

  final StopProgress stop;
  final bool isLast;
  final bool isRiderPickup;
  final bool riderBoarded;

  Color _tone(BuildContext context) => switch (stop.status) {
    StopVisitStatus.departed => ClientColors.journeyGreen,
    StopVisitStatus.arrived ||
    StopVisitStatus.next => ClientColors.primary,
    StopVisitStatus.upcoming => ClientColors.borderFor(context),
  };

  @override
  Widget build(BuildContext context) {
    final tone = _tone(context);
    final passed = stop.status == StopVisitStatus.departed;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              _StopDot(status: stop.status, tone: tone),
              if (!isLast)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: 2,
                    color: passed
                        ? ClientColors.journeyGreen
                        : ClientColors.borderFor(context),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      stop.stop.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: stop.status == StopVisitStatus.upcoming
                            ? FontWeight.normal
                            : FontWeight.bold,
                        color: stop.status == StopVisitStatus.upcoming
                            ? ClientColors.textSecondaryFor(context)
                            : ClientColors.textPrimaryFor(context),
                      ),
                    ),
                  ),
                  if (isRiderPickup) ...[
                    const SizedBox(width: 6),
                    _RiderChip(boarded: riderBoarded, passed: passed),
                  ],
                  const SizedBox(width: 6),
                  _EtaLabel(stop: stop),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dot that morphs with the visit state; departing a stop scales in a check.
class _StopDot extends StatelessWidget {
  const _StopDot({required this.status, required this.tone});

  final StopVisitStatus status;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: switch (status) {
          StopVisitStatus.departed || StopVisitStatus.arrived => tone,
          _ => Colors.transparent,
        },
        border: Border.all(
          color: tone,
          width: status == StopVisitStatus.next ? 4 : 2,
        ),
        boxShadow: status == StopVisitStatus.arrived
            ? [BoxShadow(color: tone.withAlpha(110), blurRadius: 8, spreadRadius: 2)]
            : const [],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: switch (status) {
          StopVisitStatus.departed => const Icon(
            Icons.check,
            key: ValueKey('departed'),
            size: 11,
            color: Colors.white,
          ),
          StopVisitStatus.arrived => const Icon(
            Icons.directions_bus_rounded,
            key: ValueKey('arrived'),
            size: 11,
            color: Colors.white,
          ),
          _ => const SizedBox.shrink(key: ValueKey('pending')),
        },
      ),
    );
  }
}

class _RiderChip extends StatelessWidget {
  const _RiderChip({required this.boarded, required this.passed});

  final bool boarded;
  final bool passed;

  @override
  Widget build(BuildContext context) {
    final missed = passed && !boarded;
    final tone = boarded
        ? ClientColors.journeyGreen
        : missed
        ? Theme.of(context).colorScheme.error
        : ClientColors.primary;
    final label = boarded
        ? 'Boarded'
        : missed
        ? 'Stop passed'
        : 'You board here';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: tone.withAlpha(22),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: tone.withAlpha(70)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, color: tone, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _EtaLabel extends StatelessWidget {
  const _EtaLabel({required this.stop});

  final StopProgress stop;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = _describe(context);
    if (label == null) return const SizedBox.shrink();
    return Text(
      label,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: tone),
    );
  }

  (String?, Color) _describe(BuildContext context) {
    final muted = ClientColors.textSecondaryFor(context);
    switch (stop.status) {
      case StopVisitStatus.departed:
        return (null, muted);
      case StopVisitStatus.arrived:
        return ('Now', ClientColors.primary);
      case StopVisitStatus.next:
      case StopVisitStatus.upcoming:
        final eta = stop.eta;
        if (eta == null) return (null, muted);
        if (stop.etaConfidence == EtaConfidence.scheduled) {
          return ('Sched. ${_clock(eta)}', muted);
        }
        final minutes = eta.difference(DateTime.now()).inMinutes;
        if (minutes > 90) return (_clock(eta), muted);
        return (
          minutes <= 0 ? 'Arriving' : '~$minutes min',
          stop.status == StopVisitStatus.next ? ClientColors.primary : muted,
        );
    }
  }

  String _clock(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${value.hour >= 12 ? 'PM' : 'AM'}';
  }
}
