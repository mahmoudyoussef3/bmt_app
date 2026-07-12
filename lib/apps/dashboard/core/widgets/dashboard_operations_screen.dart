import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_button.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/empty_state.dart';
import 'package:bmt_app/core/widgets/metric_tile.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../features/dashboard_operations/domain/entities/dashboard_workspace.dart';
import '../../features/dashboard_operations/presentation/cubit/dashboard_workspace_cubit.dart';
import '../../features/dashboard_operations/presentation/cubit/dashboard_workspace_state.dart';

class DashboardOperationsScreen extends StatefulWidget {
  final String workspaceId;

  const DashboardOperationsScreen({required this.workspaceId, super.key});

  @override
  State<DashboardOperationsScreen> createState() =>
      _DashboardOperationsScreenState();
}

class _DashboardOperationsScreenState extends State<DashboardOperationsScreen> {
  static const _pageSize = 5;

  String _filter = 'all';
  String _query = '';
  bool _showAdvancedFilters = false;
  int _page = 0;
  final Set<DashboardWorkspaceRow> _selectedRows = {};

  @override
  void didUpdateWidget(covariant DashboardOperationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workspaceId != widget.workspaceId) {
      _filter = 'all';
      _query = '';
      _page = 0;
      _selectedRows.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardWorkspaceCubit, DashboardWorkspaceState>(
      builder: (context, state) {
        return switch (state) {
          DashboardWorkspaceLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          DashboardWorkspaceError(:final message) => Center(
            child: Text(message),
          ),
          DashboardWorkspaceEmpty() => const Center(
            child: EmptyState(
              title: 'لا توجد بيانات',
              subtitle: 'لا توجد عناصر تشغيلية للعرض حالياً.',
            ),
          ),
          DashboardWorkspaceLoaded(:final workspace) => _WorkspaceContent(
            workspace: workspace,
            filter: _filter,
            query: _query,
            page: _page,
            pageSize: _pageSize,
            selectedRows: _selectedRows,
            showAdvancedFilters: _showAdvancedFilters,
            onFilterChanged: (filter) => setState(() {
              _filter = filter;
              _page = 0;
              _selectedRows.clear();
            }),
            onQueryChanged: (query) => setState(() {
              _query = query;
              _page = 0;
            }),
            onPageChanged: (page) => setState(() => _page = page),
            onAdvancedFiltersChanged: (value) =>
                setState(() => _showAdvancedFilters = value),
            onSelectionChanged: (row, selected) => setState(() {
              if (selected) {
                _selectedRows.add(row);
              } else {
                _selectedRows.remove(row);
              }
            }),
            onSelectAllChanged: (rows, selected) => setState(() {
              if (selected) {
                _selectedRows.addAll(rows);
              } else {
                _selectedRows.removeAll(rows);
              }
            }),
            onClearSelection: () => setState(_selectedRows.clear),
          ),
        };
      },
    );
  }
}

class _WorkspaceContent extends StatelessWidget {
  final DashboardWorkspace workspace;
  final String filter;
  final String query;
  final int page;
  final int pageSize;
  final Set<DashboardWorkspaceRow> selectedRows;
  final bool showAdvancedFilters;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<bool> onAdvancedFiltersChanged;
  final void Function(DashboardWorkspaceRow row, bool selected)
  onSelectionChanged;
  final void Function(List<DashboardWorkspaceRow> rows, bool selected)
  onSelectAllChanged;
  final VoidCallback onClearSelection;

