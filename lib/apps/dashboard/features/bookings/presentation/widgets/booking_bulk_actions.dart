import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../cubit/bookings_cubit.dart';
import '../cubit/bookings_state.dart';
import 'booking_action_dialogs.dart';
import 'booking_status_chips.dart';
import '../../domain/entities/operation_booking.dart';

/// Batch review bar shown when one or more bookings are selected. Both actions
/// run the same audited per-booking RPCs (`approve_payment` / `reject_payment`)
/// in sequence — there is no direct bulk status write.
class BookingBulkActions extends StatelessWidget {
  const BookingBulkActions({super.key, required this.state});

  final BookingsLoaded state;

  @override
  Widget build(BuildContext context) {
    final selectedCount = state.selectedIds.length;
    if (selectedCount == 0) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final cubit = context.read<BookingsCubit>();
    final busy = state.isProcessing;
    final approved = paymentStatusStyle(
      PaymentStatus.approved,
    ).resolve(context);
    final rejected = paymentStatusStyle(
      PaymentStatus.rejected,
    ).resolve(context);

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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (busy)
                  const Padding(
                    padding: EdgeInsetsDirectional.only(end: AppSpacing.small),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: AppSpacing.small,
                    ),
                    child: Icon(
                      Icons.checklist_rounded,
                      size: 18,
                      color: scheme.primary,
                    ),
                  ),
                Flexible(
                  child: Text(
                    busy
                        ? 'جارٍ تنفيذ المراجعة على $selectedCount طلب…'
                        : '$selectedCount طلب محدد للمراجعة',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            FilledButton.icon(
              onPressed: busy ? null : () => _bulkApprove(context, cubit),
              style: FilledButton.styleFrom(
                backgroundColor: approved.fill,
                foregroundColor: approved.onFill,
              ),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: Text('اعتماد الدفع ($selectedCount)'),
            ),
            OutlinedButton.icon(
              onPressed: busy ? null : () => _bulkReject(context, cubit),
              style: OutlinedButton.styleFrom(
                foregroundColor: rejected.accent,
                side: BorderSide(color: rejected.accent.withAlpha(110)),
              ),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: Text('رفض الدفع ($selectedCount)'),
            ),
            TextButton(
              onPressed: busy ? null : cubit.clearSelection,
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
      message: 'سيتم اعتماد الدفع لـ ${state.selectedIds.length} حجز محدد.',
      onConfirm: cubit.bulkApprove,
    );
  }

  void _bulkReject(BuildContext context, BookingsCubit cubit) {
    openRejectionDialog(
      context,
      message:
          'سيتم رفض الدفع لـ ${state.selectedIds.length} حجز محدد وتحرير مقاعدها.',
      onConfirm: cubit.bulkReject,
    );
  }
}
