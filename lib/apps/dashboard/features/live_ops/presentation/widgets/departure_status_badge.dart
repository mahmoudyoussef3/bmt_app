import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/colors.dart';

import '../../domain/entities/live_ops_snapshot.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';

/// Names how late a trip is against its schedule.
///
/// Only rendered when there is something to say: a trip comfortably ahead of
/// its departure time, or one whose schedule could not be read, shows nothing
/// rather than a reassuring badge nobody needs.
///
/// Wears the console's 6px status rect and its tone line, the same mark every
/// other status label in the dashboard uses.
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

    final (label, tone, icon) = switch (status) {
      DepartureStatus.overdue => (
        'تأخّر الانطلاق ${_delayText(delay)}',
        AppStatusTone.error,
        Icons.running_with_errors_rounded,
      ),
      DepartureStatus.due => (
        'موعد الانطلاق الآن',
        AppStatusTone.warning,
        Icons.schedule_rounded,
      ),

      DepartureStatus.departed when delay != null => (
        'انطلقت متأخرة ${_delayText(delay)}',
        AppStatusTone.neutral,
        Icons.history_rounded,
      ),
      _ => (null, null, null),
    };

    if (label == null || tone == null || icon == null) {
      return const SizedBox.shrink();
    }

    final style = context.status(tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: style.tint,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: DashboardColors.statusLine(context, tone)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: style.ink),
          const SizedBox(width: 5),

          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: style.ink,
                fontWeight: FontWeight.w700,
                height: 1.3,
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
