import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/utils/trip_schedule_format.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/payments/domain/entities/payment_models.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The ride the rider is paying for: pick-up on the left, drop-off on the
/// right, ride length on the line between them — the way a boarding pass reads.
class CheckoutTicketJourney extends StatelessWidget {
  const CheckoutTicketJourney({super.key, required this.data});

  final PaymentCheckoutData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _Endpoint(
            caption: context.l10n.common_pickup,
            time: formatTripTime(context, data.departureTime),
            stop: data.pickupPoint,
            align: CrossAxisAlignment.start,
          ),
        ),
        _Connector(
          duration: formatTripDuration(
            context,
            data.departureTime,
            data.arrivalTime,
          ),
        ),
        Expanded(
          child: _Endpoint(
            caption: context.l10n.common_dropOff,
            time: formatTripTime(context, data.arrivalTime),
            stop: data.destination,
            align: CrossAxisAlignment.end,
          ),
        ),
      ],
    );
  }
}

class _Endpoint extends StatelessWidget {
  const _Endpoint({
    required this.caption,
    required this.time,
    required this.stop,
    required this.align,
  });

  final String caption;
  final String time;
  final String stop;
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
          stop.trim().isEmpty ? '—' : stop,
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

class _Connector extends StatelessWidget {
  const _Connector({required this.duration});

  final String duration;

  @override
  Widget build(BuildContext context) {
    final accent = ClientColors.primaryFor(context);

    return SizedBox(
      width: 96,
      child: Column(
        children: [
          const SizedBox(height: 22),
          Row(
            children: [
              _Dot(color: accent, filled: false),
              Expanded(child: DashedDivider(color: accent.withAlpha(90))),
              Icon(Icons.directions_bus_rounded, size: 16, color: accent),
              Expanded(child: DashedDivider(color: accent.withAlpha(90))),
              _Dot(color: accent, filled: true),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            duration.isEmpty ? context.l10n.payments_directTrip : duration,
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
