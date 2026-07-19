import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_cancellation_reasons.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Final confirmation before the booking is cancelled. Returns true only when
/// the passenger explicitly confirms.
Future<bool> showTripCancellationConfirmDialog(
  BuildContext context, {
  required String reason,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(ctx.l10n.trips_cancelDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ctx.l10n.trips_cancelDialogBody,
            style: ClientTypography.bodySmall(ctx),
          ),
          const SizedBox(height: 12),
          _ReasonRecap(reason: reason),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(ctx.l10n.trips_keepTrip),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: ClientColors.primary),
          child: Text(ctx.l10n.trips_confirmCancellation),
        ),
      ],
    ),
  );

  return confirmed == true;
}

class _ReasonRecap extends StatelessWidget {
  const _ReasonRecap({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ClientColors.surfaceSubtleFor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: ClientColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.trips_cancelReasonPrefix(
                cancellationReasonLabel(context, reason),
              ),
              style: ClientTypography.bodySmall(
                context,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
