import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/operation_booking.dart';
import '../cubit/bookings_cubit.dart';
import 'booking_review_intents.dart' as intents;
import 'booking_status_chips.dart';
import 'bookings_queue_board.dart' show bookingRelativeTime;

/// One booking on the card layout.
///
/// The previous card was a five-row label/value list under a grey chip: every
/// line carried the same weight, the fare — the thing a payment review is
/// about — was the last item on the card, and the two states were merged into
/// one uncoloured `محجوز / تم الرفع` string. This version has three tiers
/// (who → which trip → how much + where it stands) and colours the state.
class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.booking,
    required this.selected,
    required this.opened,
    this.isProcessing = false,
  });

  final OperationBooking booking;
  final bool selected;
  final bool opened;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<BookingsCubit>();
    final highlighted = opened || selected;

    return AnimatedContainer(
      duration: AppTokens.motionFast,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        border: Border.all(
          
          color: opened
              ? scheme.primary
              : selected
              ? scheme.primary.withAlpha(120)
              : Colors.transparent,
          width: highlighted ? 2 : 1,
        ),
      ),
      child: AppCard(
        onTap: () => cubit.openBooking(booking),
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardHeader(
              booking: booking,
              selected: selected,
              isProcessing: isProcessing,
              onToggleSelection: () => cubit.toggleSelection(booking.id),
            ),
            const SizedBox(height: AppSpacing.medium),
            _TripBlock(booking: booking),
            const SizedBox(height: AppSpacing.medium),
            _AmountRow(booking: booking),
            const SizedBox(height: AppSpacing.small),
            _CardActions(
              booking: booking,
              cubit: cubit,
              isProcessing: isProcessing,
            ),
          ],
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.booking,
    required this.selected,
    required this.isProcessing,
    required this.onToggleSelection,
  });

  final OperationBooking booking;
  final bool selected;
  final bool isProcessing;
  final VoidCallback onToggleSelection;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (booking.awaitingReview)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.xSmall),
            child: Checkbox(
              value: selected,
              onChanged: isProcessing ? null : (_) => onToggleSelection(),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking.passengerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                [
                  if (booking.bookingNumber.isNotEmpty) booking.bookingNumber,
                  if (booking.phone.isNotEmpty) booking.phone,
                  bookingRelativeTime(booking.createdAt),
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        
        Flexible(
          child: BookingStateChip.payment(booking.paymentStatus, dense: true),
        ),
      ],
    );
  }
}

class _TripBlock extends StatelessWidget {
  const _TripBlock({required this.booking});

  final OperationBooking booking;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.small),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(70),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route_rounded, size: 16, color: scheme.primary),
              const SizedBox(width: AppSpacing.xSmall),
              Expanded(
                child: Text(
                  booking.route.isEmpty ? 'مسار غير محدد' : booking.route,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xSmall),
          
          Wrap(
            spacing: AppSpacing.medium,
            runSpacing: AppSpacing.xSmall,
            children: [
              if (booking.date.isNotEmpty)
                _Fact(icon: Icons.event_rounded, value: booking.date),
              if (booking.tripTime.isNotEmpty)
                _Fact(icon: Icons.schedule_rounded, value: booking.tripTime),
              if (booking.seat.isNotEmpty)
                _Fact(icon: Icons.event_seat_rounded, value: booking.seat),
            ],
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.booking});

  final OperationBooking booking;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                booking.amountLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: scheme.primary,
                ),
              ),
              Text(
                booking.paymentMethod.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Flexible(child: BookingStateChip.booking(booking.status, dense: true)),
      ],
    );
  }
}

class _CardActions extends StatelessWidget {
  const _CardActions({
    required this.booking,
    required this.cubit,
    required this.isProcessing,
  });

  final OperationBooking booking;
  final BookingsCubit cubit;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    final approved = paymentStatusStyle(
      PaymentStatus.approved,
    ).resolve(context);
    final rejected = paymentStatusStyle(
      PaymentStatus.rejected,
    ).resolve(context);

    return Wrap(
      spacing: AppSpacing.xSmall,
      runSpacing: AppSpacing.xSmall,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (booking.awaitingReview) ...[
          FilledButton.icon(
            onPressed: isProcessing
                ? null
                : () => intents.approveBooking(context, cubit, booking),
            style: FilledButton.styleFrom(
              backgroundColor: approved.ink,
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('قبول'),
          ),
          OutlinedButton.icon(
            onPressed: isProcessing
                ? null
                : () => intents.rejectBooking(context, cubit, booking),
            style: OutlinedButton.styleFrom(
              foregroundColor: rejected.ink,
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('رفض'),
          ),
          OutlinedButton.icon(
            onPressed: isProcessing
                ? null
                : () => intents.requestReupload(context, cubit, booking),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('إعادة رفع'),
          ),
        ],
        TextButton.icon(
          onPressed: () => cubit.openBooking(booking),
          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          icon: const Icon(Icons.info_outline_rounded, size: 18),
          label: const Text('التفاصيل'),
        ),
      ],
    );
  }
}
