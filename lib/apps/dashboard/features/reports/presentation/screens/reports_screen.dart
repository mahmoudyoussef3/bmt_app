import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/empty_state.dart';

import '../../domain/entities/report_entities.dart';
import '../cubit/reports_cubit.dart';
import '../cubit/reports_state.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ReportsCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مركز التقارير التنفيذية والتحليلات'),
          elevation: 0,
          actions: [
            IconButton(
              tooltip: 'تحديث البيانات',
              onPressed: () => context.read<ReportsCubit>().load(),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: BlocConsumer<ReportsCubit, ReportsState>(
          listener: (context, state) {
            if (state is ReportsLoaded && state.exportingFormat != null) {
              _showExportDialog(context, state);
            }
          },
          builder: (context, state) {
            return switch (state) {
              ReportsLoading() => const Center(child: CircularProgressIndicator()),
              ReportsError(:final message) => _ErrorView(message: message),
              ReportsLoaded() => _LoadedView(state: state),
            };
          },
        ),
      ),
    );
  }

  void _showExportDialog(BuildContext context, ReportsLoaded state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.download_for_offline, color: Colors.blue),
            SizedBox(width: AppSpacing.small),
            Text('معاينة وتحميل التقرير المصدّر'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('تم توليد التقرير بنجاح وهو جاهز للتحميل الآن:'),
            const SizedBox(height: AppSpacing.medium),
            Container(
              padding: const EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('اسم الملف: ${state.exportedFileName ?? ""}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('تنسيق الملف: ${state.exportingFormat?.toUpperCase() ?? ""}', style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  const Text('حالة التوليد: جاهز (محاكاة)', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<ReportsCubit>().clearExport();
            },
            child: const Text('إغلاق'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<ReportsCubit>().clearExport();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم تنزيل الملف ${state.exportedFileName ?? ""} بنجاح (محاكاة)'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('تحميل الملف الآن'),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.read<ReportsCubit>().load(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  final ReportsLoaded state;
  const _LoadedView({required this.state});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useSplit = constraints.maxWidth > 950;

        if (useSplit) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sidebar Selector
              SizedBox(
                width: 240,
                child: _ReportSidebarSelector(
                  selectedType: state.activeReportType,
                  onSelect: (type) => context.read<ReportsCubit>().switchReportType(type),
                ),
              ),
              const VerticalDivider(width: 1),
              // Main Workspace
              Expanded(
                child: _ReportWorkspace(state: state),
              ),
            ],
          );
        }

        // Compact Layout (Sidebar becomes a dropdown menu at the top)
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium, vertical: AppSpacing.small),
              child: AppCard(
                child: Row(
                  children: [
                    const Text('نوع التقرير النشط:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: DropdownButton<ReportType>(
                        value: state.activeReportType,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: ReportType.values.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Text(t.label),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            context.read<ReportsCubit>().switchReportType(val);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: _ReportWorkspace(state: state)),
          ],
        );
      },
    );
  }
}

// -------------------------------------------------------------
// SIDEBAR SELECTOR
// -------------------------------------------------------------
class _ReportSidebarSelector extends StatelessWidget {
  final ReportType selectedType;
  final ValueChanged<ReportType> onSelect;

