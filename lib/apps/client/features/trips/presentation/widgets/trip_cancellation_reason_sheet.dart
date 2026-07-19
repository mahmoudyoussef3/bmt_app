import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip_support_data.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_cancellation_reason_option.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_sheet_grabber.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Asks why the passenger is cancelling. Returns the chosen reason, or null if
/// they dismissed the sheet.
Future<String?> showTripCancellationReasonSheet(
  BuildContext context, {
  required String tripReference,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: ClientColors.surfaceFor(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _ReasonSheet(tripReference: tripReference),
  );
}

class _ReasonSheet extends StatefulWidget {
  const _ReasonSheet({required this.tripReference});

  final String tripReference;

  @override
  State<_ReasonSheet> createState() => _ReasonSheetState();
}

class _ReasonSheetState extends State<_ReasonSheet> {
  String _selected = kCancellationReasons.first;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TripSheetGrabber(),
            const SizedBox(height: 16),
            Text(
              context.l10n.trips_cancelReasonTitle,
              style: ClientTypography.headingMedium(context),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.trips_cancelReasonTripRef(widget.tripReference),
              style: ClientTypography.bodySmall(
                context,
              ).copyWith(color: ClientColors.textSecondaryFor(context)),
            ),
            const SizedBox(height: 16),
            for (final reason in kCancellationReasons)
              TripCancellationReasonOption(
                reason: reason,
                selected: _selected == reason,
                onTap: () => setState(() => _selected = reason),
              ),
            const SizedBox(height: 16),
            ClientButton(
              label: context.l10n.payments_continueLabel,
              expand: true,
              onPressed: () => Navigator.pop(context, _selected),
            ),
          ],
        ),
      ),
    );
  }
}
