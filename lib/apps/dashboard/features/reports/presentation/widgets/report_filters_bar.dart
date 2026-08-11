import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/report_entities.dart';
import '../cubit/reports_cubit.dart';
import '../cubit/reports_state.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';

class ReportFiltersBar extends StatelessWidget {
  final ReportsLoaded state;
  const ReportFiltersBar({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReportsCubit>();
    final filter = state.filter;

    final presetDateLabels = ['اليوم', 'آخر 7 أيام', 'آخر 30 يوم'];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'فلاتر التقرير النشطة',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.medium),
          LayoutBuilder(
            builder: (context, box) {
              final isCompact = box.maxWidth < 750;

              return Column(
                children: [
                  
                  if (isCompact)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.date_range_outlined,
                              size: 20,
                              color: context.status(AppStatusTone.neutral).ink,
                            ),
                            const SizedBox(width: AppSpacing.small),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _pickCustomDateRange(context),
                                child: Text(
                                  'الفترة: ${_formatDate(filter.startDate)} - ${_formatDate(filter.endDate)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.small),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: presetDateLabels.map((preset) {
                            final isSelected = _checkDatePreset(preset, filter);
                            return ChoiceChip(
                              label: Text(
                                preset,
                                style: const TextStyle(fontSize: 11),
                              ),
                              selected: isSelected,
                              onSelected: (sel) {
                                if (sel) {
                                  _applyPresetDate(preset, cubit);
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Icon(
                          Icons.date_range_outlined,
                          size: 20,
                          color: context.status(AppStatusTone.neutral).ink,
                        ),
                        const SizedBox(width: AppSpacing.small),
                        OutlinedButton(
                          onPressed: () => _pickCustomDateRange(context),
                          child: Text(
                            'الفترة: ${_formatDate(filter.startDate)} - ${_formatDate(filter.endDate)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.medium),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: presetDateLabels.map((preset) {
                              final isSelected = _checkDatePreset(
                                preset,
                                filter,
                              );
                              return ChoiceChip(
                                label: Text(
                                  preset,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                selected: isSelected,
                                onSelected: (sel) {
                                  if (sel) {
                                    _applyPresetDate(preset, cubit);
                                  }
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: AppSpacing.small),

                  if (isCompact)
                    Column(children: _buildDropdownFilters(context))
                  else
                    Row(
                      children: _buildDropdownFilters(context)
                          .map(
                            (w) => Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                ),
                                child: w,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDropdownFilters(BuildContext context) {
    final cubit = context.read<ReportsCubit>();
    final filter = state.filter;

    return [
      DropdownButtonFormField<String>(
        initialValue: filter.routeCode,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'المسار',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
        items: [
          const DropdownMenuItem(
            value: null,
            child: Text('الكل (المسار)', overflow: TextOverflow.ellipsis),
          ),
          ...state.availableRoutes.map(
            (r) => DropdownMenuItem(
              value: r,
              child: Text(r, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: (val) =>
            cubit.updateFilter(route: val, clearRoute: val == null),
      ),
      const SizedBox(height: AppSpacing.xSmall),
      DropdownButtonFormField<String>(
        initialValue: filter.driverName,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'السائق',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
        items: [
          const DropdownMenuItem(
            value: null,
            child: Text('الكل (السائق)', overflow: TextOverflow.ellipsis),
          ),
          ...state.availableDrivers.map(
            (d) => DropdownMenuItem(
              value: d,
              child: Text(d, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: (val) =>
            cubit.updateFilter(driver: val, clearDriver: val == null),
      ),
      const SizedBox(height: AppSpacing.xSmall),
      DropdownButtonFormField<String>(
        initialValue: filter.vehiclePlate,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'المركبة',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
        items: [
          const DropdownMenuItem(
            value: null,
            child: Text('الكل (المركبة)', overflow: TextOverflow.ellipsis),
          ),
          ...state.availableVehicles.map(
            (v) => DropdownMenuItem(
              value: v,
              child: Text(v, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: (val) =>
            cubit.updateFilter(vehicle: val, clearVehicle: val == null),
      ),
      const SizedBox(height: AppSpacing.xSmall),
      DropdownButtonFormField<String>(
        initialValue: filter.packageName,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'الاشتراك',
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
        items: [
          const DropdownMenuItem(
            value: null,
            child: Text('الكل (الاشتراك)', overflow: TextOverflow.ellipsis),
          ),
          ...state.availablePackages.map(
            (p) => DropdownMenuItem(
              value: p,
              child: Text(p, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
        onChanged: (val) =>
            cubit.updateFilter(pkg: val, clearPackage: val == null),
      ),
    ];
  }

  bool _checkDatePreset(String preset, ReportFilter filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final filterStart = DateTime(
      filter.startDate.year,
      filter.startDate.month,
      filter.startDate.day,
    );
    final filterEnd = DateTime(
      filter.endDate.year,
      filter.endDate.month,
      filter.endDate.day,
    );

    if (preset == 'اليوم') {
      return filterStart == today && filterEnd == today;
    } else if (preset == 'آخر 7 أيام') {
      final sevenDaysAgo = today.subtract(const Duration(days: 7));
      return filterStart.difference(sevenDaysAgo).inDays.abs() <= 1 &&
          filterEnd.difference(today).inDays.abs() == 0;
    } else if (preset == 'آخر 30 يوم') {
      final thirtyDaysAgo = today.subtract(const Duration(days: 30));
      return filterStart.difference(thirtyDaysAgo).inDays.abs() <= 1 &&
          filterEnd.difference(today).inDays.abs() == 0;
    }
    return false;
  }

  void _applyPresetDate(String preset, ReportsCubit cubit) {
    final now = DateTime.now();
    if (preset == 'اليوم') {
      cubit.updateFilter(start: now, end: now);
    } else if (preset == 'آخر 7 أيام') {
      cubit.updateFilter(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      );
    } else if (preset == 'آخر 30 يوم') {
      cubit.updateFilter(
        start: now.subtract(const Duration(days: 30)),
        end: now,
      );
    }
  }

  Future<void> _pickCustomDateRange(BuildContext context) async {
    final cubit = context.read<ReportsCubit>();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: state.filter.startDate,
        end: state.filter.endDate,
      ),
    );
    if (range != null) {
      cubit.updateFilter(start: range.start, end: range.end);
    }
  }

  String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
