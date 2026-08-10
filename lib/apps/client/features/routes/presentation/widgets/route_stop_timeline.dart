import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import '../../domain/entities/route_stop.dart';

/// The route's full corridor as an ordered, connected list of stops.
class RouteStopTimeline extends StatelessWidget {
  const RouteStopTimeline({super.key, required this.stops});

  final List<RouteStop> stops;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(stops.length, (index) {
        return _StopRow(
          stop: stops[index],
          isFirst: index == 0,
          isLast: index == stops.length - 1,
        );
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

  final RouteStop stop;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final accent = ClientColors.primaryFor(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isFirst || isLast) ? accent : Colors.transparent,
                  border: Border.all(
                    color: accent,
                    width: (isFirst || isLast) ? 0 : 3,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 3,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: accent.withAlpha(100),
                  ),
                ),
            ],
          ),
          const SizedBox(width: ClientSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: ClientSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stop.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ClientTypography.bodyMedium(context).copyWith(
                      fontWeight: (isFirst || isLast)
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                  ),
                  if (stop.area.isNotEmpty || stop.estimatedArrivalTime.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      [
                        stop.area,
                        stop.estimatedArrivalTime,
                      ].where((part) => part.isNotEmpty).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ClientTypography.labelSmall(context).copyWith(
                        color: ClientColors.textTertiaryFor(context),
                      ),
                    ),
                  ],
                  if (!stop.pickupAllowed || !stop.dropoffAllowed) ...[
                    const SizedBox(height: 4),
                    Text(
                      !stop.pickupAllowed
                          ? context.l10n.routes_dropoffOnly
                          : context.l10n.routes_pickupOnly,
                      style: ClientTypography.labelSmall(
                        context,
                      ).copyWith(color: accent, fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
