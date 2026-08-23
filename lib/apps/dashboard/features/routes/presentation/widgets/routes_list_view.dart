import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_colors.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/charts/chart_palette.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_empty_state.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_status_chip.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/ops_data_table.dart';
import 'package:bmt_app/apps/dashboard/features/trips/presentation/widgets/trip_ui_helpers.dart'
    show formatTripPrice;
import 'package:bmt_app/core/theme/colors.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/debounced_search_field.dart';
import 'package:bmt_app/core/widgets/route_direction_text.dart';

import '../../domain/entities/operation_route.dart';
import '../cubit/routes_cubit.dart';
import '../cubit/routes_state.dart';
import 'route_details_view.dart' show confirmArchiveRoute, confirmDeleteRoute;
import 'route_timeline_node.dart';

/// The board of routes: a bare header, four always-visible KPI tiles and one
/// table — the same generic `isTable` module shape [TripsLoadedView] (Trips
/// screen) already matches, so the two feel like one system rather than two
/// redesigns of the same idea.
///
/// This replaces a card grid whose only real content — direction, code, stop
/// count — is a subset of what the table row shows plus the numbers a card
/// had no room for (occupancy, weekly trips, price). Nothing the grid did is
/// lost: every action it exposed (view, edit) plus the ones only the route
/// detail page had (duplicate, return leg, pause/activate, archive, delete)
/// are on the row's menu now.
class RoutesListView extends StatelessWidget {
  final RoutesLoaded state;

  const RoutesListView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RoutesCubit>();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        DashboardModuleHeader(
          icon: DashboardIcons.routesActive,
          title: 'المسارات',
          subtitle: 'خطوط الخدمة ومحطات التحميل والتسعير',
          actions: [
            OutlinedButton.icon(
              onPressed: () => _exportComingSoon(context),
              icon: const Icon(Icons.download_rounded),
              label: const Text('تصدير'),
            ),
            FilledButton.icon(
              onPressed: cubit.showBuilder,
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة مسار جديد'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.medium),
        _RoutesKpiRow(state: state),
        const SizedBox(height: AppSpacing.medium),
        _RoutesTable(state: state),
      ],
    );
  }

  void _exportComingSoon(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تصدير المسارات غير متاح بعد.')));
  }
}

/// The four numbers an operator needs before touching a filter: the
/// least-full and most-full route, how many loading stations exist, and how
/// many routes are actually active. Same shape as [DashboardKpiCard]'s other
/// call sites (Home, Trips) — a plain card, an icon tint as the only colour,
/// nothing fabricated.
class _RoutesKpiRow extends StatelessWidget {
  const _RoutesKpiRow({required this.state});

  final RoutesLoaded state;

  @override
  Widget build(BuildContext context) {
    final palette = DashboardChartPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final lowest = state.lowestOccupancyRoute;
    final highest = state.highestOccupancyRoute;

    return DashboardKpiGrid(
      itemExtent: 116,
      children: [
        DashboardKpiCard(
          emphasized: true,
          label: 'أقل إشغال',
          value: lowest == null ? '—' : '${(lowest.$2 * 100).round()}%',
          detail: lowest == null
              ? 'لا بيانات إشغال بعد'
              : _routeLabel(context, lowest.$1),
          icon: DashboardIcons.trendDown,
          color: lowest == null ? scheme.onSurfaceVariant : scheme.error,
        ),
        DashboardKpiCard(
          emphasized: true,
          label: 'أعلى إشغال',
          value: highest == null ? '—' : '${(highest.$2 * 100).round()}%',
          detail: highest == null
              ? 'لا بيانات إشغال بعد'
              : _routeLabel(context, highest.$1),
          icon: DashboardIcons.occupancy,
          color: highest == null ? scheme.onSurfaceVariant : palette.positive,
        ),
        DashboardKpiCard(
          emphasized: true,
          label: 'محطات التحميل',
          value: '${state.totalStations}',
          detail: 'نقطة',
          icon: Icons.place_rounded,
          color: scheme.primary,
        ),
        DashboardKpiCard(
          emphasized: true,
          label: 'مسارات نشطة',
          value: '${state.activeCount}',
          detail: 'من ${state.routes.length}',
          icon: DashboardIcons.routesActive,
          color: palette.active,
        ),
      ],
    );
  }
}

/// The default routes view: search, quick status chips and the advanced
/// filter trigger inside the same bordered card as the sticky column header,
/// the rows and the pager — the shape [OpsDataTable.toolbar] was built for.
class _RoutesTable extends StatelessWidget {
  const _RoutesTable({required this.state});

