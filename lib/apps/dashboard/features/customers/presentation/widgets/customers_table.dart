import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/ops_data_table.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/avatar.dart';

import '../../domain/entities/customer.dart';
import '../../domain/entities/customer_filters.dart';
import '../cubit/customers_state.dart';
import 'customers_format.dart';

/// The customer directory.
///
/// ## Sorting is a choice of key, not a direction
///
/// Each sort key has one sensible direction — newest activity first, most
/// bookings first, soonest trip first, names A→Z — and the server applies it.
/// Letting the header toggle to "the customer who has spent least" would be a
/// control nobody uses standing in front of one everybody does.
class CustomersTable extends StatelessWidget {
  const CustomersTable({
    super.key,
    required this.state,
    required this.now,
    required this.onOpen,
    required this.onPageChanged,
    required this.onSort,
    required this.onClearFilters,
  });

  final CustomersLoadedState state;

  /// Injected rather than read from the clock, so "منذ ساعتين" is stable within
  /// one build and a test can assert on it.
  final DateTime now;

  final ValueChanged<CustomerSummary> onOpen;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<CustomerSort> onSort;
  final VoidCallback onClearFilters;

  /// Column index → sort key. Columns absent from this map are not sortable.
  static const _sortByColumn = <int, CustomerSort>{
    0: CustomerSort.name,
    3: CustomerSort.upcoming,
    4: CustomerSort.recent,
    5: CustomerSort.bookings,
    6: CustomerSort.paid,
  };

  @override
  Widget build(BuildContext context) {
    final rows = state.page.rows;

    if (rows.isEmpty) {
      return AppCard(child: _emptyState(context));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Seven columns need roughly this much before the cells start truncating
        // into uselessness; below it the same rows read better stacked.
        if (constraints.maxWidth < 1100) {
          return _CustomerCardList(
            rows: rows,
            now: now,
            onOpen: onOpen,
            state: state,
            onPageChanged: onPageChanged,
          );
        }
        return _table(context, rows);
      },
    );
  }

  Widget _table(BuildContext context, List<CustomerSummary> rows) {
    final sortIndex = _sortByColumn.entries
        .where((entry) => entry.value == state.filters.sort)
        .map((entry) => entry.key)
        .firstOrNull;

    return OpsDataTable(
      columns: const [
        OpsColumn('العميل', flex: 3, minWidth: 200, sortable: true),
        OpsColumn('الحالة', minWidth: 96),
        OpsColumn('الاشتراك', flex: 2, minWidth: 150),
        OpsColumn('الرحلة القادمة', minWidth: 120, sortable: true),
        OpsColumn('آخر نشاط', minWidth: 120, sortable: true),
        OpsColumn('الحجوزات', minWidth: 100, numeric: true, sortable: true),
        OpsColumn('المدفوع', minWidth: 120, numeric: true, sortable: true),
        OpsColumn('', minWidth: 96),
      ],
      rows: [for (final customer in rows) _cells(context, customer)],
      onRowTap: [for (final customer in rows) () => onOpen(customer)],
      total: state.page.total,
      currentPage: state.pageIndex,
      pageSize: customersPageSize,
      onPageChanged: onPageChanged,
      sortColumnIndex: sortIndex,
      // Always ascending as a marker: the arrow says "sorted by this", and the
      // key's own direction is what the label promises.
      sortDirection: sortIndex == null ? OpsSort.none : OpsSort.asc,
      onSort: (index) {
        final sort = _sortByColumn[index];
        if (sort != null) onSort(sort);
      },
    );
  }

  List<Widget> _cells(BuildContext context, CustomerSummary customer) {
    final palette = Theme.of(context).colorScheme;
    return [
      _Identity(customer: customer),
      _StatusPill(
        label: CustomersFormat.clientStatus(customer.status),
        tone: customer.status == 'active'
            ? palette.primary
            : DashboardColors.mutedInk(context),
      ),
      _SubscriptionCell(customer: customer),
      Text(
        CustomersFormat.relativeDay(customer.nextTripDate, now),
        style: TextStyle(
          fontWeight: customer.hasUpcomingTrip
              ? FontWeight.w700
              : FontWeight.w400,
          color: customer.hasUpcomingTrip
              ? DashboardColors.ink(context)
              : DashboardColors.mutedInk(context),
        ),
      ),
      Text(
        CustomersFormat.age(customer.lastActivityAt, now),
        style: TextStyle(color: DashboardColors.mutedInk(context)),
      ),
      _BookingsCell(customer: customer),
      Text(
        CustomersFormat.money(customer.totalPaid),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      Align(
        alignment: AlignmentDirectional.centerEnd,
        child: TextButton(
          onPressed: () => onOpen(customer),
          child: const Text('فتح الملف'),
        ),
      ),
    ];
  }

  Widget _emptyState(BuildContext context) {
    if (state.isFilteredEmpty) {
      return DashboardEmptyState(
        icon: Icons.search_off_rounded,
        title: 'لم نجد عملاء مطابقين للبحث',
        message: 'جرّب تعديل الكلمات أو إزالة بعض عوامل التصفية.',
        action: TextButton.icon(
          onPressed: onClearFilters,
          icon: const Icon(Icons.filter_alt_off_outlined),
          label: const Text('مسح التصفية'),
        ),
      );
    }
    return const DashboardEmptyState(
      icon: DashboardIcons.customers,
      title: 'لا يوجد عملاء حتى الآن',
      // Says what would put data here, rather than only that there is none.
      message:
          'يظهر العميل هنا بعد أول حجز أو اشتراك مع المكتب — لا يُنشأ العملاء من هذه الشاشة.',
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.customer});

  final CustomerSummary customer;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppAvatar(initials: customer.initials, radius: 16),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                customer.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                customer.phone,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: DashboardColors.mutedInk(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SubscriptionCell extends StatelessWidget {
  const _SubscriptionCell({required this.customer});

  final CustomerSummary customer;

  @override
  Widget build(BuildContext context) {
    final name = customer.activePackageName;
    if (name == null) {
      return Text(
        'بدون اشتراك',
        style: TextStyle(color: DashboardColors.faintInk(context)),
      );
    }

    final used = customer.activePackageTripsUsed;
    final total = customer.activePackageTripsCount;
    // A package with no ride allowance cannot report "3 من 0"; the name alone
    // is the honest answer.
    final detail = (total != null && total > 0 && used != null)
        ? '$used من $total رحلة'
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        if (detail != null)
          Text(
            detail,
            style: TextStyle(
              fontSize: 12,
              color: DashboardColors.mutedInk(context),
            ),
          ),
      ],
    );
  }
}

