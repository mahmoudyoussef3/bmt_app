import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/ops_data_table.dart';

import '../../domain/entities/operation_booking.dart';
import '../cubit/bookings_cubit.dart';
import '../cubit/bookings_state.dart';
import '../models/booking_queue_tab.dart';
import '../models/booking_sort.dart';
import 'booking_card.dart';
import 'booking_review_intents.dart' as intents;
import 'booking_status_chips.dart';

/// The operator's working list: a sortable, paginated table on desktop widths
/// and a card grid below them, sharing one header strip (result count, select
/// all, ordering) so both layouts behave the same way.
class BookingsQueueBoard extends StatelessWidget {
  const BookingsQueueBoard({super.key, required this.state});

  /// Below this the table's eight columns stop fitting without horizontal
  /// scrolling, and the card layout reads better — which is also the width the
  /// board gets on a 1440px screen once the inspector is open.
  static const double tableBreakpoint = 1040;

  final BookingsLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingsCubit>();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (state.resultCount == 0) {
          return _EmptyBoard(state: state, onClearFilters: cubit.clearFilters);
        }

        final isTable = constraints.maxWidth >= tableBreakpoint;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BoardHeader(state: state, cubit: cubit, showSort: !isTable),
            const SizedBox(height: AppSpacing.small),
            if (isTable)
              _BoardTable(state: state, cubit: cubit)
            else ...[
              _BoardCards(state: state, width: constraints.maxWidth),
              const SizedBox(height: AppSpacing.small),
              _CardsPagination(state: state, onPageChanged: cubit.goToPage),
            ],
          ],
        );
      },
    );
  }
}

/// Result count, select-all and (on card layouts) the sort control.
class _BoardHeader extends StatelessWidget {
  const _BoardHeader({
    required this.state,
    required this.cubit,
    required this.showSort,
  });

  final BookingsLoaded state;
  final BookingsCubit cubit;
  final bool showSort;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final first = state.currentPage * BookingsLoaded.pageSize + 1;
    final last = first + state.pageBookings.length - 1;
    final selectable = state.selectablePageBookings.length;

    return Wrap(
      spacing: AppSpacing.medium,
      runSpacing: AppSpacing.small,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_seat_rounded, size: 18, color: scheme.primary),
            const SizedBox(width: AppSpacing.xSmall),
            Flexible(
              child: Text(
                state.activeTab.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            Flexible(
              child: Text(
                'عرض $first–$last من ${state.resultCount}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectable > 0)
              // Only reviewable rows can be batch-approved, so "select all"
              // advertises exactly how many rows it will take.
              Flexible(
                child: TextButton.icon(
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
              ),
            if (showSort) ...[
              const SizedBox(width: AppSpacing.small),
              Flexible(
                child: _SortControl(state: state, onSort: cubit.sortBy),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Ordering for the card layout, where there are no column headers to tap.
class _SortControl extends StatelessWidget {
  const _SortControl({required this.state, required this.onSort});

  final BookingsLoaded state;
  final ValueChanged<BookingSortField> onSort;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PopupMenuButton<BookingSortField>(
      tooltip: 'ترتيب القائمة',
      position: PopupMenuPosition.under,
      onSelected: onSort,
      itemBuilder: (context) => [
        for (final field in BookingSortField.values)
          PopupMenuItem(
            value: field,
            child: Row(
              children: [
                Icon(
                  state.sortField == field
                      ? (state.sortAscending
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded)
                      : Icons.swap_vert_rounded,
                  size: 16,
                ),
                const SizedBox(width: AppSpacing.small),
                Text(field.label),
              ],
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.small,
          vertical: AppSpacing.xSmall,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_vert_rounded, size: 18),
            const SizedBox(width: AppSpacing.xSmall),
            Flexible(
              child: Text(
                state.sortField.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Icon(
              state.sortAscending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 14,
            ),
          ],
        ),
      ),
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
    // Wide enough for three review buttons plus the details chevron: a tighter
    // actions column is what pushed the whole table into horizontal scroll.
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
    if (!booking.awaitingReview) {
      // A disabled checkbox on every settled row reads as a broken control, so
      // rows that no batch action can touch simply show no control.
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
          maxLines: 1,
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
            maxLines: 1,
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
        if (booking.awaitingReview) ...[
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
          icon: const Icon(Icons.chevron_left_rounded, size: 20),
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
        backgroundColor: style.resolve(context).tint,
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
    // Two columns from tablet up: one column of full-width cards on a 900px
    // board wasted half the row and pushed the list twice as long.
    final columns = width >= 720 ? 2 : 1;
    final cardWidth = columns == 1
        ? width
        : (width - AppSpacing.medium) / columns;

    return Wrap(
      spacing: AppSpacing.medium,
      runSpacing: AppSpacing.medium,
      children: [
        for (final booking in state.pageBookings)
          SizedBox(
            width: cardWidth,
            child: BookingCard(
              booking: booking,
              selected: state.selectedIds.contains(booking.id),
              opened: state.openedBooking?.id == booking.id,
              isProcessing: state.isProcessing,
            ),
          ),
      ],
    );
  }
}

class _CardsPagination extends StatelessWidget {
  const _CardsPagination({required this.state, required this.onPageChanged});

  final BookingsLoaded state;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    if (state.pageCount <= 1) return const SizedBox.shrink();
    final page = state.currentPage;

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      child: Row(
        children: [
          Flexible(
            child: Text(
              'الإجمالي ${state.resultCount}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              'صفحة ${page + 1} من ${state.pageCount}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          IconButton(
            tooltip: 'السابق',
            onPressed: page == 0 ? null : () => onPageChanged(page - 1),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
          IconButton(
            tooltip: 'التالي',
            onPressed: page >= state.pageCount - 1
                ? null
                : () => onPageChanged(page + 1),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
        ],
      ),
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

    return AppCard(
      child: Column(
        children: [
          EmptyState(
            emoji: filtered ? '🔍' : '📭',
            title: filtered
                ? 'لا توجد نتائج مطابقة'
                : switch (state.activeTab) {
                    BookingQueueTab.needsReview =>
                      'لا توجد مدفوعات بانتظار المراجعة',
                    BookingQueueTab.all => 'لا توجد حجوزات بعد',
                    _ => 'لا توجد طلبات في «${state.activeTab.label}»',
                  },
            subtitle: filtered
                ? 'جرّب توسيع نطاق البحث أو امسح الفلاتر لعرض كل طلبات هذا التبويب.'
                : state.activeTab == BookingQueueTab.needsReview
                ? 'كل الإيصالات المرفوعة تمت مراجعتها — لا شيء ينتظر قراراً.'
                : 'ستظهر الطلبات هنا فور وصولها.',
          ),
          if (filtered)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.medium),
              child: FilledButton.tonalIcon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.filter_alt_off_rounded),
                label: const Text('مسح الفلاتر'),
              ),
            ),
        ],
      ),
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
