import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/map/route_map_models.dart';

/// "850 m" under a kilometre, otherwise "12.4 km".
String formatRouteDistance(double meters) => meters < 1000
    ? '${meters.round()} m'
    : '${(meters / 1000).toStringAsFixed(1)} km';

/// "25 min" under an hour, otherwise "1h 05m".
String formatRouteDuration(double seconds) {
  final minutes = (seconds / 60).round();
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return '${hours}h ${rest.toString().padLeft(2, '0')}m';
}

/// Transit-style facts card: headline distance · duration, then compact chips
/// for stops, seats, passengers and status. Values that are unknown simply
/// don't render, so the card degrades gracefully down to a stop count.
class RouteMapInfoPanel extends StatelessWidget {
  const RouteMapInfoPanel({
    super.key,
    required this.stopCount,
    this.info = const RouteMapInfoData(),
  });

  final int stopCount;
  final RouteMapInfoData info;

  @override
  Widget build(BuildContext context) {
    final headline = [
      ?info.distance,
      ?info.duration,
    ].where((value) => value.trim().isNotEmpty).join('  ·  ');

    return Container(
      constraints: const BoxConstraints(maxWidth: 250),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: RouteMapStyle.surface(context).withAlpha(245),
        borderRadius: BorderRadius.circular(ClientRadius.lg),
        border: Border.all(color: RouteMapStyle.border(context)),
        boxShadow: RouteMapStyle.shadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (headline.isNotEmpty) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.near_me_rounded,
                  size: 15,
                  color: RouteMapStyle.routeLine(context),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    headline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: RouteMapStyle.pillLabel(
                      context,
                    ).copyWith(fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
          ],
          Wrap(
            spacing: 10,
            runSpacing: 5,
            children: [
              _Fact(
                icon: Icons.route_rounded,
                label: stopCount == 1 ? '1 stop' : '$stopCount stops',
              ),
              if (info.availableSeats != null)
                _Fact(
                  icon: Icons.event_seat_rounded,
                  label: '${info.availableSeats} seats',
                ),
              if (info.passengerCount != null)
                _Fact(
                  icon: Icons.people_alt_rounded,
                  label: '${info.passengerCount} riders',
                ),
              if (info.status != null && info.status!.trim().isNotEmpty)
                _Fact(icon: Icons.circle, iconSize: 8, label: info.status!),
            ],
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, this.iconSize = 13});

  final IconData icon;
  final String label;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: RouteMapStyle.stop(context)),
        const SizedBox(width: 4),
        Text(
          label,
          style: RouteMapStyle.pillLabel(
            context,
          ).copyWith(color: RouteMapStyle.onSurfaceMuted(context)),
        ),
      ],
    );
  }
}

/// Subtle pill shown while road geometry is being fetched. Deliberately
/// quiet — the straight-line route is already visible underneath.
class RouteMapLoadingPill extends StatelessWidget {
  const RouteMapLoadingPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: RouteMapStyle.surface(context).withAlpha(235),
        borderRadius: RouteMapStyle.pill,
        border: Border.all(color: RouteMapStyle.border(context)),
        boxShadow: RouteMapStyle.shadow(context),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 11,
            height: 11,
            child: CircularProgressIndicator(
              strokeWidth: 1.8,
              color: RouteMapStyle.routeLine(context),
            ),
          ),
          const SizedBox(width: 7),
          Text('Tracing road…', style: RouteMapStyle.pillLabel(context)),
        ],
      ),
    );
  }
}
