import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/operation_booking.dart';
import '../cubit/bookings_cubit.dart';
import '../cubit/bookings_state.dart';
import '../widgets/booking_bulk_actions.dart';
import '../widgets/booking_details_panel.dart';
import '../widgets/booking_filters_bar.dart';
import '../widgets/bookings_queue_board.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingsCubit, BookingsState>(
      builder: (context, state) {
        return switch (state) {
          BookingsLoading() => const Center(child: CircularProgressIndicator()),
          BookingsError(:final message) => Center(child: Text(message)),
          BookingsLoaded() => _BookingsLoadedView(state: state),
        };
      },
    );
  }
}

class _BookingsLoadedView extends StatelessWidget {
  final BookingsLoaded state;

  const _BookingsLoadedView({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingsCubit>();
    final opened = state.openedBooking;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.large),
            children: [
              _Header(total: state.filteredBookings.length),
              const SizedBox(height: AppSpacing.large),
              BookingFiltersBar(
                filters: state.filters,
                onChanged: cubit.updateFilters,
              ),
              const SizedBox(height: AppSpacing.medium),
              BookingBulkActions(
                selectedCount: state.selectedIds.length,
                onApprove: () => cubit.bulkUpdate(BookingStatus.confirmed),
                onReject: () => cubit.bulkUpdate(BookingStatus.cancelled),
                onAssign: cubit.assignSelectedToTrip,
                onClear: cubit.clearSelection,
              ),
              BookingsQueueBoard(
                bookings: state.filteredBookings,
                selectedIds: state.selectedIds,
                onToggleSelected: cubit.toggleSelection,
                onOpen: cubit.openBooking,
                onStatus: cubit.updateStatus,
                onEdit: cubit.openBooking,
              ),
            ],
          ),
        ),
        if (opened != null) ...[
          const SizedBox(width: AppSpacing.medium),
          SizedBox(
            width: 430,
            child: BookingDetailsPanel(
              booking: opened,
              onClose: cubit.closePanel,
              onStatus: (status) => cubit.updateStatus(opened, status),
            ),
          ),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final int total;

  const _Header({required this.total});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.event_seat_outlined, size: 42),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مركز عمليات الحجوزات',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xSmall),
                Text(
                  'قائمة انتظار لخدمة العملاء لمراجعة وتأكيد وإسناد طلبات الحجز.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text('$total طلب'),
        ],
      ),
    );
  }
}
