import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_pager.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_results_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/ops_data_table.dart';

import '../../domain/entities/booking_lifecycle.dart';
import '../../domain/entities/operation_booking.dart';
import '../cubit/bookings_cubit.dart';
import '../cubit/bookings_state.dart';
import '../models/booking_queue_tab.dart';
import '../models/booking_sort.dart';
import 'booking_card.dart';
import 'booking_review_intents.dart' as intents;
import 'booking_status_chips.dart';

/// The operator's working list: the shared results header, a sortable,
/// paginated table on desktop widths and a card grid below them — both fed by
/// the same page index, so both layouts behave the same way.
class BookingsQueueBoard extends StatelessWidget {
  const BookingsQueueBoard({super.key, required this.state});

  final BookingsLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingsCubit>();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (state.resultCount == 0) {
          return _EmptyBoard(state: state, onClearFilters: cubit.clearFilters);
        }

        final isTable = constraints.maxWidth >= kDashboardTableBreakpoint;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BoardHeader(state: state, cubit: cubit),
            const SizedBox(height: AppSpacing.small),
            if (isTable)
              _BoardTable(state: state, cubit: cubit)
            else ...[
              _BoardCards(state: state, width: constraints.maxWidth),
              const SizedBox(height: AppSpacing.small),
              // The same bar the table closes with, so the two layouts page
              // identically.
              AppCard(
                padding: EdgeInsets.zero,
                child: DashboardPagerBar(
                  totalLabel: 'الإجمالي ${state.resultCount} حجز',
                  currentPage: state.currentPage,
                  pages: state.pageCount,
                  onPageChanged: cubit.goToPage,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// The open queue's name, the range in view, and the one control that acts on
/// the whole page: select-all for a bulk review.
///
/// Ordering moved out to the toolbar, where the other two المبيعات modules keep
/// theirs — it used to live here and only on card layouts, so the same list was
/// sortable or not depending on the window width.
class _BoardHeader extends StatelessWidget {
  const _BoardHeader({required this.state, required this.cubit});

  final BookingsLoaded state;
  final BookingsCubit cubit;

  @override
  Widget build(BuildContext context) {
    final first = state.currentPage * BookingsLoaded.pageSize + 1;
    final last = first + state.pageBookings.length - 1;
    final selectable = state.selectablePageBookings.length;

    return DashboardResultsHeader(
      icon: Icons.event_seat_rounded,
      title: state.activeTab.label,
      subtitle: 'عرض $first–$last من ${state.resultCount}',
      actions: [
        if (selectable > 0)
          TextButton.icon(
            onPressed: cubit.toggleSelectAllOnPage,
            icon: Icon(
              state.allPageSelected
                  ? Icons.check_box_rounded
                  : Icons.check_box_outline_blank_rounded,
              size: 18,
            ),
            label: Text(
              state.allPageSelected
                  ? 'إلغاء تحديد الصفحة'
                  : 'تحديد $selectable للمراجعة',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

class _BoardTable extends StatelessWidget {
  const _BoardTable({required this.state, required this.cubit});

  final BookingsLoaded state;
  final BookingsCubit cubit;

  /// Column order mirrors the question order an operator works through: which
  /// request, whose, for what trip, for how much, and where it stands.
  static const _columns = <OpsColumn>[
    OpsColumn('', flex: 1, minWidth: 44),
    OpsColumn('الحجز', flex: 3, minWidth: 120, sortable: true),
    OpsColumn('العميل', flex: 4, minWidth: 150, sortable: true),
    OpsColumn('الرحلة', flex: 5, minWidth: 190, sortable: true),
    OpsColumn('المبلغ', flex: 3, minWidth: 105, numeric: true, sortable: true),
    OpsColumn('حالة الحجز', flex: 3, minWidth: 110),
    OpsColumn('حالة الدفع', flex: 3, minWidth: 120),

    OpsColumn('إجراءات', flex: 3, minWidth: 170),
  ];

  /// Table column index → the field it sorts by. Columns without an entry are
  /// not sortable, which is what keeps the header arrows honest.
  static const _sortFields = <int, BookingSortField>{
    1: BookingSortField.createdAt,
    2: BookingSortField.passenger,
    3: BookingSortField.route,
    4: BookingSortField.amount,
  };

  @override
  Widget build(BuildContext context) {
    final sortIndex = _sortFields.entries
        .where((entry) => entry.value == state.sortField)
        .map((entry) => entry.key)
        .firstOrNull;

    return OpsDataTable(
      columns: _columns,
      total: state.resultCount,
      totalLabel: 'الإجمالي ${state.resultCount} حجز',
      currentPage: state.currentPage,
      pageSize: BookingsLoaded.pageSize,
      onPageChanged: cubit.goToPage,
      sortColumnIndex: sortIndex,
      sortDirection: state.sortAscending ? OpsSort.asc : OpsSort.desc,
      onSort: (index) {
        final field = _sortFields[index];
        if (field != null) cubit.sortBy(field);
      },
      rows: [
        for (final booking in state.pageBookings)
          _row(context, booking: booking),
      ],
    );
  }

  List<Widget> _row(BuildContext context, {required OperationBooking booking}) {
    final opened = state.openedBooking?.id == booking.id;
    return [
      _SelectCell(
        booking: booking,
        selected: state.selectedIds.contains(booking.id),
        enabled: !state.isProcessing,
        onChanged: () => cubit.toggleSelection(booking.id),
      ),
      _StackedCell(
        primary: booking.bookingNumber.isEmpty ? '—' : booking.bookingNumber,
        secondary: bookingRelativeTime(booking.createdAt),
        emphasised: opened,
        onTap: () => cubit.openBooking(booking),
      ),
      _StackedCell(
        primary: booking.passengerName,
        secondary: booking.phone.isEmpty ? null : booking.phone,
        onTap: () => cubit.openBooking(booking),
      ),
      _StackedCell(
        primary: booking.route.isEmpty ? '—' : booking.route,
        secondary: [
          if (booking.date.isNotEmpty) booking.date,
          if (booking.tripTime.isNotEmpty) booking.tripTime,
          if (booking.seat.isNotEmpty) 'مقعد ${booking.seat}',
        ].join(' · '),
        onTap: () => cubit.openBooking(booking),
      ),
      _AmountCell(booking: booking),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: BookingStateChip.booking(booking.status, dense: true),
      ),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: BookingStateChip.payment(booking.paymentStatus, dense: true),
      ),
      _RowActions(
        booking: booking,
        cubit: cubit,
        isProcessing: state.isProcessing,
      ),
    ];
  }
}

class _SelectCell extends StatelessWidget {
  const _SelectCell({
    required this.booking,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final OperationBooking booking;
  final bool selected;
  final bool enabled;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    // Not `awaitingReview`: a cancelled booking with a submitted receipt is a
    // row the payment RPCs refuse, so it is never selectable for a bulk review.
    if (!booking.canReviewPayment) {
      return const SizedBox.shrink();
    }
    return Tooltip(
      message: 'تحديد للمراجعة الجماعية',
      child: Checkbox(
        value: selected,
        onChanged: enabled ? (_) => onChanged() : null,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

/// Two lines of related text in one cell — the pattern that let the table drop
/// from twelve thin columns to eight readable ones.
class _StackedCell extends StatelessWidget {
  const _StackedCell({
    required this.primary,
    this.secondary,
    this.emphasised = false,
    this.onTap,
  });

  final String primary;
  final String? secondary;
  final bool emphasised;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          primary,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: text.bodyMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: emphasised ? scheme.primary : null,
          ),
        ),
        if (secondary != null && secondary!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            secondary!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ],
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      child: content,
    );
  }
}

class _AmountCell extends StatelessWidget {
  const _AmountCell({required this.booking});

  final OperationBooking booking;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          booking.amountLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          booking.paymentMethod.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _RowActions extends StatelessWidget {
  const _RowActions({
    required this.booking,
    required this.cubit,
    required this.isProcessing,
  });

  final OperationBooking booking;
  final BookingsCubit cubit;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (booking.canReviewPayment) ...[
          _ActionIcon(
            icon: Icons.check_rounded,
            tooltip: 'قبول الدفع',
            style: paymentStatusStyle(PaymentStatus.approved),
            onPressed: isProcessing
                ? null
                : () => intents.approveBooking(context, cubit, booking),
          ),
          _ActionIcon(
            icon: Icons.close_rounded,
            tooltip: 'رفض الدفع',
            style: paymentStatusStyle(PaymentStatus.rejected),
            onPressed: isProcessing
                ? null
                : () => intents.rejectBooking(context, cubit, booking),
          ),
          _ActionIcon(
            icon: Icons.refresh_rounded,
            tooltip: 'طلب إعادة رفع الإيصال',
            style: paymentStatusStyle(PaymentStatus.submitted),
            onPressed: isProcessing
                ? null
                : () => intents.requestReupload(context, cubit, booking),
          ),
        ],
        IconButton(
          icon: const Icon(DashboardIcons.forward, size: 20),
          tooltip: 'عرض التفاصيل',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          onPressed: () => cubit.openBooking(booking),
        ),
      ],
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.tooltip,
    required this.style,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final BookingStatusStyle style;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      style: IconButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: style.resolve(context).ink,
        padding: EdgeInsets.zero,
        minimumSize: const Size(32, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
    );
  }
}

class _BoardCards extends StatelessWidget {
  const _BoardCards({required this.state, required this.width});

  final BookingsLoaded state;
  final double width;

  @override
  Widget build(BuildContext context) {
    final columns = dashboardCardColumnsFor(width);
    final rows = <List<OperationBooking>>[
      for (var i = 0; i < state.pageBookings.length; i += columns)
        state.pageBookings.skip(i).take(columns).toList(),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, row) in rows.indexed) ...[
          if (index > 0) const SizedBox(height: AppSpacing.medium),
          // A `Wrap` let each card size to its own content, so two side-by-side
          // cards ended at different heights and the grid read as ragged. One
          // `IntrinsicHeight` row per pair squares them off; the cost is bounded
          // because a page is twelve cards.
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (position, booking) in row.indexed) ...[
                  if (position > 0) const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: BookingCard(
                      booking: booking,
                      selected: state.selectedIds.contains(booking.id),
                      opened: state.openedBooking?.id == booking.id,
                      isProcessing: state.isProcessing,
                    ),
                  ),
                ],
                // Keeps a lone card on the final row at one column's width
                // instead of letting it stretch across both.
                for (var i = row.length; i < columns; i++) ...[
                  const SizedBox(width: AppSpacing.medium),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Distinguishes "this queue is genuinely empty" from "your filters hid
/// everything" — the second is recoverable, and says so.
class _EmptyBoard extends StatelessWidget {
  const _EmptyBoard({required this.state, required this.onClearFilters});

  final BookingsLoaded state;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final filtered = state.filters.isActive;

    return DashboardEmptyState(
      icon: filtered ? Icons.search_off_rounded : DashboardIcons.bookings,
      title: filtered
          ? 'لا توجد نتائج مطابقة'
          : switch (state.activeTab) {
              BookingQueueTab.needsReview => 'لا توجد مدفوعات بانتظار المراجعة',
              BookingQueueTab.all => 'لا توجد حجوزات بعد',
              _ => 'لا توجد طلبات في «${state.activeTab.label}»',
            },
      message: filtered
          ? 'جرّب توسيع نطاق البحث أو امسح الفلاتر لعرض كل طلبات هذا التبويب.'
          : state.activeTab == BookingQueueTab.needsReview
          ? 'كل الإيصالات المرفوعة تمت مراجعتها — لا شيء ينتظر قراراً.'
          : 'ستظهر الطلبات هنا فور وصولها.',
      action: filtered
          ? FilledButton.tonalIcon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.filter_alt_off_rounded),
              label: const Text('مسح الفلاتر'),
            )
          : null,
    );
  }
}

/// "منذ ٣ ساعات" in ASCII digits, so age reads at a glance without a second
/// full timestamp column.
String bookingRelativeTime(DateTime createdAt) {
  final diff = DateTime.now().difference(createdAt);
  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
  if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
  if (diff.inDays < 30) return 'منذ ${diff.inDays} يوم';
  return 'منذ ${(diff.inDays / 30).floor()} شهر';
}