  const _WorkspaceContent({
    required this.workspace,
    required this.filter,
    required this.query,
    required this.page,
    required this.pageSize,
    required this.selectedRows,
    required this.showAdvancedFilters,
    required this.onFilterChanged,
    required this.onQueryChanged,
    required this.onPageChanged,
    required this.onAdvancedFiltersChanged,
    required this.onSelectionChanged,
    required this.onSelectAllChanged,
    required this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    final filteredRows = _filteredRows;
    final maxPage = filteredRows.isEmpty
        ? 0
        : ((filteredRows.length - 1) / pageSize).floor();
    final activePage = page.clamp(0, maxPage);
    final pageRows = filteredRows
        .skip(activePage * pageSize)
        .take(pageSize)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        _WorkspaceHeader(workspace: workspace),
        const SizedBox(height: AppSpacing.large),
        _MetricStrip(metrics: workspace.metrics),
        const SizedBox(height: AppSpacing.large),
        _ModuleSpecialPanel(workspace: workspace),
        _WorkflowToolbar(
          workspace: workspace,
          query: query,
          filter: filter,
          selectedCount: selectedRows.length,
          showAdvancedFilters: showAdvancedFilters,
          onQueryChanged: onQueryChanged,
          onFilterChanged: onFilterChanged,
          onAdvancedFiltersChanged: onAdvancedFiltersChanged,
          onClearSelection: onClearSelection,
        ),
        const SizedBox(height: AppSpacing.medium),
        _WorkspaceTable(
          workspace: workspace,
          rows: pageRows,
          selectedRows: selectedRows,
          onSelectionChanged: onSelectionChanged,
          onSelectAllChanged: onSelectAllChanged,
        ),
        const SizedBox(height: AppSpacing.medium),
        _PaginationBar(
          totalCount: filteredRows.length,
          page: activePage,
          pageSize: pageSize,
          onPageChanged: onPageChanged,
        ),
        const SizedBox(height: AppSpacing.large),
        _WorkspaceSections(sections: workspace.sections),
      ],
    );
  }

  List<DashboardWorkspaceRow> get _filteredRows {
    final normalizedQuery = query.trim().toLowerCase();
    return workspace.rows.where((row) {
      final matchesFilter = filter == 'all' || row.status == filter;
      final text = [...row.cells, row.details].join(' ').toLowerCase();
      final matchesQuery =
          normalizedQuery.isEmpty || text.contains(normalizedQuery);
      return matchesFilter && matchesQuery;
    }).toList();
  }
}

class _WorkspaceHeader extends StatelessWidget {
  final DashboardWorkspace workspace;

  const _WorkspaceHeader({required this.workspace});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 720;
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              workspace.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xSmall),
            Text(
              workspace.subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        );
        final actions = Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          children: [
            AppButton(
              label: 'إضافة',
              height: 40,
              onPressed: () => _openFormDialog(context, workspace),
            ),
            AppButton(
              label: 'تصدير',
              height: 40,
              onPressed: () => _openExportDialog(context, workspace),
            ),
          ],
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: AppSpacing.medium),
              actions,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: title),
            const SizedBox(width: AppSpacing.medium),
            actions,
          ],
        );
      },
    );
  }
}

class _MetricStrip extends StatelessWidget {
  final List<DashboardWorkspaceMetric> metrics;

  const _MetricStrip({required this.metrics});

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? metrics.length.clamp(1, 4)
            : constraints.maxWidth >= 580
            ? 2
            : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.medium,
            mainAxisSpacing: AppSpacing.medium,
            mainAxisExtent: 116,
          ),
          itemBuilder: (context, index) {
            final metric = metrics[index];
            return MetricTile(
              label: metric.label,
              value: metric.value,
              trend: metric.note,
            );
          },
        );
      },
    );
  }
}

class _ModuleSpecialPanel extends StatelessWidget {
  final DashboardWorkspace workspace;

  const _ModuleSpecialPanel({required this.workspace});

