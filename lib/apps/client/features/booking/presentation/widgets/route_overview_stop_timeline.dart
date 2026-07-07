import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/overview_stop_dot.dart';

/// [RouteOverviewScreen]'s simple numbered stop list (a lighter-weight
/// variant than Route Details' `RouteStopTimeline`).
class RouteOverviewStopTimeline extends StatelessWidget {
  const RouteOverviewStopTimeline({super.key, required this.stops});

  final List<RoutePointData> stops;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(stops.length, (i) {
        final stop = stops[i];
        final isFirst = i == 0;
        final isLast = i == stops.length - 1;
        return _StopRow(stop: stop, isFirst: isFirst, isLast: isLast);
      }),
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.stop,
    required this.isFirst,
    required this.isLast,
  });

  final RoutePointData stop;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OverviewStopDot(order: stop.order, isFirst: isFirst, isLast: isLast),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop.name,
                  style: ClientTypography.bodyMedium(context).copyWith(
                    fontWeight: (isFirst || isLast)
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
                if (isFirst)
                  Text(
                    'Pickup point',
                    style: ClientTypography.labelSmall(
                      context,
                    ).copyWith(color: ClientColors.primary),
                  ),
                if (isLast)
                  Text(
                    'Final stop',
                    style: ClientTypography.labelSmall(
                      context,
                    ).copyWith(color: ClientColors.journeyGreen),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
