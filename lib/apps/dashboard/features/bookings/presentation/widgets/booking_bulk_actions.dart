import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../cubit/bookings_cubit.dart';
import 'booking_action_dialogs.dart';

/// Batch review bar shown when one or more bookings are selected. Both actions
/// run the same audited per-booking RPCs (`approve_payment` / `reject_payment`)
/// in sequence — there is no direct bulk status write.
class BookingBulkActions extends StatelessWidget {
  const BookingBulkActions({super.key, required this.selectedCount});

  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    if (selectedCount == 0) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<BookingsCubit>();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.medium),
        decoration: BoxDecoration(
          color: scheme.primary.withAlpha(16),
          borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
          border: Border.all(color: scheme.primary.withAlpha(55)),
        ),
        child: Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '$selectedCount طلب محدد',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: scheme.primary,
              ),
            ),
            FilledButton.icon(
              onPressed: () => _bulkApprove(context, cubit),
              icon: const Icon(Icons.check_rounded),
              label: const Text('اعتماد الدفع'),
            ),
            OutlinedButton.icon(
              onPressed: () => _bulkReject(context, cubit),
              icon: const Icon(Icons.close_rounded),
              label: const Text('رفض الدفع'),
            ),
            TextButton(
              onPressed: cubit.clearSelection,
              child: const Text('إلغاء التحديد'),
            ),
          ],
        ),
      ),
    );
  }

  void _bulkApprove(BuildContext context, BookingsCubit cubit) {
    openApprovalDialog(
      context,
      message: 'سيتم اعتماد الدفع لـ $selectedCount حجز محدد.',
      onConfirm: cubit.bulkApprove,
    );
  }

  void _bulkReject(BuildContext context, BookingsCubit cubit) {
    openRejectionDialog(
      context,
      message: 'سيتم رفض الدفع لـ $selectedCount حجز محدد وتحرير مقاعدها.',
      onConfirm: cubit.bulkReject,
    );
  }
}
