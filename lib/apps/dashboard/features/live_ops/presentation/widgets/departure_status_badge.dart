import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../domain/entities/live_ops_snapshot.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';

/// Names how late a trip is against its schedule.
///
/// Only rendered when there is something to say: a trip comfortably ahead of
/// its departure time, or one whose schedule could not be read, shows nothing
/// rather than a reassuring badge nobody needs.
class DepartureStatusBadge extends StatelessWidget {
  const DepartureStatusBadge({
    super.key,
    required this.trip,
    required this.now,
  });

  final LiveTrip trip;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final status = trip.departureStatusAt(now);
    final delay = trip.departureDelayAt(now);

    final (label, colors, icon) = switch (status) {
      DepartureStatus.overdue => (
        'تأخّر الانطلاق ${_delayText(delay)}',
        (
          context.status(AppStatusTone.error).tint,
          context.status(AppStatusTone.error).ink,
        ),
        Icons.running_with_errors_rounded,
      ),
      DepartureStatus.due => (
        'موعد الانطلاق الآن',
        (
          context.status(AppStatusTone.warning).tint,
          context.status(AppStatusTone.warning).ink,
        ),
        Icons.schedule_rounded,
      ),
      // A trip already on the road only earns a badge if it left late — that is
      // context for the delay a passenger is feeling, not an action item.
      DepartureStatus.departed when delay != null => (
        'انطلقت متأخرة ${_delayText(delay)}',
        (
          context.status(AppStatusTone.neutral).tint,
          context.status(AppStatusTone.neutral).ink,
        ),
        Icons.history_rounded,
      ),
      _ => (null, null, null),
    };

    if (label == null || colors == null || icon == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.$2),
          const SizedBox(width: 5),
          // Flexible so a long delay string wraps/ellipsises inside a narrow
          // card instead of overflowing it at large text scales.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.$2,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Human delay text. Hours are shown with minutes because "متأخرة ساعة" reads
/// very differently from "متأخرة ساعة و٥٠ د" to someone deciding what to do.
String _delayText(Duration? delay) {
  if (delay == null) return '';
  final minutes = delay.inMinutes;
  if (minutes < 60) return '$minutes د';
  final hours = delay.inHours;
  final rest = minutes % 60;
  return rest == 0 ? '$hours س' : '$hours س و$rest د';
}