  final RoutesLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RoutesCubit>();
    final rows = state.pagedRoutes;
    return OpsDataTable(
      toolbar: _RoutesTableToolbar(state: state),
      // `flex` is set equal to `minWidth` on every column here (not the usual
      // small round numbers) — [OpsDataTable] splits the table's rendered
      // width by flex *fraction*, not by minWidth, so at the exact-minWidth
      // boundary (a narrow viewport, table scrolling horizontally) a column
      // whose flex-share undercuts its own minWidth still gets squeezed
      // below it and overflows. Matching flex to minWidth exactly makes the
      // two agree at every width instead of only above it.
      columns: const [
        OpsColumn('المسار', flex: 200, minWidth: 200),
        OpsColumn('المحطات', flex: 140, minWidth: 140),
        OpsColumn('الرحلات الأسبوعية', flex: 130, minWidth: 130),
        OpsColumn(
          'السعر',
          flex: 90,
          minWidth: 90,
          numeric: true,
          sortable: true,
        ),
        OpsColumn('الحالة', flex: 90, minWidth: 90),
        OpsColumn('', flex: 104, minWidth: 104),
      ],
      rows: [for (final route in rows) _cells(context, route)],
      onRowTap: [for (final route in rows) () => cubit.showDetails(route)],
      total: state.filteredRoutes.length,
      currentPage: state.pageIndex,
      pageSize: routesPageSize,
      onPageChanged: cubit.setPage,
      // A brand-new office with zero routes needs to be told what a route
      // *is* and pointed at the builder; an office with routes that just
      // filtered to nothing needs the filters cleared, not a definition.
      emptyState: state.routes.isEmpty
          ? DashboardEmptyState(
              icon: Icons.alt_route_rounded,
              title: 'ابدأ بإضافة أول مسار',
              message:
                  'المسار هو خط سير: من أين يبدأ الأتوبيس، وأين ينتهي، وما '
                  'يمر به. يكفي اسمان لإنشائه — تحديد المواقع على الخريطة '
                  'اختياري.',
              action: FilledButton.icon(
                onPressed: cubit.showBuilder,
                icon: const Icon(Icons.add_rounded),
                label: const Text('إضافة مسار جديد'),
              ),
            )
          : DashboardEmptyState(
              icon: Icons.search_off_rounded,
              title: 'لا توجد مسارات مطابقة',
              message: 'جرّب تعديل البحث أو إزالة بعض عوامل التصفية.',
              action: TextButton.icon(
                onPressed: () => cubit.updateStatusFilter(null),
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('مسح التصفية'),
              ),
            ),
    );
  }

  List<Widget> _cells(BuildContext context, OperationRoute route) {
    final stats = state.statsFor(route);
    final tone = context.status(routeStatusTone(route.status));
    final stops = [
      route.startCity,
      route.endCity,
    ].where((name) => name.trim().isNotEmpty).toList();

    return [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          stops.length < 2
              ? Text(
                  route.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                )
              : RouteDirectionChain(stops: stops, maxLines: 1),
          Text(
            stats.occupancyRate == null
                ? 'لا بيانات إشغال'
                : '${(stats.occupancyRate! * 100).round()}% متوسط إشغال',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              color: DashboardColors.mutedInk(context),
            ),
          ),
        ],
      ),
      Text(
        route.duration.isEmpty
            ? '${route.stations.length} محطات'
            : '${route.stations.length} محطات، ${route.duration}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      Text(
        '${stats.weeklyTrips} رحلات',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      Text(
        stats.price == null
            ? '—'
            : '${formatTripPrice(stats.price!)} ${stats.currency}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
      DashboardStatusChip(
        label: route.status.label,
        color: tone.tint,
        textColor: tone.ink,
      ),
      Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'عرض التفاصيل',
              onPressed: () => context.read<RoutesCubit>().showDetails(route),
              icon: const Icon(Icons.visibility_outlined, size: 19),
              visualDensity: VisualDensity.compact,
            ),
            _RouteRowMenu(route: route),
          ],
        ),
      ),
    ];
  }
}

class _RouteRowMenu extends StatelessWidget {
  const _RouteRowMenu({required this.route});

  final OperationRoute route;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cubit = context.read<RoutesCubit>();
    final active = route.status == OperationRouteStatus.active;

    return PopupMenuButton<String>(
      tooltip: 'المزيد',
      onSelected: (value) {
        switch (value) {
          case 'edit':
            cubit.showEditRoute(route);
          case 'duplicate':
            cubit.duplicateRoute(route);
          case 'returnLeg':
            cubit.showReturnLeg(route);
          case 'pause':
            cubit.pauseRoute(route);
          case 'activate':
            cubit.activateRoute(route);
          case 'archive':
            confirmArchiveRoute(context, route);
          case 'delete':
            confirmDeleteRoute(context, route);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit_outlined),
            title: Text('تعديل المسار'),
          ),
        ),
        const PopupMenuItem(
          value: 'duplicate',
          child: ListTile(
            leading: Icon(Icons.copy_rounded),
            title: Text('نسخ المسار'),
          ),
        ),
        const PopupMenuItem(
          value: 'returnLeg',
          child: ListTile(
            leading: Icon(Icons.swap_vert_rounded),
            title: Text('إنشاء مسار العودة'),
          ),
        ),
        if (active)
          const PopupMenuItem(
            value: 'pause',
            child: ListTile(
              leading: Icon(Icons.pause_circle_outline_rounded),
              title: Text('إيقاف مؤقت'),
            ),
          )
        else
          const PopupMenuItem(
            value: 'activate',
            child: ListTile(
              leading: Icon(Icons.play_circle_outline_rounded),
              title: Text('تنشيط المسار'),
            ),
          ),
        PopupMenuItem(
          value: 'archive',
          enabled: route.status != OperationRouteStatus.archived,
          child: const ListTile(
            leading: Icon(Icons.archive_outlined),
            title: Text('أرشفة'),
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete_outline_rounded, color: scheme.error),
            title: Text('حذف نهائي', style: TextStyle(color: scheme.error)),
          ),
        ),
      ],
    );
  }
}

