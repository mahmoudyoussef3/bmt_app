import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/stop_role_chips.dart';

/// One stop row in [RouteStopTimeline]: a colored dot/connector plus the
/// stop's name and pickup/drop-off capability chips.
class TimelineStopTile extends StatelessWidget {
  const TimelineStopTile({
    super.key,
    required this.point,
    required this.isFirst,
    required this.isLast,
  });

  final RoutePointData point;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = isFirst
        ? ClientColors.journeyGreen
        : isLast
        ? ClientColors.primaryFor(context)
        : ClientColors.accent;
    final bgColor = isFirst
        ? ClientColors.journeyGreenLight
        : isLast
        ? ClientColors.primaryContainerFor(context)
        : ClientColors.journeyAmberLight;
    final roleLabel = isFirst
        ? 'Start'
        : isLast
        ? 'End'
        : 'Stop ${point.order}';

    return Padding(
      padding: EdgeInsets.fromLTRB(18, 0, 18, isLast ? 18 : 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Dot(color: color, isFirst: isFirst, isLast: isLast),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                child: _StopCard(
                  point: point,
                  roleLabel: roleLabel,
                  color: color,
                  bgColor: bgColor,
                  scheme: scheme,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.isFirst, required this.isLast});

  final Color color;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: scheme.surface, width: 4),
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(65),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(
            isFirst
                ? Icons.trip_origin_rounded
                : isLast
                ? Icons.flag_rounded
                : Icons.place_rounded,
            size: 13,
            color: Colors.white,
          ),
        ),
        if (!isLast)
          Expanded(
            child: Container(
              width: 3,
              margin: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: color.withAlpha(95),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
      ],
    );
  }
}

class _StopCard extends StatelessWidget {
  const _StopCard({
    required this.point,
    required this.roleLabel,
    required this.color,
    required this.bgColor,
    required this.scheme,
  });

  final RoutePointData point;
  final String roleLabel;
  final Color color;
  final Color bgColor;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor.withAlpha(isDark ? 34 : 120),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  point.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 8),
              StopRoleChip(label: roleLabel, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (point.pickupAllowed)
                CapabilityChip(
                  label: 'Pickup',
                  icon: Icons.login_rounded,
                  color: ClientColors.journeyGreen,
                ),
              if (point.dropoffAllowed)
                CapabilityChip(
                  label: 'Drop-off',
                  icon: Icons.logout_rounded,
                  color: ClientColors.primary,
                ),
              if (!point.pickupAllowed && !point.dropoffAllowed)
                CapabilityChip(
                  label: 'Pass-through',
                  icon: Icons.route_rounded,
                  color: scheme.outline,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
