import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/empty_state.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_table_frame.dart';

import '../../domain/entities/operation_booking.dart';
import '../cubit/bookings_cubit.dart';
import '../cubit/bookings_state.dart';
import 'booking_card.dart';
import 'booking_review_intents.dart' as intents;

/// Renders the active-tab bookings as a data table (wide) or card list
/// (narrow), or an empty state when filters match nothing.
class BookingsQueueBoard extends StatelessWidget {
  const BookingsQueueBoard({super.key, required this.state});

  final BookingsLoaded state;

  @override
  Widget build(BuildContext context) {
    final bookings = state.filteredBookings;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (bookings.isEmpty) {
          return const AppCard(
            child: EmptyState(
              title: 'لا توجد طلبات',
              subtitle: 'لا توجد حجوزات مطابقة للفلاتر الحالية.',
            ),
          );
        }
        if (constraints.maxWidth < 900) {
          return _CardsList(state: state, bookings: bookings);
        }
        return _Table(state: state, bookings: bookings);
      },
    );
  }
}

class _CardsList extends StatelessWidget {
  const _CardsList({required this.state, required this.bookings});

  final BookingsLoaded state;
  final List<OperationBooking> bookings;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: bookings.map((booking) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: BookingCard(
            booking: booking,
            selected: state.selectedIds.contains(booking.id),
            opened: state.openedBooking?.id == booking.id,
          ),
        );
      }).toList(),
    );
  }
}

class _Table extends StatelessWidget {
  const _Table({required this.state, required this.bookings});

  final BookingsLoaded state;
  final List<OperationBooking> bookings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<BookingsCubit>();

    return DashboardTableFrame(
      icon: Icons.event_seat_rounded,
      title: 'قائمة ${state.activeTab.label}',
      trailingText: '${bookings.length} طلب',
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStatePropertyAll(
              scheme.surfaceContainerHighest.withAlpha(70),
            ),
            columns: const [
              DataColumn(label: Text('')),
              DataColumn(label: Text('رقم الحجز')),
              DataColumn(label: Text('العميل')),
              DataColumn(label: Text('المسار')),
              DataColumn(label: Text('المبلغ')),
              DataColumn(label: Text('الدفع')),
              DataColumn(label: Text('الحالة')),
              DataColumn(label: Text('التاريخ')),
              DataColumn(label: Text('إجراءات')),
            ],
            rows: bookings.map((booking) {
              return DataRow(
                selected: state.openedBooking?.id == booking.id,
                onSelectChanged: (_) => cubit.openBooking(booking),
                cells: [
                  DataCell(
                    Checkbox(
                      value: state.selectedIds.contains(booking.id),
                      onChanged: (_) => cubit.toggleSelection(booking.id),
                    ),
                  ),
                  DataCell(Text(booking.bookingNumber)),
                  DataCell(
                    Text(
                      booking.passengerName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Text(
                        booking.route,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(Text(booking.amountLabel)),
                  DataCell(Text(booking.paymentMethod.label)),
                  DataCell(
                    StatusChip(
                      label:
                          '${booking.status.label} / ${booking.paymentStatus.label}',
                    ),
                  ),
                  DataCell(Text(booking.date)),
                  DataCell(_RowActions(booking: booking, cubit: cubit)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _RowActions extends StatelessWidget {
  const _RowActions({required this.booking, required this.cubit});

  final OperationBooking booking;
  final BookingsCubit cubit;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (booking.awaitingReview) ...[
          IconButton(
            icon: const Icon(Icons.check_rounded, size: 18),
            tooltip: 'قبول',
            color: AppStatusColors.onSuccessContainer,
            onPressed: () => intents.approveBooking(context, cubit, booking),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            tooltip: 'رفض',
            color: AppStatusColors.onErrorContainer,
            onPressed: () => intents.rejectBooking(context, cubit, booking),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 18),
            tooltip: 'طلب إعادة رفع',
            color: AppStatusColors.onWarningContainer,
            onPressed: () => intents.requestReupload(context, cubit, booking),
          ),
        ],
        IconButton(
          icon: const Icon(Icons.open_in_new_rounded, size: 18),
          tooltip: 'عرض التفاصيل',
          onPressed: () => cubit.openBooking(booking),
        ),
      ],
    );
  }
}
