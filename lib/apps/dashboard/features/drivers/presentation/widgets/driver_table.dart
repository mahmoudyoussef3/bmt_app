import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/empty_state.dart';

import '../../domain/entities/driver.dart';
import '../models/driver_list_query.dart';
import 'driver_avatar.dart';
import 'driver_status_badge.dart';

class DriverTable extends StatelessWidget {
  final List<Driver> drivers;
  final DriverListQuery query;
  final int totalCount;
  final int maxPage;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<DriverStatus?> onStatusChanged;
  final ValueChanged<DriverSortBy> onSortChanged;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<Driver> onView;
  final ValueChanged<Driver> onEdit;
  final void Function(Driver driver, DriverStatus status) onStatusAction;

  const DriverTable({
    required this.drivers,
    required this.query,
    required this.totalCount,
    required this.maxPage,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onSortChanged,
    required this.onPageChanged,
    required this.onView,
    required this.onEdit,
    required this.onStatusAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DriverToolbar(
          query: query,
          onSearchChanged: onSearchChanged,
          onStatusChanged: onStatusChanged,
          onSortChanged: onSortChanged,
        ),
        const SizedBox(height: AppSpacing.medium),
        if (drivers.isEmpty)
          const AppCard(
            child: EmptyState(
              title: 'لا يوجد سائقين',
              subtitle: 'غيّر البحث أو الفلتر لعرض نتائج أخرى.',
            ),
          )
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 1120),
                child: DataTable(
                  columns: [
                    const DataColumn(label: Text('الصورة')),
                    DataColumn(
                      label: const Text('الاسم'),
                      onSort: (_, _) => onSortChanged(DriverSortBy.name),
                    ),
                    const DataColumn(label: Text('رقم الهاتف')),
                    const DataColumn(label: Text('الرقم القومي')),
                    const DataColumn(label: Text('المركبة الحالية')),
                    DataColumn(
                      label: const Text('عدد الرحلات'),
                      numeric: true,
                      onSort: (_, _) => onSortChanged(DriverSortBy.trips),
                    ),
                    DataColumn(
                      label: const Text('التقييم'),
                      numeric: true,
                      onSort: (_, _) => onSortChanged(DriverSortBy.rating),
                    ),
                    DataColumn(
                      label: const Text('الحالة'),
                      onSort: (_, _) => onSortChanged(DriverSortBy.status),
                    ),
                    const DataColumn(label: Text('إجراءات')),
                  ],
                  rows: drivers.map((driver) {
                    return DataRow(
                      cells: [
                        DataCell(DriverAvatar(driver: driver)),
                        DataCell(Text(driver.name)),
                        DataCell(Text(driver.phone)),
                        DataCell(Text(driver.nationalId)),
                        DataCell(Text(driver.currentVehicle)),
                        DataCell(Text('${driver.totalTrips}')),
                        DataCell(Text(driver.rating.toStringAsFixed(1))),
                        DataCell(DriverStatusBadge(status: driver.status)),
                        DataCell(
                          _DriverActions(
                            driver: driver,
                            onView: onView,
                            onEdit: onEdit,
                            onStatusAction: onStatusAction,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.medium),
        _DriverPagination(
          query: query,
          totalCount: totalCount,
          maxPage: maxPage,
          onPageChanged: onPageChanged,
        ),
      ],
    );
  }
}

class _DriverToolbar extends StatelessWidget {
  final DriverListQuery query;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<DriverStatus?> onStatusChanged;
  final ValueChanged<DriverSortBy> onSortChanged;

  const _DriverToolbar({
    required this.query,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Wrap(
        spacing: AppSpacing.medium,
        runSpacing: AppSpacing.medium,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 320,
            child: TextField(
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                labelText: 'بحث',
                prefixIcon: Icon(Icons.search),
                hintText: 'اسم، هاتف، رقم قومي، مركبة',
              ),
              onChanged: onSearchChanged,
            ),
          ),
          SizedBox(
            width: 240,
            child: DropdownButtonFormField<DriverStatus?>(
              initialValue: query.status,
              decoration: const InputDecoration(labelText: 'فلتر الحالة'),
              items: [
                const DropdownMenuItem<DriverStatus?>(
                  value: null,
                  child: Text('كل الحالات'),
                ),
                ...DriverStatus.values.map(
                  (status) => DropdownMenuItem<DriverStatus?>(
                    value: status,
                    child: Text(status.label),
                  ),
                ),
              ],
              onChanged: onStatusChanged,
            ),
          ),
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<DriverSortBy>(
              initialValue: query.sortBy,
              decoration: const InputDecoration(labelText: 'ترتيب حسب'),
              items: DriverSortBy.values
                  .map(
                    (sort) =>
                        DropdownMenuItem(value: sort, child: Text(sort.label)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) onSortChanged(value);
              },
            ),
          ),
          InputChip(
            avatar: Icon(
              query.ascending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 18,
            ),
            label: Text(query.ascending ? 'تصاعدي' : 'تنازلي'),
            onPressed: () => onSortChanged(query.sortBy),
          ),
        ],
      ),
    );
  }
}

class _DriverActions extends StatelessWidget {
  final Driver driver;
  final ValueChanged<Driver> onView;
  final ValueChanged<Driver> onEdit;
  final void Function(Driver driver, DriverStatus status) onStatusAction;

  const _DriverActions({
    required this.driver,
    required this.onView,
    required this.onEdit,
    required this.onStatusAction,
  });

  @override
  Widget build(BuildContext context) {
    final canActivate = driver.status == DriverStatus.suspended;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(onPressed: () => onView(driver), child: const Text('عرض')),
        TextButton(onPressed: () => onEdit(driver), child: const Text('تعديل')),
        TextButton(
          onPressed: () => onStatusAction(
            driver,
            canActivate ? DriverStatus.active : DriverStatus.suspended,
          ),
          child: Text(canActivate ? 'تفعيل' : 'إيقاف'),
        ),
      ],
    );
  }
}

class _DriverPagination extends StatelessWidget {
  final DriverListQuery query;
  final int totalCount;
  final int maxPage;
  final ValueChanged<int> onPageChanged;

  const _DriverPagination({
    required this.query,
    required this.totalCount,
    required this.maxPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final start = totalCount == 0 ? 0 : query.page * query.pageSize + 1;
    final end = (start + query.pageSize - 1).clamp(0, totalCount);

    return Row(
      children: [
        Text('عرض $start - $end من $totalCount'),
        const Spacer(),
        IconButton(
          tooltip: 'السابق',
          onPressed: query.page == 0
              ? null
              : () => onPageChanged(query.page - 1),
          icon: const Icon(Icons.chevron_right),
        ),
        Text('${query.page + 1} / ${maxPage + 1}'),
        IconButton(
          tooltip: 'التالي',
          onPressed: query.page >= maxPage
              ? null
              : () => onPageChanged(query.page + 1),
          icon: const Icon(Icons.chevron_left),
        ),
      ],
    );
  }
}
