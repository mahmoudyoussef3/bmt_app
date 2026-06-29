import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_button.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';

class RouteOverviewScreen extends StatelessWidget {
  const RouteOverviewScreen({super.key, required this.route});
  final RouteOptionData route;

  static const _fallback = LatLng(30.0444, 31.2357);

  List<RoutePointData> get _sortedStops =>
      [...route.points]..sort((a, b) => a.order.compareTo(b.order));

  LatLng _latLng(RoutePointData p) =>
      LatLng(p.latitude ?? _fallback.latitude, p.longitude ?? _fallback.longitude);

  @override
  Widget build(BuildContext context) {
    final stops = _sortedStops;
    final hasCoords = stops.any((s) => s.latitude != null);
    return Scaffold(
      backgroundColor: ClientColors.surfaceSubtleFor(context),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: ClientColors.surfaceFor(context),
            leading: const BackButton(),
            title: Text(route.routeName,
                style: ClientTypography.bodyMedium(context)
                    .copyWith(fontWeight: FontWeight.w700)),
            flexibleSpace: FlexibleSpaceBar(
              background: hasCoords
                  ? _RouteMap(stops: stops, latLng: _latLng)
                  : _NoMapPlaceholder(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RouteMetaRow(route: route),
                  const SizedBox(height: 20),
                  Text('All Stops (${stops.length})',
                      style: ClientTypography.labelMedium(context)
                          .copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _StopTimeline(stops: stops),
                  const SizedBox(height: 24),
                  ClientButton(
                    label: 'Book This Route',
                    onPressed: () => Navigator.of(context).pushNamed(
                      BookingRoutes.wizard,
                      arguments: route,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteMap extends StatelessWidget {
  const _RouteMap({required this.stops, required this.latLng});
  final List<RoutePointData> stops;
  final LatLng Function(RoutePointData) latLng;

  @override
  Widget build(BuildContext context) {
    final points = stops.map(latLng).toList();
    final center = points.isNotEmpty ? points[points.length ~/ 2] : const LatLng(30.0444, 31.2357);
    return FlutterMap(
      options: MapOptions(initialCenter: center, initialZoom: 11),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.bmt.app',
        ),
        if (points.length > 1)
          PolylineLayer(polylines: [
            Polyline(points: points, color: ClientColors.primary,
                strokeWidth: 4, borderColor: Colors.white, borderStrokeWidth: 1.5),
          ]),
        MarkerLayer(
          markers: List.generate(stops.length, (i) => Marker(
            point: points[i],
            width: 28, height: 28,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == 0
                    ? ClientColors.primary
                    : i == stops.length - 1
                        ? ClientColors.journeyGreen
                        : Colors.white,
                border: Border.all(color: ClientColors.primary, width: 2),
              ),
              child: Center(
                child: Text('${stops[i].order}',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                        color: (i == 0 || i == stops.length - 1) ? Colors.white : ClientColors.primary)),
              ),
            ),
          )),
        ),
      ],
    );
  }
}

class _NoMapPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    color: ClientColors.journeySlateLight,
    child: const Center(
      child: Icon(Icons.map_outlined, size: 64, color: ClientColors.journeySlate),
    ),
  );
}

class _RouteMetaRow extends StatelessWidget {
  const _RouteMetaRow({required this.route});
  final RouteOptionData route;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _chip(context, Icons.schedule_rounded, route.duration),
        const SizedBox(width: 10),
        _chip(context, Icons.straighten_rounded, route.distance),
        const SizedBox(width: 10),
        _chip(context, Icons.event_seat_rounded, '${route.availableSeats} seats'),
        const Spacer(),
        Text(route.startingPrice,
            style: ClientTypography.headingSmall(context)
                .copyWith(color: ClientColors.primary, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _chip(BuildContext ctx, IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: ClientColors.textSecondaryFor(ctx)),
      const SizedBox(width: 4),
      Text(label, style: ClientTypography.labelSmall(ctx)
          .copyWith(color: ClientColors.textSecondaryFor(ctx))),
    ],
  );
}

class _StopTimeline extends StatelessWidget {
  const _StopTimeline({required this.stops});
  final List<RoutePointData> stops;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(stops.length, (i) {
        final stop = stops[i];
        final isFirst = i == 0;
        final isLast = i == stops.length - 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 32,
              child: Column(children: [
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFirst
                        ? ClientColors.primary
                        : isLast
                            ? ClientColors.journeyGreen
                            : ClientColors.primaryLight,
                    border: Border.all(
                        color: isFirst || isLast ? Colors.transparent : ClientColors.primary,
                        width: 1.5),
                  ),
                  child: Center(
                    child: Text('${stop.order}',
                        style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: (isFirst || isLast) ? Colors.white : ClientColors.primary,
                        )),
                  ),
                ),
                if (!isLast)
                  Container(width: 2, height: 28, color: ClientColors.primary.withAlpha(30)),
              ]),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(stop.name,
                      style: ClientTypography.bodyMedium(context).copyWith(
                        fontWeight: (isFirst || isLast) ? FontWeight.w700 : FontWeight.w400,
                      )),
                  if (isFirst)
                    Text('Pickup point',
                        style: ClientTypography.labelSmall(context)
                            .copyWith(color: ClientColors.primary)),
                  if (isLast)
                    Text('Final stop',
                        style: ClientTypography.labelSmall(context)
                            .copyWith(color: ClientColors.journeyGreen)),
                ]),
              ),
            ),
          ],
        );
      }),
    );
  }
}
