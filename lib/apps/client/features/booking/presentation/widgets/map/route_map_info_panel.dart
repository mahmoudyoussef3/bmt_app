import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/booking/presentation/widgets/map/booking_map_adapters.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/maps/map_style.dart';
import 'package:bmt_app/core/widgets/maps/overlays/glass_info_card.dart';

/// "850 m" under a kilometre, otherwise "12.4 km".
String formatRouteDistance(BuildContext context, double meters) {
  final l10n = context.l10n;
  return meters < 1000
      ? l10n.booking_distanceMeters(meters.round())
      : l10n.booking_distanceKm((meters / 1000).toStringAsFixed(1));
}

/// "25 min" under an hour, otherwise "1h 05m".
String formatRouteDuration(BuildContext context, double seconds) {
  final minutes = (seconds / 60).round();
  final l10n = context.l10n;
  if (minutes < 60) return l10n.common_durationMinutes(minutes);
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (rest == 0) return l10n.common_durationHours(hours);
  return l10n.common_durationHoursMinutes(hours, rest);
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
    final l10n = context.l10n;
    final headline = <String>[
      if ((info.distance ?? '').trim().isNotEmpty) info.distance!.trim(),
      if ((info.duration ?? '').trim().isNotEmpty) info.duration!.trim(),
    ].join('  ·  ');

    return GlassInfoCard(
      maxWidth: 250,
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
                  color: MapStyle.routeLine(context),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    headline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: MapStyle.pillLabel(context).copyWith(fontSize: 13),
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
                label: stopCount == 1
                    ? l10n.booking_oneStop
                    : l10n.booking_stopsCountLabel(stopCount),
              ),
              if (info.availableSeats != null)
                _Fact(
                  icon: Icons.event_seat_rounded,
                  label: l10n.booking_seatsCountLabel(info.availableSeats!),
                ),
              if (info.passengerCount != null)
                _Fact(
                  icon: Icons.people_alt_rounded,
                  label: l10n.booking_ridersCount(info.passengerCount!),
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
        Icon(icon, size: iconSize, color: MapStyle.stop(context)),
        const SizedBox(width: 4),
        Text(
          label,
          style: MapStyle.pillLabel(
            context,
          ).copyWith(color: MapStyle.onSurfaceMuted(context)),
        ),
      ],
    );
  }
}

/// Subtle pill shown while road geometry is being fetched. Deliberately
/// quiet — the straight-line route is already visible underneath. Uses a
/// pulsing dot rather than a spinner, consistent with the rest of the map
/// kit's "never a bare progress indicator" rule.
class RouteMapLoadingPill extends StatefulWidget {
  const RouteMapLoadingPill({super.key});

  @override
  State<RouteMapLoadingPill> createState() => _RouteMapLoadingPillState();
}

class _RouteMapLoadingPillState extends State<RouteMapLoadingPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: MapStyle.surface(context).withAlpha(235),
        borderRadius: MapStyle.pill,
        border: Border.all(color: MapStyle.border(context)),
        boxShadow: MapStyle.shadow(context),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _controller.drive(CurveTween(curve: Curves.easeInOut)),
            child: Icon(
              Icons.route_rounded,
              size: 13,
              color: MapStyle.routeLine(context),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            context.l10n.booking_tracingRoad,
            style: MapStyle.pillLabel(context),
          ),
        ],
      ),
    );
  }
}