  @override
  Widget build(BuildContext context) {
    return switch (workspace.id) {
      'liveTrips' => const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.large),
        child: _LiveTripsPanel(),
      ),
      'routes' => const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.large),
        child: _RouteTimelinePanel(),
      ),
      'payments' => const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.large),
        child: _ReceiptPreviewPanel(),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _WorkflowToolbar extends StatelessWidget {
  final DashboardWorkspace workspace;
  final String query;
  final String filter;
  final int selectedCount;
  final bool showAdvancedFilters;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<bool> onAdvancedFiltersChanged;
  final VoidCallback onClearSelection;

  const _WorkflowToolbar({
    required this.workspace,
    required this.query,
    required this.filter,
    required this.selectedCount,
    required this.showAdvancedFilters,
    required this.onQueryChanged,
    required this.onFilterChanged,
    required this.onAdvancedFiltersChanged,
    required this.onClearSelection,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'بحث',
                    hintText: 'ابحث بالاسم أو الرقم أو الحالة',
                  ),
                  onChanged: onQueryChanged,
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              IconButton.filledTonal(
                tooltip: 'فلاتر متقدمة',
                onPressed: () => onAdvancedFiltersChanged(!showAdvancedFilters),
                icon: const Icon(Icons.tune),
              ),
              const SizedBox(width: AppSpacing.small),
              PopupMenuButton<String>(
                tooltip: 'إجراءات جماعية',
                enabled: selectedCount > 0,
                onSelected: (value) => _handleBulkAction(
                  context,
                  workspace,
                  value,
                  selectedCount,
                  onClearSelection,
                ),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'status', child: Text('تحديث الحالة')),
                  PopupMenuItem(value: 'delete', child: Text('حذف المحدد')),
                ],
                child: Badge(
                  label: Text('$selectedCount'),
                  isLabelVisible: selectedCount > 0,
                  child: const Icon(Icons.more_vert),
                ),
              ),
            ],
          ),
          if (showAdvancedFilters) ...[
            const SizedBox(height: AppSpacing.medium),
            Wrap(
              spacing: AppSpacing.small,
              runSpacing: AppSpacing.small,
              children: workspace.tabs
                  .map(
                    (tab) => ChoiceChip(
                      label: Text(tab.label),
                      selected: filter == tab.filter,
                      onSelected: (_) => onFilterChanged(tab.filter),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              'الفلاتر محلية وتعمل على البيانات الوهمية فقط.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class _WorkspaceTable extends StatelessWidget {
  final DashboardWorkspace workspace;
  final List<DashboardWorkspaceRow> rows;
  final Set<DashboardWorkspaceRow> selectedRows;
  final void Function(DashboardWorkspaceRow row, bool selected)
  onSelectionChanged;
  final void Function(List<DashboardWorkspaceRow> rows, bool selected)
  onSelectAllChanged;

  const _WorkspaceTable({
    required this.workspace,
    required this.rows,
    required this.selectedRows,
    required this.onSelectionChanged,
    required this.onSelectAllChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const AppCard(
        child: EmptyState(
          title: 'لا توجد عناصر',
          subtitle: 'عدّل البحث أو الفلاتر لعرض عناصر أخرى.',
        ),
      );
    }

    final allSelected = rows.every(selectedRows.contains);

    return AppCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 980),
          child: DataTable(
            showCheckboxColumn: false,
            columns: [
              DataColumn(
                label: Checkbox(
                  value: allSelected,
                  onChanged: (value) =>
                      onSelectAllChanged(rows, value ?? false),
                ),
              ),
              ...workspace.columns.map(
                (column) => DataColumn(label: Text(column)),
              ),
              const DataColumn(label: Text('إجراءات')),
            ],
            rows: rows
                .map(
                  (row) => DataRow(
                    selected: selectedRows.contains(row),
                    cells: [
                      DataCell(
                        Checkbox(
                          value: selectedRows.contains(row),
                          onChanged: (value) =>
                              onSelectionChanged(row, value ?? false),
                        ),
                      ),
                      ...row.cells.map(
                        (cell) => DataCell(
                          Text(
                            cell,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(_RowActions(workspace: workspace, row: row)),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _RowActions extends StatelessWidget {
  final DashboardWorkspace workspace;
  final DashboardWorkspaceRow row;

  const _RowActions({required this.workspace, required this.row});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'التفاصيل',
          onPressed: () => _openDetailsSheet(context, workspace, row),
          icon: const Icon(Icons.open_in_new),
        ),
        PopupMenuButton<String>(
          tooltip: 'إجراءات',
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _openFormDialog(context, workspace, row: row);
              case 'status':
                _openStatusDialog(context, workspace, row);
              case 'delete':
                _openDeleteDialog(context, row);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('تعديل')),
            PopupMenuItem(value: 'status', child: Text('تحديث الحالة')),
            PopupMenuItem(value: 'delete', child: Text('حذف')),
          ],
        ),
      ],
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final int totalCount;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const _PaginationBar({
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final maxPage = totalCount == 0 ? 0 : ((totalCount - 1) / pageSize).floor();
    final start = totalCount == 0 ? 0 : page * pageSize + 1;
    final end = (start + pageSize - 1).clamp(0, totalCount);

    return Row(
      children: [
        Text('عرض $start - $end من $totalCount'),
        const Spacer(),
        IconButton(
          tooltip: 'السابق',
          onPressed: page == 0 ? null : () => onPageChanged(page - 1),
          icon: const Icon(Icons.chevron_left),
        ),
        Text('${page + 1} / ${maxPage + 1}'),
        IconButton(
          tooltip: 'التالي',
          onPressed: page >= maxPage ? null : () => onPageChanged(page + 1),
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _WorkspaceSections extends StatelessWidget {
  final List<DashboardWorkspaceSection> sections;

  const _WorkspaceSections({required this.sections});

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) return const SizedBox.shrink();

    return Column(
      children: sections
          .map(
            (section) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.medium),
              child: AppCard(
                child: ExpansionTile(
                  initiallyExpanded: true,
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(
                    bottom: AppSpacing.small,
                  ),
                  title: Text(section.title),
                  children: section.items.map(_ChecklistRow.new).toList(),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final String text;

  const _ChecklistRow(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 18),
          const SizedBox(width: AppSpacing.small),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _WorkspaceFormDialog extends StatefulWidget {
  final DashboardWorkspace workspace;
  final DashboardWorkspaceRow? row;

  const _WorkspaceFormDialog({required this.workspace, this.row});

  @override
  State<_WorkspaceFormDialog> createState() => _WorkspaceFormDialogState();
}

class _WorkspaceFormDialogState extends State<_WorkspaceFormDialog> {
  late final List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = widget.workspace.columns.indexed.map((entry) {
      final (index, _) = entry;
      final initial = widget.row != null && index < widget.row!.cells.length
          ? widget.row!.cells[index]
          : '';
      return TextEditingController(text: initial);
    }).toList();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.row == null ? 'إضافة ${widget.workspace.title}' : 'تعديل',
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.workspace.columns.indexed.map((entry) {
              final (index, column) = entry;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                child: TextField(
                  controller: _controllers[index],
                  decoration: InputDecoration(labelText: column),
                ),
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            final cells = _controllers.map((controller) {
              final value = controller.text.trim();
              return value.isEmpty ? 'غير محدد' : value;
            }).toList();
            final cubit = context.read<DashboardWorkspaceCubit>();
            final row = widget.row;
            if (row == null) {
              cubit.createRow(cells);
            } else {
              cubit.updateRow(row, cells);
            }
            Navigator.of(context).pop();
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

class _StatusDialog extends StatefulWidget {
  final DashboardWorkspace workspace;
  final DashboardWorkspaceRow row;

  const _StatusDialog({required this.workspace, required this.row});

  @override
  State<_StatusDialog> createState() => _StatusDialogState();
}

class _StatusDialogState extends State<_StatusDialog> {
  late String _status;

  @override
  void initState() {
    super.initState();
    _status = widget.row.cells.isEmpty ? '' : widget.row.cells.last;
  }

  @override
  Widget build(BuildContext context) {
    final options = _statusOptions(widget.workspace, widget.row);
    if (!options.contains(_status)) {
      _status = options.first;
    }

    return AlertDialog(
      title: const Text('تحديث الحالة'),
      content: DropdownButtonFormField<String>(
        initialValue: _status,
        items: options
            .map(
              (status) => DropdownMenuItem(value: status, child: Text(status)),
            )
            .toList(),
        onChanged: (value) {
          if (value != null) setState(() => _status = value);
        },
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            context.read<DashboardWorkspaceCubit>().updateStatus(
              widget.row,
              _status,
            );
            Navigator.of(context).pop();
          },
          child: const Text('تحديث'),
        ),
      ],
    );
  }
}

class _DetailsSheet extends StatelessWidget {
  final DashboardWorkspace workspace;
  final DashboardWorkspaceRow row;

  const _DetailsSheet({required this.workspace, required this.row});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fields = _detailFields(workspace, row);
    final tabs = _detailTabs(workspace, row);

    return DefaultTabController(
      length: tabs.length,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: scheme.primaryContainer,
                  child: Icon(
                    _moduleIcon(workspace.id),
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: AppSpacing.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.cells.isEmpty ? workspace.title : row.cells.first,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.xSmall),
                      StatusChip(
                        label: row.cells.isEmpty ? 'نشط' : row.cells.last,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'إغلاق',
                  onPressed: Navigator.of(context).pop,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.large),
            TabBar(
              isScrollable: true,
              tabs: tabs.map((tab) => Tab(text: tab.title)).toList(),
            ),
            const SizedBox(height: AppSpacing.medium),
            Expanded(
              child: TabBarView(
                children: tabs.map((tab) {
                  if (tab.title == 'بيانات عامة' || tab.title == 'التفاصيل') {
                    return _FieldGrid(fields: fields, details: row.details);
                  }
                  return _SectionList(section: tab);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldGrid extends StatelessWidget {
  final List<DashboardWorkspaceField> fields;
  final String details;

  const _FieldGrid({required this.fields, required this.details});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Text(details),
        const SizedBox(height: AppSpacing.large),
        Wrap(
          spacing: AppSpacing.medium,
          runSpacing: AppSpacing.medium,
          children: fields
              .map(
                (field) => SizedBox(
                  width: 220,
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          field.label,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.xSmall),
                        Text(
                          field.value,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _SectionList extends StatelessWidget {
  final DashboardWorkspaceSection section;

  const _SectionList({required this.section});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: section.items.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) => ListTile(
        leading: const Icon(Icons.description_outlined),
        title: Text(section.items[index]),
      ),
    );
  }
}

class _LiveTripsPanel extends StatelessWidget {
  const _LiveTripsPanel();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        final map = AppCard(
          child: Container(
            height: 260,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Center(
                    child: Icon(
                      Icons.map_outlined,
                      size: 72,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const Positioned(
                  top: 24,
                  right: 28,
                  child: _MapMarker(label: '٢٢١'),
                ),
                const Positioned(
                  bottom: 44,
                  left: 72,
                  child: _MapMarker(label: '٢٢٦'),
                ),
              ],
            ),
          ),
        );
        final alerts = AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('تنبيهات مباشرة'),
              SizedBox(height: AppSpacing.medium),
              _ChecklistRow('رحلة ٢٢٦ متأخرة ٩ دقائق عند محور شبرا.'),
              _ChecklistRow('السائق كريم حسن أكد الوصول للنقطة الثالثة.'),
              _ChecklistRow('راكبان لم يسجلا الحضور في رحلة ٢٢١.'),
            ],
          ),
        );

        if (!isWide) {
          return Column(
            children: [
              map,
              const SizedBox(height: AppSpacing.medium),
              alerts,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: map),
            const SizedBox(width: AppSpacing.medium),
            Expanded(child: alerts),
          ],
        );
      },
    );
  }
}

class _MapMarker extends StatelessWidget {
  final String label;

  const _MapMarker({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.small,
          vertical: AppSpacing.xSmall,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: scheme.onPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _RouteTimelinePanel extends StatelessWidget {
  const _RouteTimelinePanel();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const stops = ['بنها', 'شبرا', 'الدائري', 'الشيخ زايد', 'القرية الذكية'];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('خط سير المسار', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.medium),
          Row(
            children: stops.indexed.map((entry) {
              final (index, stop) = entry;
              return Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: scheme.primaryContainer,
                      child: Text('${index + 1}'),
                    ),
                    const SizedBox(width: AppSpacing.xSmall),
                    Expanded(
                      child: Text(stop, overflow: TextOverflow.ellipsis),
                    ),
                    if (index != stops.length - 1)
                      Expanded(child: Divider(color: scheme.outline)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ReceiptPreviewPanel extends StatelessWidget {
  const _ReceiptPreviewPanel();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
            ),
            child: const Icon(Icons.receipt_long_outlined, size: 36),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'معاينة إيصالات وهمية',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xSmall),
                Text(
                  'كل صور الإيصالات هنا تمثيلية لمراجعة القبول والرفض وطلب المراجعة.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _openFormDialog(
  BuildContext context,
  DashboardWorkspace workspace, {
  DashboardWorkspaceRow? row,
}) {
  showDialog<void>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: context.read<DashboardWorkspaceCubit>(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: _WorkspaceFormDialog(workspace: workspace, row: row),
      ),
    ),
  );
}

void _openStatusDialog(
  BuildContext context,
  DashboardWorkspace workspace,
  DashboardWorkspaceRow row,
) {
  showDialog<void>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: context.read<DashboardWorkspaceCubit>(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: _StatusDialog(workspace: workspace, row: row),
      ),
    ),
  );
}

void _openDeleteDialog(BuildContext context, DashboardWorkspaceRow row) {
  showDialog<void>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: context.read<DashboardWorkspaceCubit>(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('حذف العنصر'),
          content: const Text(
            'سيتم حذف هذا العنصر من البيانات التجريبية الحالية.',
          ),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                context.read<DashboardWorkspaceCubit>().deleteRow(row);
                Navigator.of(context).pop();
              },
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    ),
  );
}

void _openDetailsSheet(
  BuildContext context,
  DashboardWorkspace workspace,
  DashboardWorkspaceRow row,
) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.82,
        child: _DetailsSheet(workspace: workspace, row: row),
      ),
    ),
  );
}

void _openExportDialog(BuildContext context, DashboardWorkspace workspace) {
  showDialog<void>(
    context: context,
    builder: (context) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text('تصدير ${workspace.title}'),
        content: const Text('واجهة تصدير تجريبية للبيانات المحلية فقط.'),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('إغلاق'),
          ),
          FilledButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('تجهيز ملف وهمي'),
          ),
        ],
      ),
    ),
  );
}

void _handleBulkAction(
  BuildContext context,
  DashboardWorkspace workspace,
  String value,
  int selectedCount,
  VoidCallback onClearSelection,
) {
  showDialog<void>(
    context: context,
    builder: (context) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('إجراء جماعي'),
        content: Text('سيتم تطبيق الإجراء على $selectedCount عناصر محددة.'),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              onClearSelection();
              Navigator.of(context).pop();
            },
            child: Text(value == 'delete' ? 'حذف' : 'تحديث'),
          ),
        ],
      ),
    ),
  );
}

List<String> _statusOptions(
  DashboardWorkspace workspace,
  DashboardWorkspaceRow row,
) {
  if (workspace.statusOptions.isNotEmpty) return workspace.statusOptions;
  final moduleOptions = switch (workspace.id) {
    'bookings' => ['جديد', 'مؤكد', 'قيد المراجعة', 'ملغي', 'مكتمل'],
    'trips' || 'liveTrips' => [
      'مجدولة',
      'قيد التحضير',
      'جاهزة للانطلاق',
      'في الطريق',
      'وصلت',
      'مكتملة',
      'ملغاة',
    ],
    'drivers' => ['متاح', 'في رحلة', 'متوقف', 'غير نشط'],
    'vehicles' => ['جاهزة', 'في رحلة', 'صيانة', 'غير نشطة'],
    'payments' => ['معلق', 'مقبول', 'مرفوض', 'يحتاج مراجعة'],
    'tickets' => ['مفتوحة', 'قيد المعالجة', 'مصعدة', 'مغلقة'],
    'subscriptions' => ['نشط', 'ينتهي قريباً', 'معلق', 'موقوف'],
    _ => <String>[],
  };
  if (moduleOptions.isNotEmpty) return moduleOptions;
  final current = row.cells.isEmpty ? 'نشط' : row.cells.last;
  return {current, 'نشط', 'قيد المراجعة', 'مكتمل', 'ملغي'}.toList();
}

List<DashboardWorkspaceField> _detailFields(
  DashboardWorkspace workspace,
  DashboardWorkspaceRow row,
) {
  if (row.fields.isNotEmpty) return row.fields;
  final baseFields = workspace.columns.indexed.map((entry) {
    final (index, column) = entry;
    return DashboardWorkspaceField(
      label: column,
      value: index < row.cells.length ? row.cells[index] : 'غير محدد',
    );
  }).toList();

  final extraFields = switch (workspace.id) {
    'drivers' => const [
      DashboardWorkspaceField(label: 'رقم البطاقة', value: '—'),
      DashboardWorkspaceField(label: 'العنوان', value: '—'),
      DashboardWorkspaceField(label: 'المركبة الحالية', value: '—'),
      DashboardWorkspaceField(label: 'المسار الحالي', value: '—'),
      DashboardWorkspaceField(label: 'تاريخ التعيين', value: '—'),
      DashboardWorkspaceField(label: 'عدد الرحلات', value: '—'),
      DashboardWorkspaceField(label: 'الملاحظات', value: '—'),
      DashboardWorkspaceField(label: 'المرفقات', value: '—'),
    ],
    'vehicles' => const [
      DashboardWorkspaceField(label: 'الموديل', value: '—'),
      DashboardWorkspaceField(label: 'السائق الحالي', value: '—'),
      DashboardWorkspaceField(label: 'المسار الحالي', value: '—'),
      DashboardWorkspaceField(label: 'التأمين', value: '—'),
      DashboardWorkspaceField(label: 'الرخصة', value: '—'),
      DashboardWorkspaceField(label: 'الفحص الفني', value: '—'),
    ],
    'routes' => const [
      DashboardWorkspaceField(label: 'المسافة', value: '—'),
      DashboardWorkspaceField(label: 'المدة', value: '—'),
      DashboardWorkspaceField(label: 'عدد النقاط', value: '—'),
      DashboardWorkspaceField(label: 'إدارة النقاط', value: '—'),
    ],
    'trips' || 'liveTrips' => const [
      DashboardWorkspaceField(label: 'المركبة', value: '—'),
      DashboardWorkspaceField(label: 'عدد الركاب', value: '—'),
      DashboardWorkspaceField(label: 'الوقت', value: '—'),
      DashboardWorkspaceField(label: 'الملاحظات', value: '—'),
    ],
    'bookings' => const [
      DashboardWorkspaceField(label: 'المقعد', value: '—'),
      DashboardWorkspaceField(label: 'المبلغ', value: '—'),
      DashboardWorkspaceField(label: 'طريقة الدفع', value: '—'),
      DashboardWorkspaceField(label: 'المرفقات', value: '—'),
    ],
    'payments' => const [
      DashboardWorkspaceField(label: 'الطريقة', value: '—'),
      DashboardWorkspaceField(label: 'التاريخ', value: '—'),
      DashboardWorkspaceField(label: 'الإيصال', value: '—'),
    ],
    'tickets' => const [
      DashboardWorkspaceField(label: 'نوع الشكوى', value: '—'),
      DashboardWorkspaceField(label: 'الوصف', value: '—'),
      DashboardWorkspaceField(label: 'الردود', value: '—'),
      DashboardWorkspaceField(label: 'المرفقات', value: '—'),
    ],
    _ => const <DashboardWorkspaceField>[],
  };

  return [...baseFields, ...extraFields];
}

List<DashboardWorkspaceSection> _detailTabs(
  DashboardWorkspace workspace,
  DashboardWorkspaceRow row,
) {
  if (row.tabs.isNotEmpty) {
    return [
      const DashboardWorkspaceSection(title: 'بيانات عامة', items: []),
      ...row.tabs,
    ];
  }

  final moduleTabs = switch (workspace.id) {
    'drivers' => ['الرحلات', 'المخالفات', 'المستندات', 'المدفوعات'],
    'vehicles' => ['الصيانة', 'المستندات', 'الرحلات'],
    'trips' => ['الركاب', 'التتبع', 'المدفوعات', 'الأحداث'],
    'bookings' => ['المرفقات', 'السجل'],
    'users' => [
      'الرحلات',
      'المدفوعات',
      'الاشتراكات',
      'الشكاوى',
      'المستندات',
      'الملاحظات',
    ],
    'payments' => ['الإيصالات', 'السجل'],
    'tickets' => ['المحادثة', 'السجل'],
    _ => ['السجل', 'المرفقات'],
  };

  return [
    const DashboardWorkspaceSection(title: 'بيانات عامة', items: []),
    ...moduleTabs.map(
      (tab) => DashboardWorkspaceSection(
        title: tab,
        items: [
          '${workspace.title}: سجل تجريبي مرتبط بالعنصر.',
          'آخر تحديث محلي ضمن النموذج الأولي.',
          'لا توجد بيانات مرسلة إلى أي خادم.',
        ],
      ),
    ),
  ];
}

IconData _moduleIcon(String workspaceId) {
  return switch (workspaceId) {
    'drivers' => Icons.badge_outlined,
    'vehicles' => Icons.directions_bus_outlined,
    'routes' => Icons.alt_route_outlined,
    'trips' || 'liveTrips' => Icons.route_outlined,
    'payments' => Icons.payments_outlined,
    'tickets' => Icons.support_agent_outlined,
    'users' => Icons.person_outline,
    _ => Icons.folder_open_outlined,
  };
}
