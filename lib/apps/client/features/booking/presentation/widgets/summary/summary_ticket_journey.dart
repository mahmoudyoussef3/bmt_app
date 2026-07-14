import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/utils/trip_schedule_format.dart';
import 'package:bmt_app/apps/client/core/widgets/dashed_divider.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_wizard_session.dart';

/// The ride itself: when the rider is picked up, when they arrive, and how
/// long they are on board — laid out the way a boarding pass reads.
class SummaryTicketJourney extends StatelessWidget {
  const SummaryTicketJourney({super.key, required this.session});

  final BookingWizardSession session;

  @override
  Widget build(BuildContext context) {
    final trip = session.selectedTrip;
    final departure = formatTripTime(context, trip?.departureTime ?? '');
    final arrival = formatTripTime(context, trip?.arrivalTime ?? '');
    final duration = formatTripDuration(
      trip?.departureTime ?? '',
      trip?.arrivalTime ?? '',
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _Endpoint(
            time: departure,
            stop: session.pickupStop?.name,
            caption: 'Pick-up',
            align: CrossAxisAlignment.start,
          ),
        ),
        _Connector(duration: duration),
        Expanded(
          child: _Endpoint(
            time: arrival,
            stop: session.dropoffStop?.name,
            caption: 'Drop-off',
            align: CrossAxisAlignment.end,
          ),
        ),
      ],
    );
  }
}

class _Endpoint extends StatelessWidget {
  const _Endpoint({
    required this.time,
    required this.stop,
    required this.caption,
    required this.align,
  });

  final String time;
  final String? stop;
  final String caption;
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    final textAlign = align == CrossAxisAlignment.start
        ? TextAlign.start
        : TextAlign.end;

    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          caption,
          style: ClientTypography.labelSmall(
            context,
          ).copyWith(color: ClientColors.textTertiaryFor(context)),
        ),
        const SizedBox(height: 4),
        Text(
          time.isEmpty ? '—' : time,
          textAlign: textAlign,
          style: ClientTypography.headingMedium(
            context,
          ).copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          (stop ?? '').trim().isEmpty ? '—' : stop!,
          textAlign: textAlign,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.bodySmall(
            context,
          ).copyWith(color: ClientColors.textSecondaryFor(context)),
        ),
      ],
    );
  }
}

/// The line between the two stops, carrying the ride length so the rider does
/// not have to subtract two clock times in their head.
class _Connector extends StatelessWidget {
  const _Connector({required this.duration});

  final String duration;

  @override
  Widget build(BuildContext context) {
    final accent = ClientColors.primaryFor(context);

    return SizedBox(
      width: 104,
      child: Column(
        children: [
          const SizedBox(height: 22),
          Row(
            children: [
              _Dot(color: accent, filled: false),
              Expanded(
                child: DashedDivider(color: accent.withAlpha(90)),
              ),
              Icon(Icons.directions_bus_rounded, size: 16, color: accent),
              Expanded(
                child: DashedDivider(color: accent.withAlpha(90)),
              ),
              _Dot(color: accent, filled: true),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            duration.isEmpty ? 'Direct' : duration,
            style: ClientTypography.labelSmall(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.filled});

  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: filled ? color : ClientColors.surfaceFor(context),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
    );
  }
}
