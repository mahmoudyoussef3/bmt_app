import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/tracking/progress/stop_progress.dart';

/// The timeline's vertical rail: a connecting line and this stop's dot, filled
/// once the bus has been there.
class TrackingStopRail extends StatelessWidget {
  const TrackingStopRail({
    super.key,
    required this.color,
    required this.status,
    required this.isFirst,
    required this.isLast,
  });

  final Color color;
  final StopVisitStatus status;
  final bool isFirst;
  final bool isLast;

  bool get _visited =>
      status == StopVisitStatus.departed || status == StopVisitStatus.arrived;

  @override
  Widget build(BuildContext context) {
    final line = ClientColors.borderFor(context);
    final size = status == StopVisitStatus.upcoming ? 10.0 : 14.0;

    return SizedBox(
      width: 20,
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: 2,
              color: isFirst ? Colors.transparent : line,
            ),
          ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _visited ? color : ClientColors.surfaceFor(context),
              border: Border.all(color: color, width: 2.5),
            ),
          ),
          Expanded(
            child: Container(
              width: 2,
              color: isLast ? Colors.transparent : line,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Your stop" / "Your drop-off" — the two rows that are about this rider.
class TrackingStopBadge extends StatelessWidget {
  const TrackingStopBadge({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: ClientColors.primaryFor(context).withAlpha(30),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: ClientTypography.labelSmall(context).copyWith(
          color: ClientColors.primaryFor(context),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
