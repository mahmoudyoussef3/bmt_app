import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_button.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

class BookingBulkActions extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final ValueChanged<String> onAssign;
  final VoidCallback onClear;

  const BookingBulkActions({
    required this.selectedCount,
    required this.onApprove,
    required this.onReject,
    required this.onAssign,
    required this.onClear,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedCount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: AppCard(
        child: Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('$selectedCount طلب محدد'),
            AppButton(label: 'اعتماد المحدد', height: 40, onPressed: onApprove),
            AppButton(
              label: 'رفض المحدد',
              height: 40,
              outline: true,
              onPressed: onReject,
            ),
            AppButton(
              label: 'إسناد إلى رحلة',
              height: 40,
              outline: true,
              onPressed: () => _openAssignDialog(context),
            ),
            TextButton(onPressed: onClear, child: const Text('إلغاء التحديد')),
          ],
        ),
      ),
    );
  }

  void _openAssignDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إسناد إلى رحلة'),
          content: const Text(
            'سيتم إسناد الطلبات المحددة إلى رحلة TR-224 التجريبية.',
          ),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                onAssign('TR-224');
                Navigator.of(context).pop();
              },
              child: const Text('إسناد'),
            ),
          ],
        ),
      ),
    );
  }
}