class _BookingsCell extends StatelessWidget {
  const _BookingsCell({required this.customer});

  final CustomerSummary customer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          CustomersFormat.count(customer.bookingsTotal),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        if (customer.bookingsCancelled > 0)
          Text(
            'ملغاة: ${customer.bookingsCancelled}',
            style: TextStyle(
              fontSize: 12,
              color: DashboardColors.mutedInk(context),
            ),
          ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.tone});

  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: tone.withAlpha(28),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: tone,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

/// Below the table's breakpoint the same rows render as cards, because seven
/// truncated columns answer none of the questions the operator opened this
/// screen with.
class _CustomerCardList extends StatelessWidget {
  const _CustomerCardList({
    required this.rows,
    required this.now,
    required this.onOpen,
    required this.state,
    required this.onPageChanged,
  });

  final List<CustomerSummary> rows;
  final DateTime now;
  final ValueChanged<CustomerSummary> onOpen;
  final CustomersLoadedState state;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final customer in rows) ...[
          _CustomerCard(customer: customer, now: now, onOpen: onOpen),
          const SizedBox(height: AppSpacing.small),
        ],
        _CardPager(
          pageIndex: state.pageIndex,
          pageCount: state.pageCount,
          total: state.page.total,
          onPageChanged: onPageChanged,
        ),
      ],
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.customer,
    required this.now,
    required this.onOpen,
  });

  final CustomerSummary customer;
  final DateTime now;
  final ValueChanged<CustomerSummary> onOpen;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: InkWell(
        onTap: () => onOpen(customer),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppAvatar(initials: customer.initials, radius: 18),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        customer.phone,
                        style: TextStyle(
                          fontSize: 12,
                          color: DashboardColors.mutedInk(context),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => onOpen(customer),
                  child: const Text('فتح الملف'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            Wrap(
              spacing: AppSpacing.medium,
              runSpacing: AppSpacing.xSmall,
              children: [
                _Fact(
                  label: 'الحجوزات',
                  value: CustomersFormat.count(customer.bookingsTotal),
                ),
                _Fact(
                  label: 'المدفوع',
                  value: CustomersFormat.money(customer.totalPaid),
                ),
                _Fact(
                  label: 'الرحلة القادمة',
                  value: CustomersFormat.relativeDay(
                    customer.nextTripDate,
                    now,
                  ),
                ),
                _Fact(
                  label: 'آخر نشاط',
                  value: CustomersFormat.age(customer.lastActivityAt, now),
                ),
                _Fact(
                  label: 'الاشتراك',
                  value: customer.activePackageName ?? 'بدون اشتراك',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: DashboardColors.mutedInk(context),
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// The card list has no `OpsDataTable` to carry a pager, so it carries its own —
/// the same numbers, so the two layouts page identically.
class _CardPager extends StatelessWidget {
  const _CardPager({
    required this.pageIndex,
    required this.pageCount,
    required this.total,
    required this.onPageChanged,
  });

  /// Zero-based, like `OpsDataTable.currentPage`, so both layouts speak the
  /// same page numbers to the cubit.
  final int pageIndex;
  final int pageCount;
  final int total;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$total عميل',
            style: TextStyle(color: DashboardColors.mutedInk(context)),
          ),
          Row(
            children: [
              IconButton(
                tooltip: 'السابق',
                icon: const Icon(DashboardIcons.paginationPrevious),
                onPressed: pageIndex > 0
                    ? () => onPageChanged(pageIndex - 1)
                    : null,
              ),
              Text('${pageIndex + 1} / $pageCount'),
              IconButton(
                tooltip: 'التالي',
                icon: const Icon(DashboardIcons.paginationNext),
                onPressed: pageIndex < pageCount - 1
                    ? () => onPageChanged(pageIndex + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
