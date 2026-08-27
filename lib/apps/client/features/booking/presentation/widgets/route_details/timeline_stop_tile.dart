import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/utils/open_in_maps.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/stop_meta_labels.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/stop_schedule_labels.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/route_details/timeline_stop_dot.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// One stop row in `RouteStopTimeline`: rail marker, stop name, the estimated
/// clocks for reaching and leaving it, a muted caption saying what the
/// passenger may do there, and — when the operator mapped it — a tap that
/// opens the station in a maps app.
///
/// The row is flat — no tinted card — so the eye scans the column of names
/// first and only then the supporting detail.
class TimelineStopTile extends StatelessWidget {
  const TimelineStopTile({
    super.key,
    required this.point,
    required this.isFirst,
    required this.isLast,
    required this.referenceDeparture,
  });

  final RoutePointData point;
  final bool isFirst;
  final bool isLast;

  /// The raw `HH:mm[:ss]` departure the stop clocks are computed from — see
  /// [StopScheduleLabels].
  final String referenceDeparture;

  @override
  Widget build(BuildContext context) {
    final kind = isFirst
        ? TimelineStopKind.origin
        : isLast
        ? TimelineStopKind.destination
        : TimelineStopKind.waypoint;
    final isEndpoint = kind != TimelineStopKind.waypoint;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TimelineStopDot(kind: kind, order: point.order, isLast: isLast),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 1, bottom: isLast ? 0 : 22),
              child: _StopDetails(
                point: point,
                kind: kind,
                bold: isEndpoint,
                schedule: StopScheduleLabels.of(
                  context,
                  point,
                  referenceDeparture: referenceDeparture,
                  isFirst: isFirst,
                  isLast: isLast,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StopDetails extends StatelessWidget {
  const _StopDetails({
    required this.point,
    required this.kind,
    required this.bold,
    required this.schedule,
  });

  final RoutePointData point;
  final TimelineStopKind kind;
  final bool bold;
  final StopScheduleLabels schedule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = TimelineStopDot.accentFor(context, kind);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                point.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  color: bold
                      ? ClientColors.textPrimaryFor(context)
                      : ClientColors.textPrimaryFor(context).withAlpha(215),
                  letterSpacing: -0.2,
                  height: 1.25,
                ),
              ),
            ),
            if (kind != TimelineStopKind.waypoint) ...[
              const SizedBox(width: 10),
              StopRoleChip(
                label: kind == TimelineStopKind.origin
                    ? context.l10n.booking_stopStart
                    : context.l10n.booking_stopEnd,
                color: accent,
              ),
            ],
          ],
        ),
        if (!schedule.isEmpty) ...[
          const SizedBox(height: 6),
          _StopTimes(schedule: schedule, kind: kind),
        ],
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: StopCapabilityLabel(
                capability: StopCapability.of(
                  pickupAllowed: point.pickupAllowed,
                  dropoffAllowed: point.dropoffAllowed,
                ),
              ),
            ),
            if (point.hasCoordinates) _StopDirectionsButton(point: point),
          ],
        ),
      ],
    );
  }
}

/// The station's two estimated clocks, wrapped so a long pair still fits a
/// narrow phone.
class _StopTimes extends StatelessWidget {
  const _StopTimes({required this.schedule, required this.kind});

  final StopScheduleLabels schedule;
  final TimelineStopKind kind;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: [
        if (schedule.arrival.isNotEmpty)
          StopTimeLabel(
            icon: Icons.schedule_rounded,
            label: context.l10n.booking_stopArrivalAt(schedule.arrival),
            emphasized: kind == TimelineStopKind.destination,
          ),
        if (schedule.departure.isNotEmpty)
          StopTimeLabel(
            icon: Icons.directions_bus_filled_rounded,
            label: context.l10n.booking_stopDepartureAt(schedule.departure),
            emphasized: kind == TimelineStopKind.origin,
          ),
      ],
    );
  }
}

/// Opens this station's coordinates in the rider's maps app.
///
/// A station name alone ("Gate 3, Concord Plaza Mall") is not something a
/// rider can navigate to; the coordinates the operator mapped are. Rendered
/// only when there are usable ones, so the affordance never promises a map it
/// cannot open.
class _StopDirectionsButton extends StatelessWidget {
  const _StopDirectionsButton({required this.point});

  final RoutePointData point;

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.booking_openInMaps;

    return Tooltip(
      message: label,
      child: TextButton.icon(
        onPressed: () => openCoordinatesInMaps(
          context,
          latitude: point.latitude!,
          longitude: point.longitude!,
          label: point.name,
        ),
        icon: const Icon(Icons.map_outlined, size: 16),
        label: Text(label),
        style: TextButton.styleFrom(
          foregroundColor: ClientColors.primaryFor(context),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ClientRadius.sm),
          ),
          textStyle: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
