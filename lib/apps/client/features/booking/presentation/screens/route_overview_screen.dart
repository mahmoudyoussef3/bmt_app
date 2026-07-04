import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_button.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/routes/booking_routes.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/booking_step_components.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/google_style_map_view.dart';

class RouteOverviewScreen extends StatelessWidget {
  const RouteOverviewScreen({super.key, required this.route});
  final RouteOptionData route;

  List<RoutePointData> get _sortedStops =>
      [...route.points]..sort((a, b) => a.order.compareTo(b.order));

  @override
  Widget build(BuildContext context) {
    final stops = _sortedStops;
    final mapPins = stops
        .where(_hasValidCoordinates)
        .map(
          (stop) => MapPinOption(
            label: stop.name,
            subtitle: '',
            x: stop.latitude!,
            y: stop.longitude!,
          ),
        )
        .toList();
    return Scaffold(
      backgroundColor: ClientColors.surfaceSubtleFor(context),
      bottomNavigationBar: BookingBottomAction(
        summary: Row(
          children: [
            Expanded(
              child: Text(
                'Fares from',
                style: ClientTypography.bodySmall(
                  context,
                ).copyWith(color: ClientColors.textSecondaryFor(context)),
              ),
            ),
            Text(
              route.startingPrice,
              style: ClientTypography.priceSmall(
                context,
              ).copyWith(color: ClientColors.primary),
            ),
          ],
        ),
        child: ClientButton(
          label: 'Choose this route',
          icon: const Icon(Icons.arrow_forward_rounded),
          onPressed: () => Navigator.of(
            context,
          ).pushNamed(BookingRoutes.wizard, arguments: route),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: ClientColors.surfaceFor(context),
            leading: const BackButton(),
            title: Text(
              route.routeName,
              style: ClientTypography.bodyMedium(
                context,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: mapPins.isNotEmpty
                  ? GoogleStyleMapView(
                      waypoints: mapPins,
                      cameraPadding: const EdgeInsets.fromLTRB(42, 72, 42, 36),
                    )
                  : _NoMapPlaceholder(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RouteHero(route: route, stops: stops),
                  const SizedBox(height: 16),
                  _RouteMetaRow(route: route),
                  const SizedBox(height: 20),
                  Text(
                    'All Stops (${stops.length})',
                    style: ClientTypography.labelMedium(
                      context,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _StopTimeline(stops: stops),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasValidCoordinates(RoutePointData point) {
    final latitude = point.latitude;
    final longitude = point.longitude;
    return latitude != null &&
        longitude != null &&
        latitude.isFinite &&
        longitude.isFinite &&
        (latitude != 0 || longitude != 0) &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }
}

class _RouteHero extends StatelessWidget {
  const _RouteHero({required this.route, required this.stops});

  final RouteOptionData route;
  final List<RoutePointData> stops;

  @override
  Widget build(BuildContext context) {
    final start = stops.isEmpty ? route.pickup : stops.first.name;
    final end = stops.isEmpty ? route.destination : stops.last.name;
    return BookingSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ROUTE OVERVIEW',
            style: ClientTypography.labelSmall(
              context,
            ).copyWith(color: ClientColors.primary, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _RouteEnd(label: 'FROM', value: start),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: ClientColors.primaryGradient,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: _RouteEnd(label: 'TO', value: end, alignEnd: true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteEnd extends StatelessWidget {
  const _RouteEnd({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ClientTypography.labelSmall(
            context,
          ).copyWith(color: ClientColors.textTertiaryFor(context)),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: ClientTypography.headingSmall(
            context,
          ).copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _NoMapPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    color: ClientColors.surfaceMutedFor(context),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_off_outlined,
            size: 48,
            color: ClientColors.journeySlate,
          ),
          const SizedBox(height: 10),
          Text(
            'Map coordinates unavailable',
            style: ClientTypography.labelLarge(context),
          ),
        ],
      ),
    ),
  );
}

class _RouteMetaRow extends StatelessWidget {
  const _RouteMetaRow({required this.route});
  final RouteOptionData route;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _chip(context, Icons.schedule_rounded, route.duration),
        _chip(context, Icons.straighten_rounded, route.distance),
        _chip(
          context,
          Icons.event_seat_rounded,
          '${route.availableSeats} seats',
        ),
      ],
    );
  }

  Widget _chip(BuildContext ctx, IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: ClientColors.textSecondaryFor(ctx)),
      const SizedBox(width: 4),
      Text(
        label,
        style: ClientTypography.labelSmall(
          ctx,
        ).copyWith(color: ClientColors.textSecondaryFor(ctx)),
      ),
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
              child: Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFirst
                          ? ClientColors.primary
                          : isLast
                          ? ClientColors.journeyGreen
                          : ClientColors.primaryLight,
                      border: Border.all(
                        color: isFirst || isLast
                            ? Colors.transparent
                            : ClientColors.primary,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${stop.order}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: (isFirst || isLast)
                              ? Colors.white
                              : ClientColors.primary,
                        ),
                      ),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 28,
                      color: ClientColors.primary.withAlpha(30),
                    ),
                ],
              ),
            ),
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
      }),
    );
  }
}
