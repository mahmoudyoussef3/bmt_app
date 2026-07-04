import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/empty_state.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_table_frame.dart';

import '../../domain/entities/operation_booking.dart';
import '../cubit/bookings_cubit.dart';
import '../cubit/bookings_state.dart';
import '../models/booking_filters.dart';
import '../widgets/bookings_analytics.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocBuilder<BookingsCubit, BookingsState>(
        builder: (context, state) {
          return switch (state) {
            BookingsLoading() => const _BookingsLoadingView(),
            BookingsError(:final message) => _BookingsErrorView(
              message: message,
            ),
            BookingsLoaded() => _BookingsLoadedView(state: state),
          };
        },
      ),
    );
  }
}

class _BookingsLoadedView extends StatelessWidget {
  const _BookingsLoadedView({required this.state});

  final BookingsLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingsCubit>();
    final opened = state.openedBooking;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1180;
        final isCompact = constraints.maxWidth < 760;

        final content = CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.all(
                isCompact ? AppSpacing.medium : AppSpacing.large,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  _Header(total: state.bookings.length),
                  const SizedBox(height: AppSpacing.medium),
                  _SummaryCards(state: state),
                  const SizedBox(height: AppSpacing.medium),
                  BookingsAnalytics(bookings: state.bookings),
                  const SizedBox(height: AppSpacing.medium),
                  _BookingsToolbar(state: state),
                  const SizedBox(height: AppSpacing.medium),
                  _BookingBulkActions(
                    selectedCount: state.selectedIds.length,
                    onApprove: () => cubit.bulkUpdate(BookingStatus.confirmed),
                    onReject: () => cubit.bulkUpdate(BookingStatus.cancelled),
                    onAssign: cubit.assignSelectedToTrip,
                    onClear: cubit.clearSelection,
                  ),
                  _BookingsListArea(state: state),
                ]),
              ),
            ),
          ],
        );

        if (!isWide) {
          return Stack(
            children: [
              content,
              if (opened != null)
                _DetailsBottomSheetOverlay(
                  booking: opened,
                  onClose: cubit.closePanel,
                  onStatus: (status) => cubit.updateStatus(opened, status),
                ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: content),
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              width: opened == null ? 0 : 440,
              child: opened == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        0,
                        AppSpacing.large,
                        AppSpacing.large,
                        AppSpacing.large,
                      ),
                      child: _BookingDetailsPanel(
                        booking: opened,
                        onClose: cubit.closePanel,
                        onStatus: (status) =>
                            cubit.updateStatus(opened, status),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return DashboardModuleHeader(
      icon: Icons.event_seat_rounded,
      title: 'مركز عمليات الحجوزات',
      subtitle: 'راجع الطلبات، تحقق من الدفع، وافتح تفاصيل الحجز من مكان واحد.',
      actions: [StatusChip(label: '$total طلب')],
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.state});

  final BookingsLoaded state;

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryItem(
        'مسودة',
        state.countByStatus(BookingStatus.draft),
        Icons.fiber_new_rounded,
        AppStatusColors.onInfoContainer,
      ),
      _SummaryItem(
        'مراجعة الدفع',
        state.countByPaymentStatus(PaymentStatus.underReview) +
            state.countByPaymentStatus(PaymentStatus.submitted),
        Icons.hourglass_top_rounded,
        AppStatusColors.onWarningContainer,
      ),
      _SummaryItem(
        'محجوزة',
        state.countByStatus(BookingStatus.reserved),
        Icons.book_online_outlined,
        AppStatusColors.onSuccessContainer,
      ),
      _SummaryItem(
        'مؤكدة',
        state.countByStatus(BookingStatus.confirmed),
        Icons.verified_outlined,
        AppStatusColors.onSpecialContainer,
      ),
      _SummaryItem(
        'مرفوضة الدفع',
        state.countByPaymentStatus(PaymentStatus.rejected),
        Icons.cancel_outlined,
        AppStatusColors.onErrorContainer,
      ),
      _SummaryItem(
        'ملغاة',
        state.countByStatus(BookingStatus.cancelled),
        Icons.block_outlined,
        AppStatusColors.onNeutralContainer,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1200
            ? 6
            : constraints.maxWidth >= 860
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
            mainAxisExtent: 96,
          ),
          itemBuilder: (context, index) => _SummaryCard(item: items[index]),
        );
      },
    );
  }
}

class _SummaryItem {
  const _SummaryItem(this.label, this.count, this.icon, this.color);

