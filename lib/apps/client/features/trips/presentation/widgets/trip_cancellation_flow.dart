import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/trips/domain/entities/trip_support_data.dart';

/// Cancellation reason picker + confirmation dialog (UI only).
Future<bool> showTripCancellationFlow(
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
                    'Cancellation reason',
                    style: ClientTypography.headingMedium(ctx),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Trip $tripReference',
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
                                    r,
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
                    label: 'Continue',
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

  if (reason == null || !context.mounted) return false;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Cancel this trip?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your booking will be cancelled and a refund will be processed '
            'according to policy (demo UI).',
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
                    'Reason: $reason',
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
          child: const Text('Keep trip'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: ClientColors.primary),
          child: const Text('Confirm cancellation'),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Trip cancelled (demo)')));
    return true;
  }
  return false;
}