  const _ReportSidebarSelector({
    required this.selectedType,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final icons = {
      ReportType.trips: Icons.directions_bus_outlined,
      ReportType.bookings: Icons.book_online_outlined,
      ReportType.revenue: Icons.monetization_on_outlined,
      ReportType.drivers: Icons.badge_outlined,
      ReportType.vehicles: Icons.local_shipping_outlined,
      ReportType.subscriptions: Icons.workspace_premium_outlined,
      ReportType.complaints: Icons.support_agent_outlined,
    };

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('فئات التقارير', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
          const SizedBox(height: AppSpacing.medium),
          Expanded(
            child: ListView.separated(
              itemCount: ReportType.values.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.xSmall),
              itemBuilder: (context, index) {
                final type = ReportType.values[index];
                final isSelected = type == selectedType;
                return Material(
                  color: isSelected ? scheme.primaryContainer.withAlpha(120) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: ListTile(
                    selected: isSelected,
                    onTap: () => onSelect(type),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    leading: Icon(icons[type] ?? Icons.insert_chart_outlined, size: 20),
                    title: Text(
                      type.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// REPORT WORKSPACE
// -------------------------------------------------------------
class _ReportWorkspace extends StatelessWidget {
  final ReportsLoaded state;
  const _ReportWorkspace({required this.state});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.medium),
      children: [
        // 1. Top Filters Bar
        _ReportFiltersBar(state: state),
        const SizedBox(height: AppSpacing.medium),

        // 2. Export toolbar
        _ExportToolbar(state: state),
        const SizedBox(height: AppSpacing.medium),

        // 3. KPI Summaries
        _ReportKpiGrid(state: state),
        const SizedBox(height: AppSpacing.medium),

        // 4. Trend Chart
        _ReportTrendChart(state: state),
        const SizedBox(height: AppSpacing.medium),

        // 5. Data Grid Table
        _ReportDataTable(state: state),
      ],
    );
  }
}

// -------------------------------------------------------------
// FILTERS BAR WIDGET
// -------------------------------------------------------------
class _ReportFiltersBar extends StatelessWidget {
  final ReportsLoaded state;
  const _ReportFiltersBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReportsCubit>();
    final filter = state.filter;

    final presetDateLabels = ['اليوم', 'آخر 7 أيام', 'آخر 30 يوم'];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('فلاتر التقرير النشطة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: AppSpacing.medium),
          LayoutBuilder(
            builder: (context, box) {
              final isCompact = box.maxWidth < 750;

              return Column(
                children: [
                  // Row 1: Dates range
                  Row(
                    children: [
                      const Icon(Icons.date_range_outlined, size: 20, color: Colors.grey),
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
                      const SizedBox(width: AppSpacing.small),
                      Wrap(
                        spacing: 4,
                        children: presetDateLabels.map((preset) {
                          final isSelected = _checkDatePreset(preset, filter);
                          return ChoiceChip(
                            label: Text(preset, style: const TextStyle(fontSize: 10)),
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
                  ),
                  const SizedBox(height: AppSpacing.small),

                  // Row 2: Select drop-down selectors
                  if (isCompact)
                    Column(
                      children: _buildDropdownFilters(context),
                    )
                  else
                    Row(
                      children: _buildDropdownFilters(context)
                          .map((w) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0), child: w)))
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
        decoration: const InputDecoration(labelText: 'المسار', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
        items: [
          const DropdownMenuItem(value: null, child: Text('الكل (المسار)')),
          ...state.availableRoutes.map((r) => DropdownMenuItem(value: r, child: Text(r))),
        ],
        onChanged: (val) => cubit.updateFilter(route: val, clearRoute: val == null),
      ),
      const SizedBox(height: AppSpacing.xSmall),
      DropdownButtonFormField<String>(
        initialValue: filter.driverName,
        decoration: const InputDecoration(labelText: 'السائق', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
        items: [
          const DropdownMenuItem(value: null, child: Text('الكل (السائق)')),
          ...state.availableDrivers.map((d) => DropdownMenuItem(value: d, child: Text(d))),
        ],
        onChanged: (val) => cubit.updateFilter(driver: val, clearDriver: val == null),
      ),
      const SizedBox(height: AppSpacing.xSmall),
      DropdownButtonFormField<String>(
        initialValue: filter.vehiclePlate,
        decoration: const InputDecoration(labelText: 'المركبة', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
        items: [
          const DropdownMenuItem(value: null, child: Text('الكل (المركبة)')),
          ...state.availableVehicles.map((v) => DropdownMenuItem(value: v, child: Text(v))),
        ],
        onChanged: (val) => cubit.updateFilter(vehicle: val, clearVehicle: val == null),
      ),
      const SizedBox(height: AppSpacing.xSmall),
      DropdownButtonFormField<String>(
        initialValue: filter.packageName,
        decoration: const InputDecoration(labelText: 'الاشتراك', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
        items: [
          const DropdownMenuItem(value: null, child: Text('الكل (الاشتراك)')),
          ...state.availablePackages.map((p) => DropdownMenuItem(value: p, child: Text(p))),
        ],
        onChanged: (val) => cubit.updateFilter(pkg: val, clearPackage: val == null),
      ),
    ];
  }

  bool _checkDatePreset(String preset, ReportFilter filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final filterStart = DateTime(filter.startDate.year, filter.startDate.month, filter.startDate.day);
    final filterEnd = DateTime(filter.endDate.year, filter.endDate.month, filter.endDate.day);

    if (preset == 'اليوم') {
      return filterStart == today && filterEnd == today;
    } else if (preset == 'آخر 7 أيام') {
      final sevenDaysAgo = today.subtract(const Duration(days: 7));
      return filterStart.difference(sevenDaysAgo).inDays.abs() <= 1 && filterEnd.difference(today).inDays.abs() == 0;
    } else if (preset == 'آخر 30 يوم') {
      final thirtyDaysAgo = today.subtract(const Duration(days: 30));
      return filterStart.difference(thirtyDaysAgo).inDays.abs() <= 1 && filterEnd.difference(today).inDays.abs() == 0;
    }
    return false;
  }

  void _applyPresetDate(String preset, ReportsCubit cubit) {
    final now = DateTime.now();
    if (preset == 'اليوم') {
      cubit.updateFilter(start: now, end: now);
    } else if (preset == 'آخر 7 أيام') {
      cubit.updateFilter(start: now.subtract(const Duration(days: 7)), end: now);
    } else if (preset == 'آخر 30 يوم') {
      cubit.updateFilter(start: now.subtract(const Duration(days: 30)), end: now);
    }
  }

  Future<void> _pickCustomDateRange(BuildContext context) async {
    final cubit = context.read<ReportsCubit>();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: state.filter.startDate, end: state.filter.endDate),
    );
    if (range != null) {
      cubit.updateFilter(start: range.start, end: range.end);
    }
  }

  String _formatDate(DateTime dt) => '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

// -------------------------------------------------------------
// EXPORT TOOLBAR
// -------------------------------------------------------------
class _ExportToolbar extends StatelessWidget {
  final ReportsLoaded state;
  const _ExportToolbar({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReportsCubit>();

    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.ios_share, color: Colors.blue),
          const SizedBox(width: AppSpacing.small),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('تصدير التقرير التنفيذي', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('توليد وتنزيل نسخ التقارير بتنسيقات مختلفة لحفظها ومشاركتها.', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          if (state.actionLoading)
            const CircularProgressIndicator()
          else ...[
            OutlinedButton.icon(
              onPressed: () => cubit.triggerExport('pdf'),
              icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
              label: const Text('PDF'),
            ),
            const SizedBox(width: AppSpacing.small),
            OutlinedButton.icon(
              onPressed: () => cubit.triggerExport('excel'),
              icon: const Icon(Icons.grid_on, color: Colors.green),
              label: const Text('Excel'),
            ),
            const SizedBox(width: AppSpacing.small),
            OutlinedButton.icon(
              onPressed: () => cubit.triggerExport('csv'),
              icon: const Icon(Icons.description, color: Colors.orange),
              label: const Text('CSV'),
            ),
          ],
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// REPORT KPI GRID
// -------------------------------------------------------------
class _ReportKpiGrid extends StatelessWidget {
  final ReportsLoaded state;
  const _ReportKpiGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    final kpis = state.reportData.kpis;
    final keys = kpis.keys.toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final double spacing = AppSpacing.small;
        final int columns = constraints.maxWidth < 650 ? 2 : 4;

        if (columns == 2) {
          return Column(
            children: [
              Row(
                children: [
                  if (keys.isNotEmpty) Expanded(child: _KpiCard(label: keys[0], value: kpis[keys[0]]!, color: Colors.blue)),
                  SizedBox(width: spacing),
                  if (keys.length > 1) Expanded(child: _KpiCard(label: keys[1], value: kpis[keys[1]]!, color: Colors.orange)),
                ],
              ),
              SizedBox(height: spacing),
              Row(
                children: [
                  if (keys.length > 2) Expanded(child: _KpiCard(label: keys[2], value: kpis[keys[2]]!, color: Colors.green)),
                  SizedBox(width: spacing),
                  if (keys.length > 3) Expanded(child: _KpiCard(label: keys[3], value: kpis[keys[3]]!, color: Colors.purple)),
                ],
              ),
            ],
          );
        }

        return Row(
          children: List.generate(keys.length, (index) {
            final key = keys[index];
            final color = [Colors.blue, Colors.orange, Colors.green, Colors.purple][index % 4];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: index == 0 ? 0 : spacing / 2),
                child: _KpiCard(label: key, value: kpis[key]!, color: color),
              ),
            );
          }),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withAlpha(isDark ? 40 : 25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// TRENDS CHART
// -------------------------------------------------------------
class _ReportTrendChart extends StatelessWidget {
  final ReportsLoaded state;
  const _ReportTrendChart({required this.state});

  @override
  Widget build(BuildContext context) {
    final trends = state.reportData.trends;
    final scheme = Theme.of(context).colorScheme;

    if (trends.isEmpty) {
      return const SizedBox();
    }

    final double maxVal = trends.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final double maxCeiling = maxVal == 0 ? 1000 : ((maxVal / 50).ceil() * 50).toDouble();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('رسم بياني توضيحي للاتجاهات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: AppSpacing.large),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Y-Axis labels
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(4, (index) {
                    final double val = maxCeiling * (3 - index) / 3;
                    return Text(
                      val.toStringAsFixed(0),
                      style: const TextStyle(fontSize: 8, color: Colors.grey),
                    );
                  }),
                ),
                const SizedBox(width: AppSpacing.small),

                // Chart Bars
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, box) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: trends.map((e) {
                          final double barPct = maxCeiling == 0 ? 0.0 : e.value / maxCeiling;
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                e.value.toStringAsFixed(0),
                                style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: scheme.primary),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                width: 18,
                                height: (box.maxHeight - 30) * barPct,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [scheme.primary, scheme.primary.withAlpha(120)],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    topRight: Radius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                e.key.length > 6 ? e.key.substring(0, 6) : e.key,
                                style: const TextStyle(fontSize: 8, color: Colors.grey),
                              ),
                            ],
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// DETAILED DATA TABLES
// -------------------------------------------------------------
class _ReportDataTable extends StatelessWidget {
  final ReportsLoaded state;
  const _ReportDataTable({required this.state});

  @override
  Widget build(BuildContext context) {
    final rows = state.reportData.rows;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('سجل البيانات المفصلة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text('عدد السجلات: ${rows.length}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          if (rows.isEmpty)
            const EmptyState(
              title: 'لا توجد سجلات بيانات لتحديد الفلتر الحالي',
              subtitle: 'يرجى تجربة تعديل فترة التصفية الزمنية أو خيارات الفلترة.',
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _buildTable(context),
            ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rows = state.reportData.rows;

    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: scheme.outlineVariant.withAlpha(50),
      ),
      child: switch (state.activeReportType) {
        ReportType.trips => DataTable(
            columns: const [
              DataColumn(label: Text('كود الرحلة')),
              DataColumn(label: Text('المسار')),
              DataColumn(label: Text('السائق')),
              DataColumn(label: Text('المركبة')),
              DataColumn(label: Text('الركاب')),
              DataColumn(label: Text('نسبة الإشغال')),
              DataColumn(label: Text('الإيرادات')),
              DataColumn(label: Text('التاريخ')),
              DataColumn(label: Text('الحالة')),
            ],
            rows: rows.cast<TripReportRow>().take(50).map((r) {
              return DataRow(cells: [
                DataCell(Text(r.tripId, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(r.routeCode)),
                DataCell(Text(r.driverName)),
                DataCell(Text(r.vehiclePlate)),
                DataCell(Text('${r.passengerCount} راكب')),
                DataCell(Text('${(r.occupancyRate * 100).toStringAsFixed(0)}%')),
                DataCell(Text('${r.revenue.toStringAsFixed(0)} ج.م')),
                DataCell(Text(r.date.toString().substring(0, 10))),
                DataCell(Text(r.status, style: TextStyle(color: r.status == 'مكتملة' ? Colors.green : Colors.red, fontWeight: FontWeight.bold))),
              ]);
            }).toList(),
          ),
        ReportType.bookings => DataTable(
            columns: const [
              DataColumn(label: Text('رقم الحجز')),
              DataColumn(label: Text('العميل')),
              DataColumn(label: Text('كود الرحلة')),
              DataColumn(label: Text('المبلغ')),
              DataColumn(label: Text('طريقة الدفع')),
              DataColumn(label: Text('الحالة')),
              DataColumn(label: Text('التاريخ')),
            ],
            rows: rows.cast<BookingReportRow>().take(50).map((r) {
              return DataRow(cells: [
                DataCell(Text(r.bookingId, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(r.clientName)),
                DataCell(Text(r.tripId)),
                DataCell(Text('${r.amount.toStringAsFixed(0)} ج.م')),
                DataCell(Text(r.paymentMethod)),
                DataCell(Text(r.status, style: TextStyle(color: r.status == 'مؤكدة' ? Colors.green : Colors.red, fontWeight: FontWeight.bold))),
                DataCell(Text(r.date.toString().substring(0, 16))),
              ]);
            }).toList(),
          ),
        ReportType.revenue => DataTable(
            columns: const [
              DataColumn(label: Text('التاريخ')),
              DataColumn(label: Text('إجمالي الإيرادات')),
              DataColumn(label: Text('إيرادات الرحلات')),
              DataColumn(label: Text('إيرادات الاشتراكات')),
              DataColumn(label: Text('عدد المرتجعات')),
              DataColumn(label: Text('صافي الإيرادات')),
            ],
            rows: rows.cast<RevenueReportRow>().take(50).map((r) {
              return DataRow(cells: [
                DataCell(Text(r.date.toString().substring(0, 10), style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text('${r.totalRevenue.toStringAsFixed(0)} ج.م')),
                DataCell(Text('${r.bookingsRevenue.toStringAsFixed(0)} ج.م')),
                DataCell(Text('${r.subscriptionsRevenue.toStringAsFixed(0)} ج.م')),
                DataCell(Text('${r.refundsCount} عمليات')),
                DataCell(Text('${r.netRevenue.toStringAsFixed(0)} ج.م', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
              ]);
            }).toList(),
          ),
        ReportType.drivers => DataTable(
            columns: const [
              DataColumn(label: Text('رقم السائق')),
              DataColumn(label: Text('الاسم')),
              DataColumn(label: Text('الرحلات المكتملة')),
              DataColumn(label: Text('ساعات العمل')),
              DataColumn(label: Text('التقييم')),
              DataColumn(label: Text('إيرادات محققة')),
              DataColumn(label: Text('الحالة')),
            ],
            rows: rows.cast<DriverReportRow>().take(50).map((r) {
              return DataRow(cells: [
                DataCell(Text(r.driverId, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(r.name)),
                DataCell(Text('${r.completedTrips} رحلة')),
                DataCell(Text('${r.totalWorkingHours.toStringAsFixed(0)} ساعة')),
                DataCell(Text('${r.rating.toStringAsFixed(1)} ★', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))),
                DataCell(Text('${r.totalRevenue.toStringAsFixed(0)} ج.م')),
                DataCell(Text(r.status, style: TextStyle(color: r.status == 'نشط' ? Colors.green : Colors.orange, fontWeight: FontWeight.bold))),
              ]);
            }).toList(),
          ),
        ReportType.vehicles => DataTable(
            columns: const [
              DataColumn(label: Text('كود المركبة')),
              DataColumn(label: Text('رقم اللوحة')),
              DataColumn(label: Text('الموديل')),
              DataColumn(label: Text('الرحلات المنجزة')),
              DataColumn(label: Text('معدل الوقود')),
              DataColumn(label: Text('حالة الصيانة')),
              DataColumn(label: Text('حالة التشغيل')),
            ],
            rows: rows.cast<VehicleReportRow>().take(50).map((r) {
              return DataRow(cells: [
                DataCell(Text(r.vehicleId, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(r.plateNumber)),
                DataCell(Text(r.model)),
                DataCell(Text('${r.completedTrips} رحلة')),
                DataCell(Text('${r.fuelConsumption.toStringAsFixed(1)} لتر/100كم')),
                DataCell(Text(r.maintenanceStatus, style: TextStyle(color: r.maintenanceStatus == 'جاهزة' ? Colors.green : Colors.red, fontWeight: FontWeight.bold))),
                DataCell(Text(r.status)),
              ]);
            }).toList(),
          ),
        ReportType.subscriptions => DataTable(
            columns: const [
              DataColumn(label: Text('اسم الباقة')),
              DataColumn(label: Text('المشتركين النشطين')),
              DataColumn(label: Text('الاشتراكات المنتهية')),
              DataColumn(label: Text('إجمالي المبيعات')),
              DataColumn(label: Text('عمليات التجديد')),
            ],
            rows: rows.cast<SubscriptionReportRow>().take(50).map((r) {
              return DataRow(cells: [
                DataCell(Text(r.packageName, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text('${r.activeUsers} مستخدم')),
                DataCell(Text('${r.expiredUsers} مستخدم')),
                DataCell(Text('${r.totalRevenue.toStringAsFixed(0)} ج.م')),
                DataCell(Text('${r.renewalsCount} تجديد')),
              ]);
            }).toList(),
          ),
        ReportType.complaints => DataTable(
            columns: const [
              DataColumn(label: Text('التصنيف')),
              DataColumn(label: Text('إجمالي الشكاوى')),
              DataColumn(label: Text('تم حلها')),
              DataColumn(label: Text('متوسط وقت الحل')),
              DataColumn(label: Text('معلقة')),
            ],
            rows: rows.cast<ComplaintReportRow>().take(50).map((r) {
              return DataRow(cells: [
                DataCell(Text(r.category, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text('${r.totalComplaints} شكوى')),
                DataCell(Text('${r.resolvedComplaints} شكوى')),
                DataCell(Text('${r.avgResolutionTime.toStringAsFixed(1)} ساعة')),
                DataCell(Text('${r.pendingComplaints} شكوى معلقة', style: TextStyle(color: r.pendingComplaints > 0 ? Colors.red : Colors.grey))),
              ]);
            }).toList(),
          ),
      },
    );
  }
}
