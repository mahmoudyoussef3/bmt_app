import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../domain/entities/operation_booking.dart';
import '../cubit/bookings_cubit.dart';
import '../cubit/bookings_state.dart';
import '../widgets/booking_action_dialogs.dart';
import '../widgets/booking_bulk_actions.dart';
import '../widgets/booking_details_panel.dart';
import '../widgets/booking_filters_bar.dart';

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
              _Header(total: state.bookings.length),
              const SizedBox(height: AppSpacing.large),
              _SummaryCards(state: state),
              const SizedBox(height: AppSpacing.large),
              _StatusTabs(state: state),
              const SizedBox(height: AppSpacing.medium),
              BookingFiltersBar(
                filters: state.filters,
                onChanged: cubit.updateFilters,
              ),
              const SizedBox(height: AppSpacing.medium),
              BookingBulkActions(
                selectedCount: state.selectedIds.length,
                onApprove: () => cubit.bulkUpdate(BookingStatus.approved),
                onReject: () => cubit.bulkUpdate(BookingStatus.rejected),
                onAssign: cubit.assignSelectedToTrip,
                onClear: cubit.clearSelection,
              ),
              _BookingsTable(state: state),
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
          Icon(Icons.event_seat_outlined, size: 42, color: scheme.primary),
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
          Text(
            '$total طلب',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final BookingsLoaded state;

  const _SummaryCards({required this.state});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'طلبات جديدة',
        state.countByStatus(BookingStatus.newRequest),
        Icons.fiber_new_rounded,
        Colors.blue,
      ),
      (
        'تنتظر المراجعة',
        state.countByStatus(BookingStatus.underReview) +
            state.countByStatus(BookingStatus.paymentUploaded),
        Icons.hourglass_top_rounded,
        Colors.orange,
      ),
      (
        'مقبولة',
        state.countByStatus(BookingStatus.approved),
        Icons.check_circle_outline,
        Colors.green,
      ),
      (
        'مرفوضة',
        state.countByStatus(BookingStatus.rejected),
        Icons.cancel_outlined,
        Colors.red,
      ),
      (
        'مؤكدة',
        state.countByStatus(BookingStatus.confirmed),
        Icons.verified_outlined,
        Colors.teal,
      ),
      (
        'ملغاة',
        state.countByStatus(BookingStatus.cancelled),
        Icons.block_outlined,
        Colors.grey,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 6
            : constraints.maxWidth >= 700
                ? 3
                : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.medium,
            mainAxisSpacing: AppSpacing.medium,
            mainAxisExtent: 92,
          ),
          itemBuilder: (context, index) {
            final (label, count, icon, color) = items[index];
            return AppCard(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    '$count',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatusTabs extends StatelessWidget {
  final BookingsLoaded state;

  const _StatusTabs({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingsCubit>();
    final tabs = BookingStatus.values;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((status) {
          final selected = state.activeTab == status;
          final count = state.countByStatus(status);
          return Padding(
            padding: const EdgeInsets.only(left: AppSpacing.small),
            child: selected
                ? FilledButton(
                    onPressed: () => cubit.switchTab(status),
                    child: Text('${status.label} ($count)'),
                  )
                : OutlinedButton(
                    onPressed: () => cubit.switchTab(status),
                    child: Text('${status.label} ($count)'),
                  ),
          );
        }).toList(),
      ),
    );
  }
}

class _BookingsTable extends StatelessWidget {
  final BookingsLoaded state;

  const _BookingsTable({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<BookingsCubit>();
    final bookings = state.filteredBookings;

    const headers = [
      'رقم الحجز',
      'العميل',
      'المسار',
      'المبلغ',
      'طريقة الدفع',
      'الأولوية',
      'الحالة',
      'التاريخ',
      'إجراءات',
    ];

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: Row(
              children: [
                Text(
                  'قائمة ${state.activeTab.label}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '${bookings.length} طلب',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 1380,
              child: Column(
                children: [
                  Container(
                    color: scheme.surfaceContainerHighest.withAlpha(90),
                    padding: const EdgeInsets.all(AppSpacing.small),
                    child: Row(
                      children: [
                        const SizedBox(width: 40),
                        ...headers.map(
                          (h) => Expanded(
                            child: Text(
                              h,
                              style:
                                  Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (bookings.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.large),
                      child: Text(
                        'لا توجد طلبات في هذه الحالة',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    )
                  else
                    ...bookings.map((booking) {
                      final selected =
                          state.openedBooking?.id == booking.id;
                      final isChecked =
                          state.selectedIds.contains(booking.id);
                      return InkWell(
                        onTap: () => cubit.openBooking(booking),
                        child: Container(
                          padding:
                              const EdgeInsets.all(AppSpacing.small),
                          decoration: BoxDecoration(
                            color: selected
                                ? scheme.primary.withAlpha(18)
                                : Colors.transparent,
                            border: Border(
                              top: BorderSide(
                                color: scheme.outline.withAlpha(90),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 40,
                                child: Checkbox(
                                  value: isChecked,
                                  onChanged: (_) =>
                                      cubit.toggleSelection(
                                          booking.id),
                                ),
                              ),
                              Expanded(child: Text(booking.id)),
                              Expanded(
                                child: Text(
                                  booking.passengerName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  booking.route,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                    booking.paymentDetails.amount),
                              ),
                              Expanded(
                                child: Text(
                                    booking.paymentMethod.label),
                              ),
                              Expanded(
                                child: _PriorityBadge(
                                    priority: booking.priority),
                              ),
                              Expanded(
                                child: StatusChip(
                                    label: booking.status.label),
                              ),
                              Expanded(child: Text(booking.date)),
                              Expanded(
                                child: _RowActions(
                                  booking: booking,
                                  cubit: cubit,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final BookingPriority priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (priority) {
      BookingPriority.normal => (Colors.grey, Colors.grey.withAlpha(20)),
      BookingPriority.urgent => (Colors.orange, Colors.orange.withAlpha(20)),
      BookingPriority.vip => (Colors.amber.shade800, Colors.amber.withAlpha(20)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Text(
        priority.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _RowActions extends StatelessWidget {
  final OperationBooking booking;
  final BookingsCubit cubit;

  const _RowActions({required this.booking, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final canReview = booking.status == BookingStatus.underReview ||
        booking.status == BookingStatus.paymentUploaded;
    return Wrap(
      spacing: 4,
      children: [
        if (canReview) ...[
          IconButton(
            icon: const Icon(Icons.check_rounded, size: 18),
            tooltip: 'قبول',
            color: Colors.green,
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => BookingApprovalDialog(
                bookingId: booking.id,
                passengerName: booking.passengerName,
                onApprove: (note) => cubit.approveBooking(booking.id, note),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            tooltip: 'رفض',
            color: Colors.red,
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => BookingRejectionDialog(
                bookingId: booking.id,
                passengerName: booking.passengerName,
                onReject: (reason, note) =>
                    cubit.rejectBooking(booking.id, reason, note),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 18),
            tooltip: 'طلب إعادة رفع',
            color: Colors.orange,
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => BookingReuploadDialog(
                bookingId: booking.id,
                passengerName: booking.passengerName,
                onRequest: (reason) =>
                    cubit.requestReupload(booking.id, reason),
              ),
            ),
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