/// Search, status chips and the advanced-filter trigger — rendered inside
/// [_RoutesTable]'s [OpsDataTable] card, above its column header.
class _RoutesTableToolbar extends StatelessWidget {
  const _RoutesTableToolbar({required this.state});

  final RoutesLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RoutesCubit>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final search = DebouncedSearchField(
          hintText: 'ابحث باسم المسار أو المحطة…',
          onChanged: cubit.updateSearch,
        );
        final advancedFilter = _AdvancedFilterButton(state: state);
        final chips = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatusChip(
              label: 'الكل',
              selected: state.statusFilter == null,
              onSelected: () => cubit.updateStatusFilter(null),
            ),
            _StatusChip(
              label: 'نشطة ${state.activeCount}',
              selected: state.statusFilter == OperationRouteStatus.active,
              onSelected: () =>
                  cubit.updateStatusFilter(OperationRouteStatus.active),
            ),
            _StatusChip(
              label: 'متوقفة ${state.pausedCount}',
              selected: state.statusFilter == OperationRouteStatus.paused,
              onSelected: () =>
                  cubit.updateStatusFilter(OperationRouteStatus.paused),
            ),
          ],
        );

        if (constraints.maxWidth < 760) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: search),
                  const SizedBox(width: 8),
                  advancedFilter,
                ],
              ),
              const SizedBox(height: 10),
              chips,
            ],
          );
        }
        return Row(
          children: [
            SizedBox(width: 260, child: search),
            const SizedBox(width: 12),
            Expanded(child: chips),
            const SizedBox(width: 12),
            advancedFilter,
          ],
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onSelected(),
    );
  }
}

/// Statuses the quick chips leave out (مسودة، مؤرشف) — a route rarely sits in
/// either for long, so they live behind "تصفية متقدمة" rather than crowding
/// the board's two everyday filters.
class _AdvancedFilterButton extends StatelessWidget {
  const _AdvancedFilterButton({required this.state});

  final RoutesLoaded state;

  bool get _isAdvancedActive =>
      state.statusFilter == OperationRouteStatus.draft ||
      state.statusFilter == OperationRouteStatus.archived;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        OutlinedButton.icon(
          onPressed: () => _openSheet(context),
          icon: const Icon(Icons.tune_rounded, size: 18),
          label: const Text('تصفية متقدمة'),
        ),
        if (_isAdvancedActive)
          PositionedDirectional(
            end: 6,
            top: 6,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  void _openSheet(BuildContext context) {
    final cubit = context.read<RoutesCubit>();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تصفية بالحالة',
                style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              RadioGroup<OperationRouteStatus?>(
                groupValue: state.statusFilter,
                onChanged: (value) {
                  cubit.updateStatusFilter(value);
                  Navigator.pop(sheetContext);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const RadioListTile<OperationRouteStatus?>(
                      contentPadding: EdgeInsets.zero,
                      title: Text('كل الحالات'),
                      value: null,
                    ),
                    for (final status in OperationRouteStatus.values)
                      RadioListTile<OperationRouteStatus?>(
                        contentPadding: EdgeInsets.zero,
                        title: Text(status.label),
                        value: status,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

AppStatusTone routeStatusTone(OperationRouteStatus status) => switch (status) {
  OperationRouteStatus.active => AppStatusTone.success,
  OperationRouteStatus.paused => AppStatusTone.warning,
  OperationRouteStatus.draft => AppStatusTone.neutral,
  OperationRouteStatus.archived => AppStatusTone.neutral,
};

/// `بنها ← حلوان`, bidi-safe — see [routeDirectionLabel]. Falls back to the
/// stored route name for rows saved before endpoints were derived from stops.
String _routeLabel(BuildContext context, OperationRoute route) {
  final label = routeDirectionLabel(
    route.startCity,
    route.endCity,
    direction: Directionality.of(context),
  );
  return label.isEmpty ? route.name : label;
}

class RouteCodeBadge extends StatelessWidget {
  final String code;

  const RouteCodeBadge({super.key, required this.code});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withAlpha(90),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Text(
        code.isEmpty ? 'جديد' : code,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
