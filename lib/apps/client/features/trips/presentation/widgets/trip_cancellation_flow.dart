import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip_support_data.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_cancellation_reasons.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Cancellation reason picker + confirmation dialog. Returns the chosen reason
/// once the client confirms, or null if they backed out — the caller is what
/// actually cancels the booking.
Future<String?> showTripCancellationFlow(
  BuildContext context, {
  required String tripReference,
}) async {
  String? selectedReason = kCancellationReasons.first;

  final reason = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: ClientColors.surfaceFor(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: ClientColors.borderFor(ctx),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    ctx.l10n.trips_cancelReasonTitle,
                    style: ClientTypography.headingMedium(ctx),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ctx.l10n.trips_cancelReasonTripRef(tripReference),
                    style: ClientTypography.bodySmall(
                      ctx,
                    ).copyWith(color: ClientColors.textSecondaryFor(ctx)),
                  ),
                  const SizedBox(height: 16),
                  ...kCancellationReasons.map((r) {
                    final selected = selectedReason == r;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: selected
                            ? ClientColors.primaryLight
                            : ClientColors.surfaceSubtleFor(ctx),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          onTap: () => setModalState(() => selectedReason = r),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: selected
                                  ? Border.all(
                                      color: ClientColors.primary,
                                      width: 2,
                                    )
                                  : Border.all(
                                      color: ClientColors.borderFor(ctx),
                                    ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  selected
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_off_rounded,
                                  color: ClientColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    cancellationReasonLabel(ctx, r),
                                    style: ClientTypography.bodyMedium(ctx),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  ClientButton(
                    label: ctx.l10n.payments_continueLabel,
                    expand: true,
                    onPressed: () => Navigator.pop(ctx, selectedReason),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  if (reason == null || !context.mounted) return null;

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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ClientColors.surfaceSubtleFor(ctx),
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
                    ctx.l10n.trips_cancelReasonPrefix(
                      cancellationReasonLabel(ctx, reason),
                    ),
                    style: ClientTypography.bodySmall(
                      ctx,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
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

  return confirmed == true ? reason : null;
}
