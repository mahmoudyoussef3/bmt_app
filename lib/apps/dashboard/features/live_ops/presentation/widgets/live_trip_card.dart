import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/progress_bar.dart';

import '../../domain/entities/fleet_feed.dart';
import '../../domain/entities/live_ops_snapshot.dart';
import 'departure_status_badge.dart';
import 'live_ops_format.dart';
import 'tracking_health_badge.dart';

/// One trip on the road: departure, route, crew, occupancy and — the reason this
/// screen exists — an honest read of whether its position feed is live and when
/// it last reported.
///
/// **A row on the panel's surface, not a card.** It kept the name it has always
/// had, but it is now built to the same shape as Home's departure board:
/// departure time in its own column, a hairline, the route with its crew on one
/// meta line, the seat track, and the tracking mark trailing. Two console laws
/// were being broken by the card it used to be — a card nested inside the panel
/// card it already sits in, and two screens listing the same objects at the same
/// density in two different visual languages.
///
/// The whole row is tappable: it selects the trip, which focuses the map on it.
/// Selection is drawn as a wash plus a border rather than colour alone, so it
/// survives greyscale and high-contrast modes.
///
/// ## It sheds parts rather than squeezing them
///
/// The row is laid out three ways, and which one it takes is decided against the
/// reader's text size, not the pixel width — what runs out at the narrow end is
/// the text. Widest: everything, with the seat track in its own column. Middle:
/// the track folds into the meta line as a plain «١١/١٤». Narrowest: the
/// tracking badge drops from the trailing edge down into the meta line, and the
/// top row keeps only the departure and the route, because a trailing badge and
/// a departure column together leave a route nothing to be read in.
class LiveTripCard extends StatelessWidget {
  final LiveTrip trip;

  /// This trip's live position, or `null` when it has never reported one.
  ///
  /// Passed in rather than read off [trip] because the roster's fix is only the
  /// seed the board opened with; the feed Bloc holds the current one. A row
  /// reading `trip.lastFix` would keep showing the position the last roster
  /// refetch happened to carry, which after this change is up to two minutes old.
  final TrackedVehicle? vehicle;

  final DateTime now;
  final bool selected;
  final VoidCallback? onTap;

  const LiveTripCard({
    super.key,
    required this.trip,
    required this.now,
    this.vehicle,
    this.selected = false,
    this.onTap,
  });

  /// At or above this the seat track gets a column of its own.
  static const double _trackWidth = 620;

  /// Below this the tracking badge leaves the trailing edge for the meta line.
  static const double _badgeInlineWidth = 460;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final health = vehicle?.healthAt(now) ?? TrackingHealth.unknown;
    final age = vehicle == null
        ? null
        : _nonNegative(now.difference(vehicle!.receivedAt));
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    final radius = BorderRadius.circular(10);

    final body = LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final showTrack = width >= _trackWidth * scale;
        final badgeTrails = width >= _badgeInlineWidth * scale;

        final meta = Wrap(
          spacing: AppSpacing.medium,
          runSpacing: AppSpacing.xSmall,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (!badgeTrails) TrackingHealthBadge(health: health),
            _MetaChip(
              icon: DashboardIcons.captain,
              label: trip.driverName.trim().isEmpty
                  ? 'بدون سائق'
                  : trip.driverName,
            ),
            _MetaChip(
              icon: DashboardIcons.vehicle,
              label: trip.vehicleLabel.trim().isEmpty
                  ? 'بدون مركبة'
                  : trip.vehicleLabel,
            ),
            if (!showTrack)
              _MetaChip(
                icon: DashboardIcons.seats,
                label: '${trip.bookedSeats}/${trip.capacity}',
              ),
            _MetaChip(
              icon: Icons.my_location_rounded,
              label: _trackingText(health: health, age: age),
            ),
            if (_reportsDeparture(now))
              DepartureStatusBadge(trip: trip, now: now),
          ],
        );

        final departure = SizedBox(
          width: 56 * scale,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                trip.departureTime.isEmpty ? '--:--' : trip.departureTime,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                trip.isInProgress ? 'انطلقت' : 'الصعود',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelSmall?.copyWith(
                  color: DashboardColors.faintInk(context),
                ),
              ),
            ],
          ),
        );

        final route = Text(
          trip.routeName.isEmpty ? 'رحلة بدون مسار' : trip.routeName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
        );

        final hairline = SizedBox(
          width: 1,
          height: 34,
          child: ColoredBox(color: DashboardColors.divider(context)),
        );

        if (!badgeTrails) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  departure,
                  const SizedBox(width: AppSpacing.small),
                  hairline,
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(child: route),
                ],
              ),
              const SizedBox(height: AppSpacing.xSmall),
              meta,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            departure,
            const SizedBox(width: AppSpacing.small),
            hairline,
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [route, const SizedBox(height: 2), meta],
              ),
            ),
            if (showTrack) ...[
              const SizedBox(width: AppSpacing.medium),
              SizedBox(
                width: 96 * scale,
                child: Row(
                  children: [
                    Expanded(
                      child: AppProgressBar(progress: trip.occupancyRatio),
                    ),
                    const SizedBox(width: AppSpacing.xSmall),
                    Text(
                      '${trip.bookedSeats}/${trip.capacity}',
                      maxLines: 1,
                      style: text.labelSmall?.copyWith(
                        color: DashboardColors.mutedInk(context),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(width: AppSpacing.medium),
            TrackingHealthBadge(health: health),
          ],
        );
      },
    );

    final surface = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: AppSpacing.small,
      ),
      decoration: BoxDecoration(
        color: selected ? DashboardColors.tableRowHover(context) : null,
        borderRadius: radius,
        border: Border.all(
          color: selected
              ? DashboardColors.accentFill(context)
              : Colors.transparent,
        ),
      ),
      child: body,
    );

    if (onTap == null) return surface;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(onTap: onTap, borderRadius: radius, child: surface),
      ),
    );
  }

  /// Whether [DepartureStatusBadge] would actually draw something at [at].
  ///
  /// Asked here rather than letting the badge shrink itself away, because a
  /// zero-size child inside a [Wrap] still takes the run's spacing — a gap in the
  /// meta line with nothing in it.
  bool _reportsDeparture(DateTime at) => switch (trip.departureStatusAt(at)) {
    DepartureStatus.overdue || DepartureStatus.due => true,
    DepartureStatus.departed => trip.departureDelayAt(at) != null,
    DepartureStatus.pending || DepartureStatus.unknown => false,
  };

  /// What the feed can honestly claim about this trip, in the width of a meta
  /// chip.
  static String _trackingText({
    required TrackingHealth health,
    required Duration? age,
  }) {
    if (health == TrackingHealth.unknown || age == null) {
      return 'لم يُشارك الموقع بعد';
    }
    return 'آخر تحديث ${liveOpsAgo(age)}';
  }

  /// A captain's clock running ahead of the desk's must never render as a
  /// negative age.
  static Duration _nonNegative(Duration d) => d.isNegative ? Duration.zero : d;
}

/// One fact on the row's meta line — a small glyph and a muted label, the same
/// mark Home's departure board uses for a captain and a vehicle.
///
/// The label is [Flexible] rather than plain: these carry a driver's full name
/// inside a [Wrap] that may be a hundred pixels wide, and a `Text` in an
/// unflexed `Row` has no width to ellipsize against.
class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = DashboardColors.mutedInk(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
