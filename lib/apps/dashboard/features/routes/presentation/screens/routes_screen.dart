import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/core/maps/map_route_stop.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/app_snackbar.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';
import 'package:bmt_app/core/widgets/debounced_search_field.dart';
import 'package:bmt_app/core/widgets/maps/easyway_tile_layer.dart';
import 'package:bmt_app/core/widgets/maps/markers/station_marker.dart';
import 'package:bmt_app/core/widgets/maps/overlays/map_attribution.dart';
import 'package:bmt_app/core/widgets/maps/route_line_style.dart';
import 'package:bmt_app/core/widgets/maps/route_polyline_layers.dart';

import '../../domain/entities/operation_route.dart';
import '../cubit/routes_cubit.dart';
import '../cubit/routes_state.dart';
import '../widgets/route_builder/route_builder_view.dart';
import '../widgets/routes_analytics.dart';

class RoutesScreen extends StatelessWidget {
  const RoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RoutesCubit, RoutesState>(
      listenWhen: (previous, current) =>
          current is RoutesLoaded &&
          (current.flashMessage.isNotEmpty || current.actionError.isNotEmpty),
      listener: (context, state) {
        if (state is! RoutesLoaded) return;
        if (state.flashMessage.isNotEmpty) {
          AppSnackbar.success(context, state.flashMessage);
          return;
        }
        // A failure while the builder is open is shown inside it, next to the
        // save button that produced it — a toast would vanish before the
        // operator could act on it.
        if (state.view != RoutesView.form) {
          AppSnackbar.error(context, state.actionError);
        }
      },
      builder: (context, state) {
        return switch (state) {
          RoutesLoading() => const DashboardLoading(rows: 5),
          RoutesError(:final message) => DashboardErrorState(
            message: message,
            onRetry: () => context.read<RoutesCubit>().load(),
          ),
          RoutesLoaded() => switch (state.view) {
            RoutesView.list => _RoutesListView(state: state),
            RoutesView.details => _RouteDetailsView(state: state),
            RoutesView.form => _RouteBuilderHost(state: state),
          },
        };
      },
    );
  }
}

/// Mounts the builder and wires it back to the module: cancel returns where the
/// operator came from, save goes through the routes cubit.
class _RouteBuilderHost extends StatelessWidget {
  final RoutesLoaded state;

  const _RouteBuilderHost({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RoutesCubit>();
    final editing = state.editingRoute;
    return RouteBuilderView(
      // A fresh builder per route, so an open draft is never carried over.
      key: ValueKey('route-builder-${editing?.id ?? 'new'}'),
      route: editing,
      existingCodes: state.routeCodes,
      saving: state.saving,
      saveError: state.actionError,
      onCancel: () =>
          editing == null ? cubit.showOperations() : cubit.showDetails(editing),
      onSave: cubit.saveRoute,
    );
  }
}

class _RoutesListView extends StatelessWidget {
  final RoutesLoaded state;

  const _RoutesListView({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RoutesCubit>();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        _RoutesToolbar(state: state),
        const SizedBox(height: AppSpacing.medium),
        if (state.routes.isNotEmpty) ...[
          RoutesAnalytics(state: state),
          const SizedBox(height: AppSpacing.medium),
        ],
        _RoutesBoard(
          state: state,
          onView: cubit.showDetails,
          onEdit: cubit.showEditRoute,
          onPause: cubit.pauseRoute,
          onArchive: (route) => _confirmArchive(context, route),
          onDelete: (route) => _confirmDeleteRoute(context, route),
        ),
      ],
    );
  }
}

class _RoutesToolbar extends StatelessWidget {
  final RoutesLoaded state;

