import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/empty_state.dart';

import '../../domain/entities/operation_booking.dart';
import 'booking_card.dart';

class BookingsQueueBoard extends StatelessWidget {
  final List<OperationBooking> bookings;
  final Set<String> selectedIds;
  final void Function(String bookingId) onToggleSelected;
  final ValueChanged<OperationBooking> onOpen;
  final void Function(OperationBooking booking, BookingStatus status) onStatus;
  final ValueChanged<OperationBooking> onEdit;

  const BookingsQueueBoard({
    required this.bookings,
    required this.selectedIds,
    required this.onToggleSelected,
    required this.onOpen,
    required this.onStatus,
    required this.onEdit,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: BookingStatus.values.map((status) {
          final columnBookings = bookings
              .where((booking) => booking.status == status)
              .toList();
          return SizedBox(
            width: 320,
            child: Padding(
              padding: const EdgeInsets.only(left: AppSpacing.medium),
              child: _QueueColumn(
                status: status,
                bookings: columnBookings,
                selectedIds: selectedIds,
                onToggleSelected: onToggleSelected,
                onOpen: onOpen,
                onStatus: onStatus,
                onEdit: onEdit,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _QueueColumn extends StatelessWidget {
  final BookingStatus status;
  final List<OperationBooking> bookings;
  final Set<String> selectedIds;
  final void Function(String bookingId) onToggleSelected;
  final ValueChanged<OperationBooking> onOpen;
  final void Function(OperationBooking booking, BookingStatus status) onStatus;
  final ValueChanged<OperationBooking> onEdit;

  const _QueueColumn({
    required this.status,
    required this.bookings,
    required this.selectedIds,
    required this.onToggleSelected,
    required this.onOpen,
    required this.onStatus,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  status.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text('${bookings.length}'),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          if (bookings.isEmpty)
            const SizedBox(
              height: 160,
              child: EmptyState(
                title: 'لا توجد طلبات',
                subtitle: 'القائمة فارغة حالياً.',
              ),
            )
          else
            ...bookings.map(
              (booking) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                child: BookingCard(
                  booking: booking,
                  selected: selectedIds.contains(booking.id),
                  onToggleSelected: () => onToggleSelected(booking.id),
                  onOpen: () => onOpen(booking),
                  onApprove: () => onStatus(booking, BookingStatus.confirmed),
                  onReject: () => onStatus(booking, BookingStatus.cancelled),
                  onEdit: () => onEdit(booking),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
