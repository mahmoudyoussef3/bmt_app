import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../domain/entities/operation_booking.dart';
import '../cubit/bookings_cubit.dart';
import 'booking_review_intents.dart' as intents;

/// Compact booking summary used on narrow layouts.
class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.booking,
    required this.selected,
    required this.opened,
  });

  final OperationBooking booking;
  final bool selected;
  final bool opened;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<BookingsCubit>();

    return AppCard(
      onTap: () => cubit.openBooking(booking),
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: opened ? scheme.primary.withAlpha(120) : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: selected,
                  onChanged: (_) => cubit.toggleSelection(booking.id),
                ),
                Expanded(
                  child: Text(
                    booking.passengerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                StatusChip(
                  label:
                      '${booking.status.label} / ${booking.paymentStatus.label}',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            _MiniInfo(label: 'رقم الحجز', value: booking.bookingNumber),
            _MiniInfo(label: 'الهاتف', value: booking.phone),
            _MiniInfo(label: 'المسار', value: booking.route),
            _MiniInfo(
              label: 'الرحلة',
              value: '${booking.date} - ${booking.tripTime}',
            ),
            _MiniInfo(label: 'الدفع', value: booking.paymentMethod.label),
            const SizedBox(height: AppSpacing.small),
            Row(
              children: [
                const Spacer(),
                Text(
                  booking.amountLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.large),
            Wrap(
              spacing: AppSpacing.xSmall,
              runSpacing: AppSpacing.xSmall,
              children: [
                if (booking.awaitingReview) ...[
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        intents.approveBooking(context, cubit, booking),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('قبول'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        intents.rejectBooking(context, cubit, booking),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('رفض'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        intents.requestReupload(context, cubit, booking),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('إعادة رفع'),
                  ),
                ],
                TextButton.icon(
                  onPressed: () => cubit.openBooking(booking),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('التفاصيل'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xSmall),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
