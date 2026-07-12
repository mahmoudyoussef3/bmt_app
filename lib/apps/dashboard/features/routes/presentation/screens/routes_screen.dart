import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_kpi_card.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_state_views.dart';
import 'package:bmt_app/apps/dashboard/features/fleet/shared/core/utils/fleet_input_formatters.dart';
import 'package:bmt_app/apps/dashboard/features/routes/domain/usecases/search_places_usecase.dart';
import 'package:bmt_app/core/geo/geo_models.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../domain/entities/operation_route.dart';
import '../cubit/routes_cubit.dart';
import '../cubit/routes_state.dart';
import '../widgets/geo_route_form_view.dart';
import '../widgets/place_search_field.dart';
import '../widgets/routes_analytics.dart';

class RoutesScreen extends StatelessWidget {
  const RoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutesCubit, RoutesState>(
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
            RoutesView.form => GeoRouteFormView(route: state.editingRoute),
            RoutesView.success => _RouteSuccessView(
              route: state.successRoute ?? state.selectedRoute,
            ),
          },
        };
      },
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

    final search = TextField(
      onChanged: cubit.updateSearch,
      decoration: const InputDecoration(
        labelText: 'بحث',
        prefixIcon: Icon(Icons.search_rounded),
      ),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      child: SizedBox(
        height: 64,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(
              located.first.latitude!,
              located.first.longitude!,
            ),
            initialZoom: 9,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.bmt.app',
            ),
            if (located.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: located
                        .map(
                          (station) =>
                              LatLng(station.latitude!, station.longitude!),
                        )
                        .toList(),
                    color: scheme.primary,
                    strokeWidth: 4,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                for (final station in located)
                  Marker(
                    point: LatLng(station.latitude!, station.longitude!),
                    width: 24,
                    height: 24,
                    child: CircleAvatar(
                      backgroundColor: scheme.primary,
                      child: Text(
                        '${station.order}',
                        style: TextStyle(
                          color: scheme.onPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
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
    final cubit = context.read<RoutesCubit>();

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
            final stations = _StopManagementPanel(
              route: route,
              onAdd: (station) => cubit.addStation(station),
              onEdit: (station) => cubit.updateStation(station),
              onDelete: cubit.deleteStation,
              onReorder: cubit.reorderStations,
            );
            final mapAndFlow = Column(
              children: [
                _RouteMapPreviewPanel(route: route),
                const SizedBox(height: AppSpacing.medium),
                _StopsTimelinePanel(route: route),
              ],
            );
            final clientPreview = _ClientRoutePreview(route: route);

            Widget commandStrip;
            if (medium) {
              commandStrip = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: readiness),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(child: quickActions),
                ],
              );
            } else {
              commandStrip = Column(
                children: [
                  readiness,
                  const SizedBox(height: AppSpacing.medium),
                  quickActions,
                ],
              );
            }

            if (!wide) {
              return Column(
                children: [
                  commandStrip,
                  const SizedBox(height: AppSpacing.medium),
                  _RouteMapPreviewPanel(route: route),
                  const SizedBox(height: AppSpacing.medium),
                  clientPreview,
                  const SizedBox(height: AppSpacing.medium),
                  _StopsTimelinePanel(route: route),
                  const SizedBox(height: AppSpacing.medium),
                  stations,
                ],
              );
            }

            return Column(
              children: [
                commandStrip,
                const SizedBox(height: AppSpacing.medium),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 7,
                      child: Column(
                        children: [
                          stations,
                          const SizedBox(height: AppSpacing.medium),
                          clientPreview,
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(flex: 5, child: mapAndFlow),
                  ],
                ),
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
            subtitle: 'تحديث المسار والمحطات',
          ),
          const SizedBox(height: AppSpacing.medium),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openStopDialog(
                context,
                onSubmit: (station) => cubit.addStation(station),
              ),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('إضافة محطة بالخريطة'),
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => cubit.showEditRoute(route),
              icon: const Icon(Icons.map_outlined),
              label: const Text('تعديل المسار الكامل'),
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

class _ClientRoutePreview extends StatelessWidget {
  final OperationRoute route;

  const _ClientRoutePreview({required this.route});

  @override
  Widget build(BuildContext context) {
    final pickups = route.stations.where((station) => station.pickupAllowed);
    final dropoffs = route.stations.where((station) => station.dropoffAllowed);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelTitle(
            icon: Icons.phone_iphone_outlined,
            title: 'معاينة تطبيق العميل',
            subtitle:
                'نقاط الصعود والنزول التي ستظهر للعميل حسب إعدادات المسار.',
          ),
          const SizedBox(height: AppSpacing.medium),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 900
                  ? 3
                  : constraints.maxWidth >= 620
                  ? 2
                  : 1;
              const gap = AppSpacing.medium;
              final width =
                  (constraints.maxWidth - (gap * (columns - 1))) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  SizedBox(
                    width: width,
                    child: _PreviewStopGroup(
                      icon: Icons.login_rounded,
                      title: 'نقاط الصعود',
                      stations: pickups.toList(),
                      emptyLabel: 'لا توجد نقاط صعود',
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _PreviewStopGroup(
                      icon: Icons.logout_rounded,
                      title: 'نقاط النزول',
                      stations: dropoffs.toList(),
                      emptyLabel: 'لا توجد نقاط نزول',
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _PreviewStopGroup(
                      icon: Icons.route_outlined,
                      title: 'ترتيب الرحلة',
                      stations: route.stations,
                      emptyLabel: 'أضف محطات لعرض الترتيب',
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
    final scheme = Theme.of(context).colorScheme;
    final center = LatLng(stations.first.latitude!, stations.first.longitude!);
    final line = stations
        .map((station) => LatLng(station.latitude!, station.longitude!))
        .toList();
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radius),
      child: SizedBox(
        height: 320,
        child: FlutterMap(
          options: MapOptions(initialCenter: center, initialZoom: 11),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.bmt.app',
            ),
            if (line.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(points: line, color: scheme.primary, strokeWidth: 5),
                ],
              ),
            MarkerLayer(
              markers: [
                for (final station in stations)
                  Marker(
                    point: LatLng(station.latitude!, station.longitude!),
                    width: 52,
                    height: 58,
                    child: Tooltip(
                      message: station.name,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 17,
                            backgroundColor: scheme.primary,
                            child: Text(
                              '${station.order}',
                              style: TextStyle(
                                color: scheme.onPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            color: scheme.primary,
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution('OpenStreetMap', onTap: () {}),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewStopGroup extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<RouteStation> stations;
  final String emptyLabel;

  const _PreviewStopGroup({
    required this.icon,
    required this.title,
    required this.stations,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(70),
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: scheme.outline.withAlpha(35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: scheme.primary),
                const SizedBox(width: AppSpacing.xSmall),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                StatusChip(label: '${stations.length}'),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            if (stations.isEmpty)
              Text(
                emptyLabel,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              )
            else
              ...stations.map(
                (station) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xSmall),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: scheme.primaryContainer,
                        child: Text(
                          '${station.order}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: scheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xSmall),
                      Expanded(
                        child: Text(
                          station.estimatedArrivalTime.isEmpty
                              ? station.name
                              : '${station.name} - ${station.estimatedArrivalTime}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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

class _StopsTimelinePanel extends StatelessWidget {
  final OperationRoute route;

  const _StopsTimelinePanel({required this.route});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('خط المحطات', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.medium),
          ...route.stations.indexed.map((entry) {
            final (index, station) = entry;
            final last = index == route.stations.length - 1;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: scheme.primaryContainer,
                      child: Text('${station.order}'),
                    ),
                    if (!last)
                      Container(
                        width: 2,
                        height: 76,
                        color: scheme.outline.withAlpha(120),
                      ),
                  ],
                ),
                const SizedBox(width: AppSpacing.medium),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xSmall),
                        Text(
                          'وصول ${station.arrivalOffset} - مغادرة ${station.departureOffset.isEmpty ? station.arrivalOffset : station.departureOffset}',
                        ),
                        const SizedBox(height: AppSpacing.xSmall),
                        Text(
                          station.locationDescription,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _StopManagementPanel extends StatelessWidget {
  final OperationRoute route;
  final ValueChanged<RouteStation> onAdd;
  final ValueChanged<RouteStation> onEdit;
  final ValueChanged<RouteStation> onDelete;
  final ReorderCallback onReorder;

  const _StopManagementPanel({
    required this.route,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 620;
              final title = _PanelTitle(
                icon: Icons.edit_location_alt_outlined,
                title: 'إدارة المحطات',
                subtitle: 'رتب نقاط المسار وحدد الصعود والنزول ومواقع الخريطة.',
              );
              final action = FilledButton.icon(
                onPressed: () => _openStopDialog(context, onSubmit: onAdd),
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('إضافة محطة'),
              );
              final count = StatusChip(label: '${route.stations.length} محطة');
              if (compact) {
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
            _StationsEmptyState(
              onAdd: () => _openStopDialog(context, onSubmit: onAdd),
            )
          else
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withAlpha(28),
                borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
                border: Border.all(color: scheme.outline.withAlpha(28)),
              ),
              child: ReorderableListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.all(AppSpacing.small),
                physics: const NeverScrollableScrollPhysics(),
                buildDefaultDragHandles: false,
                itemCount: route.stations.length,
                onReorder: onReorder,
                itemBuilder: (context, index) {
                  final station = route.stations[index];
                  return _StopManagementRow(
                    key: ValueKey(station.id),
                    station: station,
                    index: index,
                    onEdit: () => _openStopDialog(
                      context,
                      station: station,
                      onSubmit: onEdit,
                    ),
                    onDelete: () => onDelete(station),
                  );
                },
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
          Icon(
            Icons.add_location_alt_outlined,
            color: scheme.primary,
            size: 30,
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            'لا توجد محطات بعد',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xSmall),
          Text(
            'أضف نقاط الصعود والنزول من الخريطة حتى يصبح المسار جاهزاً لإنشاء الرحلات.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.medium),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('إضافة محطة'),
          ),
        ],
      ),
    );
  }
}

class _StopManagementRow extends StatelessWidget {
  final RouteStation station;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StopManagementRow({
    required this.station,
    required this.index,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.small),
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        border: Border.all(color: scheme.outline.withAlpha(45)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                station.name,
                maxLines: compact ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.xSmall),
              Text(
                station.locationDescription.isEmpty
                    ? station.area
                    : station.locationDescription,
                maxLines: compact ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          );
          final facts = Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.xSmall,
            children: [
              _RouteFactPill(
                icon: Icons.location_city_outlined,
                label: station.area.isEmpty ? 'غير محدد' : station.area,
              ),
              _RouteFactPill(
                icon: Icons.login_rounded,
                label: station.pickupAllowed ? 'صعود' : 'بدون صعود',
              ),
              _RouteFactPill(
                icon: Icons.logout_rounded,
                label: station.dropoffAllowed ? 'نزول' : 'بدون نزول',
              ),
              _RouteFactPill(
                icon: station.latitude == null || station.longitude == null
                    ? Icons.location_off_outlined
                    : Icons.location_on_outlined,
                label: station.latitude == null || station.longitude == null
                    ? 'بدون موقع'
                    : 'على الخريطة',
              ),
              _RouteFactPill(
                icon: Icons.schedule_outlined,
                label:
                    'وصول ${station.arrivalOffset} - مغادرة ${station.departureOffset.isEmpty ? station.arrivalOffset : station.departureOffset}',
              ),
            ],
          );
          final leading = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Icon(
                  Icons.drag_indicator_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              CircleAvatar(
                radius: 18,
                backgroundColor: scheme.primary,
                child: Text(
                  '${station.order}',
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          );
          final actions = Wrap(
            spacing: AppSpacing.xSmall,
            children: [
              IconButton.outlined(
                tooltip: 'تعديل المحطة',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton.outlined(
                tooltip: 'حذف المحطة',
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline, color: scheme.error),
              ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    leading,
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(child: title),
                    actions,
                  ],
                ),
                const SizedBox(height: AppSpacing.small),
                facts,
              ],
            );
          }
          return Row(
            children: [
              leading,
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: AppSpacing.small),
                    facts,
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _RouteSuccessView extends StatelessWidget {
  final OperationRoute route;

  const _RouteSuccessView({required this.route});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RoutesCubit>();
    final scheme = Theme.of(context).colorScheme;
    final located = _locatedStations(route);
    return Center(
      child: SizedBox(
        width: 720,
        child: AppCard(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: scheme.primaryContainer,
                child: Icon(
                  Icons.check_rounded,
                  color: scheme.primary,
                  size: 38,
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              Text(
                'تم إنشاء المسار',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.small),
              Text(route.name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.medium),
              Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                alignment: WrapAlignment.center,
                children: [
                  _RouteFactPill(
                    icon: Icons.signpost_outlined,
                    label: '${route.stations.length} محطات',
                  ),
                  _RouteFactPill(
                    icon: Icons.map_outlined,
                    label: '$located/${route.stations.length} على الخريطة',
                  ),
                  _RouteFactPill(
                    icon: Icons.schedule_outlined,
                    label: route.duration.isEmpty
                        ? 'مدة غير محددة'
                        : route.duration,
                  ),
                  _RouteFactPill(
                    icon: Icons.health_and_safety_outlined,
                    label: _routeReadinessLabel(route),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.large),
              Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: [
                  FilledButton.icon(
                    onPressed: () => cubit.showDetails(route),
                    icon: const Icon(Icons.dashboard_outlined),
                    label: const Text('إدارة المسار'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => cubit.showEditRoute(route),
                    icon: const Icon(Icons.edit_location_alt_outlined),
                    label: const Text('تعديل بالخريطة'),
                  ),
                  OutlinedButton.icon(
                    onPressed: cubit.showOperations,
                    icon: const Icon(Icons.list_alt_outlined),
                    label: const Text('العودة للقائمة'),
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
    builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
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

void _openStopDialog(
  BuildContext context, {
  RouteStation? station,
  required ValueChanged<RouteStation> onSubmit,
}) {
  showDialog<void>(
    context: context,
    builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: _StopDialog(station: station, onSubmit: onSubmit),
    ),
  );
}

class _StopDialog extends StatefulWidget {
  final RouteStation? station;
  final ValueChanged<RouteStation> onSubmit;

  const _StopDialog({this.station, required this.onSubmit});

  @override
  State<_StopDialog> createState() => _StopDialogState();
}

class _StopDialogState extends State<_StopDialog> {
  final _dialogFormKey = GlobalKey<FormState>();
  late final SearchPlacesUseCase _searchPlaces;
  late final MapController _mapController;
  late final TextEditingController _name;
  late final TextEditingController _area;
  late final TextEditingController _arrival;
  late final TextEditingController _departure;
  late final TextEditingController _location;
  late final TextEditingController _latitude;
  late final TextEditingController _longitude;
  LatLng? _selectedPoint;
  late bool _pickupAllowed;
  late bool _dropoffAllowed;

  @override
  void initState() {
    super.initState();
    final station = widget.station;
    _searchPlaces = dashboardDi<SearchPlacesUseCase>();
    _mapController = MapController();
    _name = TextEditingController(text: station?.name ?? '');
    _area = TextEditingController(text: station?.area ?? '');
    _arrival = TextEditingController(text: station?.arrivalOffset ?? '');
    _departure = TextEditingController(text: station?.departureOffset ?? '');
    _location = TextEditingController(text: station?.locationDescription ?? '');
    _latitude = TextEditingController(
      text: station?.latitude?.toString() ?? '',
    );
    _longitude = TextEditingController(
      text: station?.longitude?.toString() ?? '',
    );
    if (station?.latitude != null && station?.longitude != null) {
      _selectedPoint = LatLng(station!.latitude!, station.longitude!);
    }
    _pickupAllowed = station?.pickupAllowed ?? true;
    _dropoffAllowed = station?.dropoffAllowed ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _area.dispose();
    _arrival.dispose();
    _departure.dispose();
    _location.dispose();
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  void _setPoint(LatLng point, {bool moveMap = false}) {
    setState(() {
      _selectedPoint = point;
      _latitude.text = point.latitude.toStringAsFixed(6);
      _longitude.text = point.longitude.toStringAsFixed(6);
    });
    if (moveMap) {
      _mapController.move(point, 15);
    }
  }

  void _applyPlace(GeoPlace place) {
    final point = LatLng(place.point.lat, place.point.lng);
    setState(() {
      if (_name.text.trim().isEmpty) _name.text = place.label;
      _area.text = _areaFromLabel(place.label);
      _location.text = place.label;
    });
    _setPoint(point, moveMap: true);
  }

  String _areaFromLabel(String label) {
    final parts = label
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length >= 2) return parts[parts.length - 2];
    return label.trim();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.station == null ? 'إضافة محطة' : 'تعديل محطة'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Form(
            key: _dialogFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_searchPlaces.enabled) ...[
                  PlaceSearchField(
                    label: 'ابحث عن المحطة على الخريطة',
                    initialText:
                        widget.station?.locationDescription ??
                        widget.station?.name ??
                        '',
                    searchPlaces: _searchPlaces,
                    focus: _selectedPoint == null
                        ? null
                        : GeoPoint(
                            _selectedPoint!.latitude,
                            _selectedPoint!.longitude,
                          ),
                    onSelected: _applyPlace,
                  ),
                  const SizedBox(height: AppSpacing.small),
                ],
                _StationMapPicker(
                  controller: _mapController,
                  point: _selectedPoint,
                  onChanged: _setPoint,
                ),
                const SizedBox(height: AppSpacing.small),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'اسم المحطة'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'يرجى إدخال اسم المحطة'
                      : null,
                ),
                const SizedBox(height: AppSpacing.small),
                TextFormField(
                  controller: _area,
                  decoration: const InputDecoration(
                    labelText: 'ترتيب / منطقة المحطة',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'يرجى إدخال منطقة المحطة'
                      : null,
                ),
                const SizedBox(height: AppSpacing.small),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _arrival,
                        decoration: const InputDecoration(
                          labelText: 'وقت الوصول (مثال: ١٥ دقيقة)',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'يرجى إدخال وقت الوصول'
                            : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(
                      child: TextFormField(
                        controller: _departure,
                        decoration: const InputDecoration(
                          labelText: 'وقت المغادرة (مثال: ١٨ دقيقة)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.small),
                TextFormField(
                  controller: _location,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'وصف الموقع'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'يرجى إدخال وصف الموقع'
                      : null,
                ),
                const SizedBox(height: AppSpacing.small),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latitude,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        inputFormatters: FleetInputFormatters.signedDecimal,
                        decoration: const InputDecoration(
                          labelText: 'خط العرض',
                        ),
                        validator: (value) => _coordinateValidator(
                          value,
                          label: 'خط العرض',
                          min: -90,
                          max: 90,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(
                      child: TextFormField(
                        controller: _longitude,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        inputFormatters: FleetInputFormatters.signedDecimal,
                        decoration: const InputDecoration(
                          labelText: 'خط الطول',
                        ),
                        validator: (value) => _coordinateValidator(
                          value,
                          label: 'خط الطول',
                          min: -180,
                          max: 180,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.small),
                CheckboxListTile(
                  value: _pickupAllowed,
                  onChanged: (value) {
                    setState(() => _pickupAllowed = value ?? true);
                  },
                  title: const Text('يسمح بالصعود من هذه المحطة'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                CheckboxListTile(
                  value: _dropoffAllowed,
                  onChanged: (value) {
                    setState(() => _dropoffAllowed = value ?? true);
                  },
                  title: const Text('يسمح بالنزول في هذه المحطة'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                if (!_pickupAllowed && !_dropoffAllowed)
                  Text(
                    'يجب أن تكون المحطة صعوداً أو نزولاً على الأقل.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
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
            if (_dialogFormKey.currentState?.validate() != true) return;
            if (!_pickupAllowed && !_dropoffAllowed) return;
            final existing = widget.station;
            widget.onSubmit(
              RouteStation(
                id: existing?.id ?? '',
                name: _name.text.trim(),
                area: _area.text.trim(),
                arrivalOffset: _arrival.text.trim(),
                departureOffset: _departure.text.trim().isEmpty
                    ? _arrival.text.trim()
                    : _departure.text.trim(),
                locationDescription: _location.text.trim(),
                latitude: double.tryParse(_latitude.text.trim()),
                longitude: double.tryParse(_longitude.text.trim()),
                pickupAllowed: _pickupAllowed,
                dropoffAllowed: _dropoffAllowed,
                estimatedArrivalTime: _arrival.text.trim(),
                notes: existing?.notes ?? '',
                order: existing?.order ?? 0,
              ),
            );
            Navigator.of(context).pop();
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }

  String? _coordinateValidator(
    String? value, {
    required String label,
    required double min,
    required double max,
  }) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final parsed = double.tryParse(trimmed);
    if (parsed == null) return '$label يجب أن يكون رقماً صحيحاً';
    if (parsed < min || parsed > max) {
      return '$label يجب أن يكون بين $min و $max';
    }
    return null;
  }
}

class _StationMapPicker extends StatelessWidget {
  final MapController controller;
  final LatLng? point;
  final ValueChanged<LatLng> onChanged;

  const _StationMapPicker({
    required this.controller,
    required this.point,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final center = point ?? const LatLng(30.0444, 31.2357);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radius),
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            FlutterMap(
              mapController: controller,
              options: MapOptions(
                initialCenter: center,
                initialZoom: point == null ? 10 : 15,
                onTap: (_, latLng) => onChanged(latLng),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.bmt.app',
                ),
                if (point != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: point!,
                        width: 48,
                        height: 48,
                        child: Icon(
                          Icons.location_on_rounded,
                          color: scheme.error,
                          size: 42,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            Positioned(
              top: 10,
              left: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surface.withAlpha(230),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: scheme.outline.withAlpha(90)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.small,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.touch_app_outlined,
                        size: 16,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'اضغط على الخريطة لتحديد المحطة',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
