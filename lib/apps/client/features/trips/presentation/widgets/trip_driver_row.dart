import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/features/trips/domain/entities/trip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_payment_chip.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_status_mapping.dart';

/// The driver avatar/name + payment status row at the bottom of [TripCard].
class TripDriverRow extends StatelessWidget {
  const TripDriverRow({super.key, required this.trip});

  final TripData trip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: scheme.primary.withAlpha(18),
          child: Text(
            trip.driverInitials,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            trip.driverName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        TripPaymentChip(
          label: paymentLabelFor(context, trip.paymentStatus),
          status: trip.paymentStatus,
        ),
      ],
    );
  }
}