  final String label;
  final int count;
  final IconData icon;
  final Color color;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.item});

  final _SummaryItem item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.color.withAlpha(22),
              borderRadius: BorderRadius.circular(AppTokens.radius),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            '${item.count}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: item.color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingsToolbar extends StatelessWidget {
  const _BookingsToolbar({required this.state});

  final BookingsLoaded state;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusTabs(state: state),
          const SizedBox(height: AppSpacing.medium),
          _BookingFiltersBar(
            filters: state.filters,
            onChanged: context.read<BookingsCubit>().updateFilters,
          ),
        ],
      ),
    );
  }
}

class _StatusTabs extends StatelessWidget {
  const _StatusTabs({required this.state});

  final BookingsLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingsCubit>();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: BookingStatus.values.map((status) {
          final selected = state.activeTab == status;
          final count = state.countByStatus(status);

          return Padding(
            padding: const EdgeInsetsDirectional.only(end: AppSpacing.small),
            child: selected
                ? FilledButton(
                    onPressed: () => cubit.switchTab(status),
                    child: Text('${status.label}  $count'),
                  )
                : OutlinedButton(
                    onPressed: () => cubit.switchTab(status),
                    child: Text('${status.label}  $count'),
                  ),
          );
        }).toList(),
      ),
    );
  }
}

class _BookingFiltersBar extends StatelessWidget {
  const _BookingFiltersBar({required this.filters, required this.onChanged});

  final BookingFilters filters;
  final ValueChanged<BookingFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final full = constraints.maxWidth;
        final compact = full < 720;

