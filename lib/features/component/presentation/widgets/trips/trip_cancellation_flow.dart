import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:bmt_app/features/component/presentation/trips/trips_mock_data.dart';

/// Cancellation reason picker + confirmation dialog (UI only).
Future<bool> showTripCancellationFlow(
  BuildContext context, {
  required String tripReference,
}) async {
  String? selectedReason = kCancellationReasons.first;

  final reason = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardColor,
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
                        color: Theme.of(ctx).colorScheme.outline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Cancellation reason',
                    style: Theme.of(ctx).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Trip $tripReference',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: Theme.of(ctx).colorScheme.onSurface.withAlpha(170),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...kCancellationReasons.map((r) {
                    final selected = selectedReason == r;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppSurface(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        radius: 14,
                        onTap: () => setModalState(() => selectedReason = r),
                        border: selected
                            ? Border.all(
                                color: Theme.of(ctx).colorScheme.primary,
                                width: 2,
                              )
                            : null,
                        child: Row(
                          children: [
                            Icon(
                              selected
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_off_rounded,
                              color: Theme.of(ctx).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                r,
                                style: Theme.of(ctx).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Continue',
                    height: 50,
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
            style: Theme.of(ctx).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: Theme.of(ctx).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Reason: $reason',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