  const _RoutesToolbar({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RoutesCubit>();
    final active = state.routes
        .where((route) => route.status == OperationRouteStatus.active)
        .length;
    final paused = state.routes
        .where((route) => route.status == OperationRouteStatus.paused)
        .length;
    final locatedStations = state.routes.fold<int>(
      0,
      (sum, route) =>
          sum +
          route.stations
              .where(
                (station) =>
                    station.latitude != null && station.longitude != null,
              )
              .length,
    );
    final totalStations = state.routes.fold<int>(
      0,
      (sum, route) => sum + route.stations.length,
    );

    final search = DebouncedSearchField(
      hintText: 'ابحث بالاسم أو المدينة',
      onChanged: cubit.updateSearch,
    );
    final filters = Wrap(
      spacing: AppSpacing.small,
      runSpacing: AppSpacing.small,
      children: [
        _StatusFilter(state: state),
        _CityFilter(state: state),
        _StopsFilter(state: state),
      ],
    );

    return DashboardModuleHeader(
      icon: Icons.alt_route_rounded,
      title: 'إدارة المسارات',
      subtitle:
          'بناء ومراجعة مسارات التشغيل التي تعتمد عليها الرحلات والحجوزات.',
      actions: [
        FilledButton.icon(
          onPressed: cubit.showBuilder,
          icon: const Icon(Icons.add_rounded),
          label: const Text('إضافة مسار'),
        ),
      ],
      child: Column(
        children: [
          _RouteKpiStrip(
            total: state.routes.length,
            filtered: state.filteredRoutes.length,
            active: active,
            paused: paused,
            locatedStations: locatedStations,
            totalStations: totalStations,
          ),
          const SizedBox(height: AppSpacing.medium),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 980;
              if (compact) {
                return Column(
                  children: [
                    search,
                    const SizedBox(height: AppSpacing.small),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: filters,
                    ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: search),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    flex: 5,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: filters,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RouteKpiStrip extends StatelessWidget {
  final int total;
  final int filtered;
  final int active;
  final int paused;
  final int locatedStations;
  final int totalStations;

  const _RouteKpiStrip({
    required this.total,
    required this.filtered,
    required this.active,
    required this.paused,
    required this.locatedStations,
    required this.totalStations,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DashboardKpiGrid(
      itemExtent: 84,
      children: [
        DashboardKpiCard(
          label: 'كل المسارات',
          value: '$total',
          detail: '$filtered ضمن الفلتر',
          icon: Icons.route_outlined,
          color: scheme.primary,
        ),
        DashboardKpiCard(
          label: 'نشط',
          value: '$active',
          detail: 'جاهز لإنشاء الرحلات',
          icon: Icons.check_circle_outline_rounded,
          color: scheme.primary,
        ),
        DashboardKpiCard(
          label: 'متوقف',
          value: '$paused',
          detail: 'يحتاج مراجعة تشغيلية',
          icon: Icons.pause_circle_outline_rounded,
          color: scheme.tertiary,
        ),
        DashboardKpiCard(
          label: 'مواقع المحطات',
          value: '$locatedStations/$totalStations',
          detail: totalStations == 0 ? 'لا توجد محطات' : 'جاهزية الخريطة',
          icon: Icons.map_outlined,
          color: scheme.secondary,
        ),
      ],
    );
  }
}

class _StatusFilter extends StatelessWidget {
  final RoutesLoaded state;

  const _StatusFilter({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RoutesCubit>();
    return SizedBox(
      width: 210,
      child: DropdownButtonFormField<OperationRouteStatus?>(
        isExpanded: true,
        initialValue: state.statusFilter,
        decoration: const InputDecoration(labelText: 'الحالة'),
        items: [
          const DropdownMenuItem(
            value: null,
            child: Text('كل الحالات', overflow: TextOverflow.ellipsis),
          ),
          ...OperationRouteStatus.values
              .where((status) => status != OperationRouteStatus.draft)
              .map(
                (status) => DropdownMenuItem(
                  value: status,
                  child: Text(status.label, overflow: TextOverflow.ellipsis),
                ),
              ),
        ],
        onChanged: cubit.updateStatusFilter,
      ),
    );
  }
}

class _CityFilter extends StatelessWidget {
  final RoutesLoaded state;

  const _CityFilter({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RoutesCubit>();
    return SizedBox(
      width: 230,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: state.cityFilter,
        decoration: const InputDecoration(labelText: 'المدينة'),
        items: state.cityOptions
            .map(
              (city) => DropdownMenuItem(
                value: city,
                child: Text(city, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (value) => cubit.updateCityFilter(value ?? 'الكل'),
      ),
    );
  }
}

class _StopsFilter extends StatelessWidget {
  final RoutesLoaded state;

  const _StopsFilter({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RoutesCubit>();
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<StopsCountFilter>(
        isExpanded: true,
        initialValue: state.stopsFilter,
        decoration: const InputDecoration(labelText: 'عدد المحطات'),
        items: StopsCountFilter.values
            .map(
              (filter) => DropdownMenuItem(
                value: filter,
                child: Text(filter.label, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (value) =>
            cubit.updateStopsFilter(value ?? StopsCountFilter.all),
      ),
    );
  }
}

class _RoutesBoard extends StatelessWidget {
  final RoutesLoaded state;
  final ValueChanged<OperationRoute> onView;
  final ValueChanged<OperationRoute> onEdit;
  final ValueChanged<OperationRoute> onPause;
  final ValueChanged<OperationRoute> onArchive;
  final ValueChanged<OperationRoute> onDelete;

  const _RoutesBoard({
    required this.state,
    required this.onView,
    required this.onEdit,
    required this.onPause,
    required this.onArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final routes = state.filteredRoutes;
    if (routes.isEmpty) {
      return _RoutesEmptyState(hasRoutes: state.routes.isNotEmpty);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1280
            ? 3
            : constraints.maxWidth >= 820
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: routes.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.medium,
            mainAxisSpacing: AppSpacing.medium,
            mainAxisExtent: 316,
          ),
          itemBuilder: (context, index) {
            final route = routes[index];
            return _RouteOpsCard(
              route: route,
              onView: () => onView(route),
              onEdit: () => onEdit(route),
              onPause: () => onPause(route),
              onArchive: () => onArchive(route),
              onDelete: () => onDelete(route),
            );
          },
        );
      },
    );
  }
}

class _RoutesEmptyState extends StatelessWidget {
  final bool hasRoutes;

  const _RoutesEmptyState({required this.hasRoutes});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RoutesCubit>();
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.route_outlined, size: 34, color: scheme.primary),
          const SizedBox(height: AppSpacing.small),
          Text(
            hasRoutes ? 'لا توجد مسارات مطابقة' : 'ابدأ ببناء أول مسار',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xSmall),
          Text(
            hasRoutes
                ? 'غيّر البحث أو الفلاتر لعرض مسارات أخرى.'
                : 'أنشئ مساراً بالخريطة والمحطات حتى تتمكن من إنشاء رحلات عليه لاحقاً.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.medium),
          FilledButton.icon(
            onPressed: cubit.showBuilder,
            icon: const Icon(Icons.add_rounded),
            label: const Text('إضافة مسار'),
          ),
        ],
      ),
    );
  }
}

class _RouteOpsCard extends StatelessWidget {
  final OperationRoute route;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onPause;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const _RouteOpsCard({
    required this.route,
    required this.onView,
    required this.onEdit,
    required this.onPause,
    required this.onArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final located = _locatedStations(route);
    final mapRatio = route.stations.isEmpty
        ? 0.0
        : located / route.stations.length;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _RouteCodeBadge(code: route.routeCode),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  route.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              StatusChip(label: route.status.label),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            'من ${route.startCity} إلى ${route.endCity}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.medium),
          _RouteMiniMap(route: route),
          const SizedBox(height: AppSpacing.medium),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: [
              _RouteFactPill(
                icon: Icons.signpost_outlined,
                label: '${route.stations.length} محطات',
              ),
              _RouteFactPill(
                icon: Icons.schedule_outlined,
                label: route.duration.isEmpty
                    ? 'مدة غير محددة'
                    : route.duration,
              ),
              _RouteFactPill(
                icon: Icons.straighten_outlined,
                label: route.distance.isEmpty
                    ? 'مسافة غير محددة'
                    : route.distance,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          _ReadinessBar(
            ratio: mapRatio,
            label: 'الخريطة: $located/${route.stations.length}',
          ),
          const Spacer(),
          Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: onView,
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('إدارة'),
              ),
              const SizedBox(width: AppSpacing.small),
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('تعديل'),
              ),
              const Spacer(),
              _RouteActionsMenu(
                route: route,
                onPause: onPause,
                onArchive: onArchive,
                onDelete: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteActionsMenu extends StatelessWidget {
  final OperationRoute route;
  final VoidCallback onPause;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const _RouteActionsMenu({
    required this.route,
    required this.onPause,
    required this.onArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'إجراءات المسار',
      icon: const Icon(Icons.more_horiz_rounded),
      onSelected: (value) {
        switch (value) {
          case 'pause':
            onPause();
          case 'archive':
            onArchive();
          case 'delete':
            onDelete();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'pause',
          enabled: route.status != OperationRouteStatus.archived,
          child: const Text('إيقاف مؤقت'),
        ),
        PopupMenuItem(
          value: 'archive',
          enabled: route.status != OperationRouteStatus.archived,
          child: const Text('أرشفة'),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Text(
            'حذف',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    );
  }
}

class _RouteMiniMap extends StatelessWidget {
  final OperationRoute route;

  const _RouteMiniMap({required this.route});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final located = route.stations
        .where(
          (station) => station.latitude != null && station.longitude != null,
        )
        .toList();
    if (located.isEmpty) {
      return Container(
        height: 64,
        padding: const EdgeInsets.all(AppSpacing.small),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withAlpha(60),
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          border: Border.all(color: scheme.outline.withAlpha(45)),
        ),
        child: Row(
          children: [
            Icon(Icons.add_location_alt_outlined, color: scheme.primary),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: Text(
                'لم يتم تحديد مواقع المحطات بعد',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      );
    }
    final line = located
        .map((station) => LatLng(station.latitude!, station.longitude!))
        .toList();
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      child: SizedBox(
        height: 64,
        child: IgnorePointer(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: line.first,
              initialZoom: 8.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              const EasyWayTileLayer(),
              if (line.length >= 2)
                PolylineLayer(
                  polylines: buildRoutePolylines(
                    context,
                    line,
                    style: RouteLineStyle.navigation,
                  ),
                ),
              MarkerLayer(
                markers: [
                  for (final point in [line.first, line.last])
                    Marker(
                      point: point,
                      width: 12,
                      height: 12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteCodeBadge extends StatelessWidget {
  final String code;

  const _RouteCodeBadge({required this.code});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withAlpha(90),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      ),
      child: Text(
        code.isEmpty ? 'NEW' : code,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _RouteFactPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _RouteFactPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(70),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outline.withAlpha(35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: scheme.primary),
          const SizedBox(width: 5),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _ReadinessBar extends StatelessWidget {
  final double ratio;
  final String label;

  const _ReadinessBar({required this.ratio, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final value = ratio.clamp(0, 1).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 6,
            backgroundColor: scheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _RouteDetailsView extends StatelessWidget {
  final RoutesLoaded state;

  const _RouteDetailsView({required this.state});

  @override
  Widget build(BuildContext context) {
    final route = state.selectedRoute;

    // One rendering of the stops, not three. This page used to show the same
    // stations as an editable list, as a timeline, and again as a "client
    // preview" of pickup/dropoff groups — every one of them a different shape
    // for the same rows.
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        _DetailsHeader(route: route),
        const SizedBox(height: AppSpacing.medium),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1180;
            final medium = constraints.maxWidth >= 760;
            final readiness = _RouteReadinessCommandCard(route: route);
            final quickActions = _RouteQuickActionsCard(route: route);
            final stops = _RouteStopsPanel(route: route);
            final map = _RouteMapPreviewPanel(route: route);

            final commandStrip = medium
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: readiness),
                      const SizedBox(width: AppSpacing.medium),
                      Expanded(child: quickActions),
                    ],
                  )
                : Column(
                    children: [
                      readiness,
                      const SizedBox(height: AppSpacing.medium),
                      quickActions,
                    ],
                  );

            return Column(
              children: [
                commandStrip,
                const SizedBox(height: AppSpacing.medium),
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 7, child: stops),
                      const SizedBox(width: AppSpacing.medium),
                      Expanded(flex: 5, child: map),
                    ],
                  )
                else ...[
                  map,
                  const SizedBox(height: AppSpacing.medium),
                  stops,
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _DetailsHeader extends StatelessWidget {
  final OperationRoute route;

  const _DetailsHeader({required this.route});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RoutesCubit>();
    final scheme = Theme.of(context).colorScheme;
    final located = _locatedStations(route);
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.large),
            decoration: BoxDecoration(
              color: _routeStatusColor(context, route.status).withAlpha(18),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppTokens.radius),
                topRight: Radius.circular(AppTokens.radius),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 880;
                final title = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.small,
                      runSpacing: AppSpacing.small,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _RouteCodeBadge(code: route.routeCode),
                        StatusChip(label: route.status.label),
                        StatusChip(
                          label:
                              '$located/${route.stations.length} على الخريطة',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Text(
                      route.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.xSmall),
                    Text(
                      'من ${route.startCity} إلى ${route.endCity}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
                final actions = Wrap(
                  spacing: AppSpacing.small,
                  runSpacing: AppSpacing.small,
                  children: [
                    OutlinedButton.icon(
                      onPressed: cubit.showOperations,
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('رجوع'),
                    ),
                    FilledButton.icon(
                      onPressed: () => cubit.showEditRoute(route),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('تعديل المسار'),
                    ),
                    OutlinedButton.icon(
                      onPressed: route.status == OperationRouteStatus.archived
                          ? null
                          : () => _confirmArchive(context, route),
                      icon: const Icon(Icons.archive_outlined),
                      label: const Text('أرشفة'),
                    ),
                  ],
                );
                if (compact) {
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
                  children: [
                    Expanded(child: title),
                    const SizedBox(width: AppSpacing.medium),
                    actions,
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: DashboardKpiGrid(
              itemExtent: 86,
              children: [
                DashboardKpiCard(
                  label: 'المحطات',
                  value: '${route.stations.length}',
                  detail:
                      '${_pickupCount(route)} صعود - ${_dropoffCount(route)} نزول',
                  icon: Icons.signpost_outlined,
                  color: scheme.primary,
                ),
                DashboardKpiCard(
                  label: 'المدة',
                  value: route.duration.isEmpty ? '-' : route.duration,
                  detail: 'من البداية للنهاية',
                  icon: Icons.schedule_outlined,
                  color: scheme.tertiary,
                ),
                DashboardKpiCard(
                  label: 'المسافة',
                  value: route.distance.isEmpty ? '-' : route.distance,
                  detail: 'حسب حساب المسار',
                  icon: Icons.straighten_outlined,
                  color: scheme.secondary,
                ),
                DashboardKpiCard(
                  label: 'جاهزية الخريطة',
                  value: '$located/${route.stations.length}',
                  detail: _routeReadinessLabel(route),
                  icon: Icons.map_outlined,
                  color: scheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteReadinessCommandCard extends StatelessWidget {
  final OperationRoute route;

  const _RouteReadinessCommandCard({required this.route});

  @override
  Widget build(BuildContext context) {
    final located = _locatedStations(route);
    final mapRatio = route.stations.isEmpty
        ? 0.0
        : located / route.stations.length;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle(
            icon: Icons.health_and_safety_outlined,
            title: 'جاهزية المسار',
            subtitle: _routeReadinessLabel(route),
          ),
          const SizedBox(height: AppSpacing.medium),
          _ReadinessBar(
            ratio: mapRatio,
            label: 'مواقع المحطات: $located/${route.stations.length}',
          ),
          const SizedBox(height: AppSpacing.medium),
          _RouteReadinessRow(
            label: 'محطات كافية',
            value: '${route.stations.length}',
            ok: route.stations.length >= 2,
          ),
          _RouteReadinessRow(
            label: 'نقاط الصعود',
            value: '${_pickupCount(route)}',
            ok: _pickupCount(route) > 0,
          ),
          _RouteReadinessRow(
            label: 'نقاط النزول',
            value: '${_dropoffCount(route)}',
            ok: _dropoffCount(route) > 0,
          ),
          _RouteReadinessRow(
            label: 'المسافة والمدة',
            value: route.distance.isEmpty || route.duration.isEmpty
                ? 'ناقص'
                : 'مكتمل',
            ok: route.distance.isNotEmpty && route.duration.isNotEmpty,
          ),
        ],
      ),
    );
  }
}

class _RouteQuickActionsCard extends StatelessWidget {
  final OperationRoute route;

  const _RouteQuickActionsCard({required this.route});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RoutesCubit>();
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle(
            icon: Icons.touch_app_outlined,
            title: 'إجراءات سريعة',
            subtitle: 'تحديث المسار وحالته',
          ),
          const SizedBox(height: AppSpacing.medium),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => cubit.showEditRoute(route),
              icon: const Icon(Icons.edit_location_alt_outlined),
              label: const Text('فتح محرر المسار'),
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: route.status == OperationRouteStatus.paused
                  ? null
                  : () => cubit.pauseRoute(route),
              icon: const Icon(Icons.pause_circle_outline_rounded),
              label: const Text('إيقاف مؤقت'),
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
              onPressed: () => _confirmDeleteRoute(context, route),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('حذف المسار'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PanelTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: scheme.primary),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RouteReadinessRow extends StatelessWidget {
  final String label;
  final String value;
  final bool ok;

  const _RouteReadinessRow({
    required this.label,
    required this.value,
    required this.ok,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_outline : Icons.error_outline_rounded,
            color: ok ? scheme.primary : scheme.error,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(child: Text(label)),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _RouteMapPreviewPanel extends StatelessWidget {
  final OperationRoute route;

  const _RouteMapPreviewPanel({required this.route});

  @override
  Widget build(BuildContext context) {
    final located = route.stations
        .where(
          (station) => station.latitude != null && station.longitude != null,
        )
        .toList();
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'خريطة المسار',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              StatusChip(
                label: '${located.length}/${route.stations.length} محددة',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xSmall),
          Text(
            'معاينة مواقع المحطات المحفوظة وترتيبها التشغيلي.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.medium),
          if (located.isEmpty)
            Container(
              height: 220,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withAlpha(70),
                borderRadius: BorderRadius.circular(AppTokens.radius),
                border: Border.all(color: scheme.outline.withAlpha(70)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_location_alt_outlined,
                    size: 36,
                    color: scheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Text(
                    'لم يتم تحديد مواقع المحطات بعد',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xSmall),
                  Text(
                    'افتح تعديل المسار أو إضافة محطة وحدد النقاط من الخريطة.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          else
            _RouteStationsMap(stations: located),
        ],
      ),
    );
  }
}

class _RouteStationsMap extends StatelessWidget {
  final List<RouteStation> stations;

  const _RouteStationsMap({required this.stations});

  @override
  Widget build(BuildContext context) {
    final points = stations
        .map((station) => LatLng(station.latitude!, station.longitude!))
        .toList();
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radius),
      child: SizedBox(
        height: 320,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCameraFit: points.length >= 2
                    ? CameraFit.bounds(
                        bounds: LatLngBounds.fromPoints(points),
                        padding: const EdgeInsets.all(48),
                      )
                    : null,
                initialCenter: points.first,
                initialZoom: 12,
              ),
              children: [
                const EasyWayTileLayer(),
                if (points.length >= 2)
                  PolylineLayer(polylines: buildRoutePolylines(context, points)),
                MarkerLayer(
                  markers: [
                    for (final entry in stations.indexed)
                      buildStationMarker(
                        context,
                        stop: MapRouteStop(
                          coordinate: points[entry.$1],
                          name: entry.$2.name,
                        ),
                        index: entry.$1,
                        count: stations.length,
                        onTap: () {},
                      ),
                  ],
                ),
              ],
            ),
            const PositionedDirectional(
              bottom: 4,
              start: 6,
              child: MapAttribution(),
            ),
          ],
        ),
      ),
    );
  }
}

/// The route's stops, read-only. Changing any of them — order, name, position,
/// boarding rule, dwell — happens in the route builder, which is the single
/// editor for a route's shape. This page used to carry a second one: a dialog
/// with raw latitude/longitude boxes and a free-text arrival field that wrote
/// values the schedule maths could not read back.
class _RouteStopsPanel extends StatelessWidget {
  final OperationRoute route;

  const _RouteStopsPanel({required this.route});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RoutesCubit>();
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final title = _PanelTitle(
                icon: Icons.route_outlined,
                title: 'محطات المسار',
                subtitle: 'ترتيب الوقوف والتوقيتات وقواعد الصعود والنزول.',
              );
              final action = FilledButton.icon(
                onPressed: () => cubit.showEditRoute(route),
                icon: const Icon(Icons.edit_location_alt_outlined),
                label: const Text('تعديل المحطات'),
              );
              final count = StatusChip(label: '${route.stations.length} محطة');
              if (constraints.maxWidth < 620) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: AppSpacing.small),
                    Wrap(
                      spacing: AppSpacing.small,
                      runSpacing: AppSpacing.small,
                      children: [count, action],
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: title),
                  count,
                  const SizedBox(width: AppSpacing.small),
                  action,
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.medium),
          if (route.stations.isEmpty)
            _StationsEmptyState(onAdd: () => cubit.showEditRoute(route))
          else
            ...route.stations.indexed.map(
              (entry) => _RouteStopRow(
                station: entry.$2,
                index: entry.$1,
                total: route.stations.length,
              ),
            ),
        ],
      ),
    );
  }
}

class _StationsEmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _StationsEmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(45),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: scheme.outline.withAlpha(45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.add_location_alt_outlined, color: scheme.primary, size: 30),
          const SizedBox(height: AppSpacing.small),
          Text(
            'لا توجد محطات بعد',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xSmall),
          Text(
            'افتح محرر المسار وحدد نقاط الصعود والنزول على الخريطة حتى يصبح المسار جاهزاً للرحلات.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.medium),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.edit_location_alt_outlined),
            label: const Text('تحديد المحطات'),
          ),
        ],
      ),
    );
  }
}

/// One stop as a timeline entry: order, name, where it is, when the bus reaches
/// it and what riders may do there.
class _RouteStopRow extends StatelessWidget {
  final RouteStation station;
  final int index;
  final int total;

  const _RouteStopRow({
    required this.station,
    required this.index,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final last = index == total - 1;
    final located = station.latitude != null && station.longitude != null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: located ? scheme.primary : scheme.errorContainer,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: located ? scheme.onPrimary : scheme.onErrorContainer,
                ),
              ),
            ),
            if (!last)
              Container(
                width: 2,
                height: 46,
                color: scheme.outline.withAlpha(110),
              ),
          ],
        ),
        const SizedBox(width: AppSpacing.medium),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: last ? 0 : AppSpacing.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  station.name.isEmpty ? 'محطة بدون اسم' : station.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.xSmall),
                Wrap(
                  spacing: AppSpacing.small,
                  runSpacing: AppSpacing.xSmall,
                  children: [
                    if (station.area.isNotEmpty)
                      _RouteFactPill(
                        icon: Icons.location_city_outlined,
                        label: station.area,
                      ),
                    if (station.arrivalOffset.isNotEmpty)
                      _RouteFactPill(
                        icon: Icons.schedule_outlined,
                        label: index == 0
                            ? 'الانطلاق ${station.departureOffset.isEmpty ? station.arrivalOffset : station.departureOffset}'
                            : 'وصول ${station.arrivalOffset}',
                      ),
                    _RouteFactPill(
                      icon: station.pickupAllowed
                          ? Icons.login_rounded
                          : Icons.logout_rounded,
                      label: _boardingLabel(station),
                    ),
                    if (!located)
                      _RouteFactPill(
                        icon: Icons.location_off_outlined,
                        label: 'بدون موقع',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _boardingLabel(RouteStation station) {
    if (station.pickupAllowed && station.dropoffAllowed) return 'صعود ونزول';
    if (station.pickupAllowed) return 'صعود فقط';
    if (station.dropoffAllowed) return 'نزول فقط';
    return 'غير متاحة للركاب';
  }
}

int _locatedStations(OperationRoute route) {
  return route.stations
      .where((station) => station.latitude != null && station.longitude != null)
      .length;
}

int _pickupCount(OperationRoute route) {
  return route.stations.where((station) => station.pickupAllowed).length;
}

int _dropoffCount(OperationRoute route) {
  return route.stations.where((station) => station.dropoffAllowed).length;
}

String _routeReadinessLabel(OperationRoute route) {
  if (route.status == OperationRouteStatus.archived) return 'المسار مؤرشف';
  if (route.stations.length < 2) return 'أضف محطتين على الأقل';
  if (_pickupCount(route) == 0) return 'لا توجد نقاط صعود';
  if (_dropoffCount(route) == 0) return 'لا توجد نقاط نزول';
  if (_locatedStations(route) < route.stations.length) {
    return 'بعض المحطات تحتاج تحديد موقع';
  }
  if (route.distance.isEmpty || route.duration.isEmpty) {
    return 'المسافة أو المدة غير مكتملة';
  }
  return 'جاهز لإنشاء الرحلات';
}

Color _routeStatusColor(BuildContext context, OperationRouteStatus status) {
  final scheme = Theme.of(context).colorScheme;
  return switch (status) {
    OperationRouteStatus.active => scheme.primary,
    OperationRouteStatus.paused => scheme.tertiary,
    OperationRouteStatus.draft => scheme.secondary,
    OperationRouteStatus.archived => scheme.error,
  };
}

void _confirmArchive(BuildContext context, OperationRoute route) {
  showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('تأكيد أرشفة المسار'),
      content: Text(
        'سيتم تحويل "${route.name}" إلى مؤرشف، ولن يظهر ضمن فلتر المسارات النشطة. الرحلات المرتبطة ستبقى محفوظة للرجوع إليها.',
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.read<RoutesCubit>().archiveRoute(route);
          },
          child: const Text('تأكيد الأرشفة'),
        ),
      ],
    ),
  );
}

void _confirmDeleteRoute(BuildContext context, OperationRoute route) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('حذف المسار نهائياً'),
      content: Text(
        'سيتم حذف "${route.name}" ومحطاته من قاعدة البيانات. الرحلات القديمة قد تبقى محفوظة بدون ربط بهذا المسار.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('إلغاء'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(dialogContext).colorScheme.error,
          ),
          onPressed: () {
            Navigator.pop(dialogContext);
            context.read<RoutesCubit>().deleteRoute(route);
          },
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('حذف'),
        ),
      ],
    ),
  );
}