        return Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          children: [
            SizedBox(
              width: compact ? full : 280,
              child: TextField(
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'بحث سريع',
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'اسم، هاتف، رقم حجز',
                ),
                onChanged: (value) =>
                    onChanged(filters.copyWith(search: value)),
              ),
            ),
            SizedBox(
              width: compact ? full : 220,
              child: TextField(
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'المسار',
                  prefixIcon: Icon(Icons.route_rounded),
                ),
                onChanged: (value) => onChanged(filters.copyWith(route: value)),
              ),
            ),
            SizedBox(
              width: compact ? full : 170,
              child: TextField(
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'التاريخ',
                  prefixIcon: Icon(Icons.calendar_today_rounded),
                ),
                onChanged: (value) => onChanged(filters.copyWith(date: value)),
              ),
            ),
            SizedBox(
              width: compact ? full : 190,
              child: DropdownButtonFormField<BookingPaymentMethod?>(
                initialValue: filters.paymentMethod,
                decoration: const InputDecoration(labelText: 'طريقة الدفع'),
                items: [
                  const DropdownMenuItem<BookingPaymentMethod?>(
                    value: null,
                    child: Text('كل الطرق'),
                  ),
                  ...BookingPaymentMethod.values.map(
                    (method) => DropdownMenuItem(
                      value: method,
                      child: Text(method.label),
                    ),
                  ),
                ],
                onChanged: (value) => onChanged(
                  filters.copyWith(
                    paymentMethod: value,
                    clearPaymentMethod: value == null,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: compact ? full : 160,
              child: DropdownButtonFormField<BookingPriority?>(
                initialValue: filters.priority,
                decoration: const InputDecoration(labelText: 'الأولوية'),
                items: [
                  const DropdownMenuItem<BookingPriority?>(
                    value: null,
                    child: Text('الكل'),
                  ),
                  ...BookingPriority.values.map(
                    (priority) => DropdownMenuItem(
                      value: priority,
                      child: Text(priority.label),
                    ),
                  ),
                ],
                onChanged: (value) => onChanged(
                  filters.copyWith(
                    priority: value,
                    clearPriority: value == null,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BookingBulkActions extends StatelessWidget {
  const _BookingBulkActions({
    required this.selectedCount,
    required this.onApprove,
    required this.onReject,
    required this.onAssign,
    required this.onClear,
  });

  final int selectedCount;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final ValueChanged<String> onAssign;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (selectedCount == 0) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.medium),
        decoration: BoxDecoration(
          color: scheme.primary.withAlpha(16),
          borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
          border: Border.all(color: scheme.primary.withAlpha(55)),
        ),
        child: Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '$selectedCount طلب محدد',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: scheme.primary,
              ),
            ),
            FilledButton.icon(
              onPressed: onApprove,
              icon: const Icon(Icons.check_rounded),
              label: const Text('اعتماد'),
            ),
            OutlinedButton.icon(
              onPressed: onReject,
              icon: const Icon(Icons.close_rounded),
              label: const Text('رفض'),
            ),
            OutlinedButton.icon(
              onPressed: () => _openAssignDialog(context),
              icon: const Icon(Icons.alt_route_rounded),
              label: const Text('إسناد لرحلة'),
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
        textDirection: TextDirection.ltr,
        child: AlertDialog(
          title: const Text('إسناد الطلبات إلى رحلة'),
          content: const Text(
            'اختر الرحلة المناسبة من قائمة الرحلات الفعلية عند ربط هذه الشاشة بالرحلات.',
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

class _BookingsListArea extends StatelessWidget {
  const _BookingsListArea({required this.state});

  final BookingsLoaded state;

  @override
  Widget build(BuildContext context) {
    final bookings = state.filteredBookings;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (bookings.isEmpty) {
          return AppCard(
            child: const EmptyState(
              title: 'لا توجد طلبات',
              subtitle: 'لا توجد حجوزات مطابقة للفلاتر الحالية.',
            ),
          );
        }

        if (constraints.maxWidth < 900) {
          return _BookingsCardsList(state: state);
        }

        return _BookingsTable(state: state);
      },
    );
  }
}

class _BookingsCardsList extends StatelessWidget {
  const _BookingsCardsList({required this.state});

  final BookingsLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookingsCubit>();

    return Column(
      children: state.filteredBookings.map((booking) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.medium),
          child: _BookingCard(
            booking: booking,
            selected: state.selectedIds.contains(booking.id),
            opened: state.openedBooking?.id == booking.id,
            onToggleSelected: () => cubit.toggleSelection(booking.id),
            onOpen: () => cubit.openBooking(booking),
            onApprove: () => _openApprovalDialog(context, booking, cubit),
            onReject: () => _openRejectionDialog(context, booking, cubit),
            onReupload: () => _openReuploadDialog(context, booking, cubit),
          ),
        );
      }).toList(),
    );
  }
}

class _BookingsTable extends StatelessWidget {
  const _BookingsTable({required this.state});

  final BookingsLoaded state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<BookingsCubit>();
    final bookings = state.filteredBookings;

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
              DataColumn(label: Text('الأولوية')),
              DataColumn(label: Text('الحالة')),
              DataColumn(label: Text('التاريخ')),
              DataColumn(label: Text('إجراءات')),
            ],
            rows: bookings.map((booking) {
              final selected = state.openedBooking?.id == booking.id;
              final checked = state.selectedIds.contains(booking.id);

              return DataRow(
                selected: selected,
                onSelectChanged: (_) => cubit.openBooking(booking),
                cells: [
                  DataCell(
                    Checkbox(
                      value: checked,
                      onChanged: (_) => cubit.toggleSelection(booking.id),
                    ),
                  ),
                  DataCell(Text(booking.id)),
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
                  DataCell(Text(booking.paymentDetails.amount)),
                  DataCell(Text(booking.paymentMethod.label)),
                  DataCell(_PriorityBadge(priority: booking.priority)),
                  DataCell(StatusChip(label: '${booking.status.label} / ${booking.paymentStatus.label}')),
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

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.selected,
    required this.opened,
    required this.onToggleSelected,
    required this.onOpen,
    required this.onApprove,
    required this.onReject,
    required this.onReupload,
  });

  final OperationBooking booking;
  final bool selected;
  final bool opened;
  final VoidCallback onToggleSelected;
  final VoidCallback onOpen;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onReupload;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canReview =
        booking.paymentStatus == PaymentStatus.underReview ||
        booking.paymentStatus == PaymentStatus.submitted;

    return AppCard(
      onTap: onOpen,
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: opened ? scheme.primary.withAlpha(120) : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        ),
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(value: selected, onChanged: (_) => onToggleSelected()),
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
                StatusChip(label: '${booking.status.label} / ${booking.paymentStatus.label}'),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            _MiniInfo(label: 'رقم الحجز', value: booking.id),
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
                _PriorityBadge(priority: booking.priority),
                const Spacer(),
                Text(
                  booking.paymentDetails.amount,
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
                if (canReview) ...[
                  FilledButton.tonalIcon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('قبول'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('رفض'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onReupload,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('إعادة رفع'),
                  ),
                ],
                TextButton.icon(
                  onPressed: onOpen,
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
              value,
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

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final BookingPriority priority;

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (priority) {
      BookingPriority.normal => (
        AppStatusColors.onNeutralContainer,
        AppStatusColors.neutralContainer,
      ),
      BookingPriority.urgent => (
        AppStatusColors.onWarningContainer,
        AppStatusColors.warningContainer,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Text(
        priority.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
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
    final canReview =
        booking.paymentStatus == PaymentStatus.underReview ||
        booking.paymentStatus == PaymentStatus.submitted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canReview) ...[
          IconButton(
            icon: const Icon(Icons.check_rounded, size: 18),
            tooltip: 'قبول',
            color: AppStatusColors.onSuccessContainer,
            onPressed: () => _openApprovalDialog(context, booking, cubit),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            tooltip: 'رفض',
            color: AppStatusColors.onErrorContainer,
            onPressed: () => _openRejectionDialog(context, booking, cubit),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 18),
            tooltip: 'طلب إعادة رفع',
            color: AppStatusColors.onWarningContainer,
            onPressed: () => _openReuploadDialog(context, booking, cubit),
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

class _BookingDetailsPanel extends StatelessWidget {
  const _BookingDetailsPanel({
    required this.booking,
    required this.onClose,
    required this.onStatus,
  });

  final OperationBooking booking;
  final VoidCallback onClose;
  final void Function(BookingStatus status) onStatus;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: scheme.primary.withAlpha(20),
                  child: Icon(Icons.person_outline, color: scheme.primary),
                ),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.passengerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        booking.phone,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.medium),
              children: [
                Wrap(
                  spacing: AppSpacing.small,
                  runSpacing: AppSpacing.small,
                  children: [
                    StatusChip(label: booking.status.label),
                    StatusChip(
                      label: booking.paymentStatus.label,
                      color: AppStatusColors.onWarningContainer,
                    ),
                    StatusChip(
                      label: booking.priority.label,
                      color: _priorityColor(booking.priority, scheme),
                    ),
                    PopupMenuButton<BookingStatus>(
                      tooltip: 'تحديث الحالة',
                      onSelected: onStatus,
                      itemBuilder: (context) => BookingStatus.values
                          .map(
                            (status) => PopupMenuItem(
                              value: status,
                              child: Text(status.label),
                            ),
                          )
                          .toList(),
                      child: Chip(
                        avatar: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('تغيير الحالة'),
                        side: BorderSide(color: scheme.outline.withAlpha(55)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.medium),
                _DetailsSection(
                  title: 'بيانات العميل',
                  icon: Icons.person_rounded,
                  rows: [
                    ('الاسم', booking.customerProfile.name),
                    ('الهاتف', booking.customerProfile.phone),
                    ('البريد', booking.customerProfile.email),
                    ('عدد الرحلات', booking.customerProfile.tripsCount),
                    ('حالة الحساب', booking.customerProfile.accountStatus),
                  ],
                ),
                _DetailsSection(
                  title: 'تفاصيل الرحلة',
                  icon: Icons.route_rounded,
                  rows: [
                    ('المسار', booking.tripDetails.route),
                    ('التاريخ', booking.tripDetails.date),
                    ('الوقت', booking.tripDetails.time),
                    ('المركبة', booking.tripDetails.vehicle),
                    ('السائق', booking.tripDetails.driver),
                    ('الرحلة المسندة', booking.assignedTrip),
                  ],
                ),
                _DetailsSection(
                  title: 'بيانات الدفع',
                  icon: Icons.payments_rounded,
                  rows: [
                    ('المبلغ', booking.paymentDetails.amount),
                    ('الطريقة', booking.paymentDetails.method.label),
                    ('الحالة', booking.paymentDetails.status),
                    ('المرجع', booking.paymentDetails.reference),
                    if (booking.paymentDetails.receiptReference != null)
                      ('رقم الإيصال', booking.paymentDetails.receiptReference!),
                  ],
                ),
                if (booking.rejectionReason != null)
                  _DetailsSection(
                    title: 'سبب الرفض',
                    icon: Icons.warning_rounded,
                    rows: [('السبب', booking.rejectionReason!)],
                  ),
                if (booking.reviewerName != null)
                  _DetailsSection(
                    title: 'المراجع',
                    icon: Icons.verified_user_rounded,
                    rows: [('اسم المراجع', booking.reviewerName!)],
                  ),
                _ListSection(title: 'المرفقات', items: booking.attachments),
                _ListSection(title: 'ملاحظات', items: booking.notes),
                _TimelineSection(events: booking.timeline),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _priorityColor(BookingPriority priority, ColorScheme scheme) {
    return switch (priority) {
      BookingPriority.normal => scheme.surfaceContainerHighest,
      BookingPriority.urgent => AppStatusColors.warningContainer,
    };
  }
}

class _DetailsBottomSheetOverlay extends StatelessWidget {
  const _DetailsBottomSheetOverlay({
    required this.booking,
    required this.onClose,
    required this.onStatus,
  });

  final OperationBooking booking;
  final VoidCallback onClose;
  final void Function(BookingStatus status) onStatus;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withAlpha(65),
        child: Align(
          alignment: AlignmentDirectional.bottomCenter,
          child: FractionallySizedBox(
            heightFactor: 0.88,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: _BookingDetailsPanel(
                booking: booking,
                onClose: onClose,
                onStatus: onStatus,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({
    required this.title,
    required this.icon,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: scheme.primary),
                const SizedBox(width: AppSpacing.xSmall),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.small),
                child: Row(
                  children: [
                    SizedBox(
                      width: 105,
                      child: Text(
                        row.$1,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.$2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListSection extends StatelessWidget {
  const _ListSection({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.small),
            if (items.isEmpty)
              Text(
                'لا توجد عناصر.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...items.map(
                (item) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.circle_outlined, size: 14),
                  title: Text(item),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  const _TimelineSection({required this.events});

  final List<BookingTimelineEvent> events;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'سجل العمليات',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.medium),
            if (events.isEmpty)
              Text(
                'لا يوجد سجل.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              )
            else
              ...events.map(
                (event) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.small),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: scheme.primary,
                            ),
                          ),
                          if (event != events.last)
                            Container(
                              width: 2,
                              height: 34,
                              color: scheme.outline.withAlpha(60),
                            ),
                        ],
                      ),
                      const SizedBox(width: AppSpacing.small),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.action,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '${event.actor} • ${_formatTime(event.timestamp)}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                            if (event.note != null)
                              Text(
                                event.note!,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: scheme.onSurfaceVariant),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final month = time.month.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }
}

class _BookingsLoadingView extends StatelessWidget {
  const _BookingsLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _BookingsErrorView extends StatelessWidget {
  const _BookingsErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Theme.of(context).colorScheme.error,
              size: 42,
            ),
            const SizedBox(height: AppSpacing.small),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

void _openApprovalDialog(
  BuildContext context,
  OperationBooking booking,
  BookingsCubit cubit,
) {
  showDialog<void>(
    context: context,
    builder: (_) => _BookingApprovalDialog(
      bookingId: booking.id,
      passengerName: booking.passengerName,
      onApprove: (note) => cubit.approveBooking(booking.id, note),
    ),
  );
}

void _openRejectionDialog(
  BuildContext context,
  OperationBooking booking,
  BookingsCubit cubit,
) {
  showDialog<void>(
    context: context,
    builder: (_) => _BookingRejectionDialog(
      bookingId: booking.id,
      passengerName: booking.passengerName,
      onReject: (reason, note) => cubit.rejectBooking(booking.id, reason, note),
    ),
  );
}

void _openReuploadDialog(
  BuildContext context,
  OperationBooking booking,
  BookingsCubit cubit,
) {
  showDialog<void>(
    context: context,
    builder: (_) => _BookingReuploadDialog(
      bookingId: booking.id,
      passengerName: booking.passengerName,
      onRequest: (reason) => cubit.requestReupload(booking.id, reason),
    ),
  );
}

class _BookingApprovalDialog extends StatefulWidget {
  const _BookingApprovalDialog({
    required this.bookingId,
    required this.passengerName,
    required this.onApprove,
  });

  final String bookingId;
  final String passengerName;
  final void Function(String? note) onApprove;

  @override
  State<_BookingApprovalDialog> createState() => _BookingApprovalDialogState();
}

class _BookingApprovalDialogState extends State<_BookingApprovalDialog> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ActionDialogShell(
      title: 'تأكيد قبول الدفع',
      icon: Icons.check_circle_outline,
      color: AppStatusColors.onSuccessContainer,
      message:
          'سيتم قبول دفع ${widget.passengerName} وتأكيد الحجز ${widget.bookingId}.',
      content: TextField(
        controller: _note,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'ملاحظة اختيارية',
          hintText: 'أضف ملاحظة للعميل أو للسجل...',
        ),
      ),
      confirmLabel: 'قبول الدفع',
      onConfirm: () {
        widget.onApprove(_note.text.trim().isEmpty ? null : _note.text.trim());
        Navigator.of(context).pop();
      },
    );
  }
}

class _BookingRejectionDialog extends StatefulWidget {
  const _BookingRejectionDialog({
    required this.bookingId,
    required this.passengerName,
    required this.onReject,
  });

  final String bookingId;
  final String passengerName;
  final void Function(String reason, String? note) onReject;

  @override
  State<_BookingRejectionDialog> createState() =>
      _BookingRejectionDialogState();
}

class _BookingRejectionDialogState extends State<_BookingRejectionDialog> {
  String? _selectedReason;
  final _note = TextEditingController();
  String _error = '';

  static const _reasons = [
    'الإيصال غير واضح',
    'المبلغ غير مطابق',
    'إيصال منتهي الصلاحية',
    'رقم المرجع غير صحيح',
    'صورة مقطوعة أو ناقصة',
    'إيصال مكرر',
    'سبب آخر',
  ];

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ActionDialogShell(
      title: 'رفض الدفع',
      icon: Icons.warning_amber_rounded,
      color: Theme.of(context).colorScheme.error,
      message:
          'سيتم رفض دفع ${widget.passengerName} للحجز ${widget.bookingId}.',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedReason,
            decoration: const InputDecoration(labelText: 'سبب الرفض *'),
            items: _reasons
                .map(
                  (reason) =>
                      DropdownMenuItem(value: reason, child: Text(reason)),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedReason = value;
                _error = '';
              });
            },
          ),
          const SizedBox(height: AppSpacing.medium),
          TextField(
            controller: _note,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'ملاحظة إضافية',
              hintText: 'تفاصيل إضافية عن سبب الرفض...',
            ),
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.small),
            Text(
              _error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      confirmLabel: 'رفض',
      onConfirm: () {
        if (_selectedReason == null) {
          setState(() => _error = 'يجب اختيار سبب الرفض');
          return;
        }

        widget.onReject(
          _selectedReason!,
          _note.text.trim().isEmpty ? null : _note.text.trim(),
        );
        Navigator.of(context).pop();
      },
    );
  }
}

class _BookingReuploadDialog extends StatefulWidget {
  const _BookingReuploadDialog({
    required this.bookingId,
    required this.passengerName,
    required this.onRequest,
  });

  final String bookingId;
  final String passengerName;
  final void Function(String reason) onRequest;

  @override
  State<_BookingReuploadDialog> createState() => _BookingReuploadDialogState();
}

class _BookingReuploadDialogState extends State<_BookingReuploadDialog> {
  String? _selectedReason;
  String _error = '';

  static const _reasons = [
    'الصورة غير واضحة',
    'الإيصال مقطوع',
    'التاريخ غير ظاهر',
    'المبلغ غير ظاهر',
    'يجب رفع إيصال بصيغة صحيحة',
    'سبب آخر',
  ];

  @override
  Widget build(BuildContext context) {
    return _ActionDialogShell(
      title: 'طلب إعادة رفع الإيصال',
      icon: Icons.refresh_rounded,
      color: AppStatusColors.onWarningContainer,
      message: 'سيُطلب من ${widget.passengerName} إعادة رفع إيصال الدفع.',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedReason,
            decoration: const InputDecoration(labelText: 'السبب *'),
            items: _reasons
                .map(
                  (reason) =>
                      DropdownMenuItem(value: reason, child: Text(reason)),
                )
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedReason = value;
                _error = '';
              });
            },
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.small),
            Text(
              _error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      confirmLabel: 'طلب إعادة رفع',
      onConfirm: () {
        if (_selectedReason == null) {
          setState(() => _error = 'يجب اختيار السبب');
          return;
        }

        widget.onRequest(_selectedReason!);
        Navigator.of(context).pop();
      },
    );
  }
}

class _ActionDialogShell extends StatelessWidget {
  const _ActionDialogShell({
    required this.title,
    required this.icon,
    required this.color,
    required this.message,
    required this.content,
    required this.confirmLabel,
    required this.onConfirm,
  });

  final String title;
  final IconData icon;
  final Color color;
  final String message;
  final Widget content;
  final String confirmLabel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.medium),
                decoration: BoxDecoration(
                  color: color.withAlpha(16),
                  borderRadius: BorderRadius.circular(AppTokens.radius),
                  border: Border.all(color: color.withAlpha(60)),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 28),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(child: Text(message)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              content,
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: Text(
              'إلغاء',
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
          FilledButton(onPressed: onConfirm, child: Text(confirmLabel)),
        ],
      ),
    );
  }
}
