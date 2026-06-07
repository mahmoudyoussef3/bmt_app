import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/operation_booking.dart';

class BookingCard extends StatelessWidget {
  final OperationBooking booking;
  final bool selected;
  final VoidCallback onToggleSelected;
  final VoidCallback onOpen;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onEdit;

  const BookingCard({
    required this.booking,
    required this.selected,
    required this.onToggleSelected,
    required this.onOpen,
    required this.onApprove,
    required this.onReject,
    required this.onEdit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(value: selected, onChanged: (_) => onToggleSelected()),
              Expanded(
                child: Text(
                  booking.passengerName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          _Fact(label: 'الهاتف', value: booking.phone),
          _Fact(label: 'المسار', value: booking.route),
          _Fact(
            label: 'وقت الرحلة',
            value: '${booking.date} - ${booking.tripTime}',
          ),
          _Fact(label: 'المقعد', value: booking.seat),
          _Fact(label: 'الدفع', value: booking.paymentMethod.label),
          const Divider(),
          Wrap(
            spacing: AppSpacing.xSmall,
            runSpacing: AppSpacing.xSmall,
            children: [
              TextButton(onPressed: onApprove, child: const Text('تأكيد')),
              TextButton(onPressed: onReject, child: const Text('رفض')),
              TextButton(onPressed: onEdit, child: const Text('تعديل')),
              TextButton(onPressed: onOpen, child: const Text('عرض التفاصيل')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final String label;
  final String value;

  const _Fact({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xSmall),
      child: Row(
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
