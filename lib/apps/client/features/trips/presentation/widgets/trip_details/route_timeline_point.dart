import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// One pickup/destination row in [TripRouteTimelineCard].
class RouteTimelinePoint extends StatelessWidget {
  const RouteTimelinePoint({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.time,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withAlpha(34),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: ClientTypography.bodySmall(context).copyWith(
                  color: ClientColors.textSecondaryFor(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: ClientTypography.bodyMedium(context).copyWith(
                  fontWeight: FontWeight.w900,
                  color: ClientColors.textPrimaryFor(context),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                time,
                style: ClientTypography.bodySmall(
                  context,
                ).copyWith(color: color, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The short vertical connector line between two [RouteTimelinePoint]s.
class TimelineConnector extends StatelessWidget {
  const TimelineConnector({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 16),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Container(
          width: 2,
          height: 26,
          decoration: BoxDecoration(
            color: color.withAlpha(110),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
