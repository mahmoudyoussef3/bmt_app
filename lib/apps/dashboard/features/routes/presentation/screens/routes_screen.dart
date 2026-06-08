import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_button.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import '../../domain/entities/operation_route.dart';
import '../cubit/routes_cubit.dart';
import '../cubit/routes_state.dart';
import '../widgets/route_builder_view.dart';
import '../widgets/route_card.dart';
import '../widgets/route_timeline.dart';
import '../widgets/station_form_dialog.dart';
import '../widgets/stations_manager.dart';

class RoutesScreen extends StatelessWidget {
  const RoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutesCubit, RoutesState>(
      builder: (context, state) {
        return switch (state) {
          RoutesLoading() => const Center(child: CircularProgressIndicator()),
          RoutesError(:final message) => _RoutesError(message: message),
          RoutesLoaded() => _RoutesLoadedView(state: state),
        };
      },
    );
  }
}

class _RoutesLoadedView extends StatelessWidget {
  final RoutesLoaded state;

  const _RoutesLoadedView({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RoutesCubit>();
    return switch (state.view) {
      RoutesView.builder => RouteBuilderView(
        route: state.editingRoute,
        onSubmit: cubit.saveRoute,
        onCancel: cubit.showOperations,
      ),
      RoutesView.operations => _RoutesOperationsView(state: state),
    };
  }
}

class _RoutesOperationsView extends StatelessWidget {
  final RoutesLoaded state;

  const _RoutesOperationsView({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RoutesCubit>();
    final scheme = Theme.of(context).colorScheme;
    final selected = state.selectedRoute;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        AppCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'عمليات المسارات',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.xSmall),
                    Text(
                      'اختيار مسار، معاينة الرحلة، وترتيب المحطات بأسلوب بصري.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              AppButton(
                label: 'بناء مسار جديد',
                height: 40,
                onPressed: cubit.showBuilder,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.large),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 1050;
            final list = _RouteList(
              routes: state.routes,
              selectedRouteId: selected.id,
              onSelected: cubit.selectRoute,
            );
            final preview = _RoutePreview(
              route: selected,
              onEditRoute: () => cubit.showEditRoute(selected),
              onDuplicateRoute: () => cubit.duplicateRoute(selected),
              onArchiveRoute: () => cubit.archiveRoute(selected),
              onReorder: cubit.reorderStations,
              onAddStation: () => _openStationDialog(context),
              onEditStation: (station) =>
                  _openStationDialog(context, station: station),
              onDeleteStation: cubit.deleteStation,
            );

            if (compact) {
              return Column(
                children: [
                  list,
                  const SizedBox(height: AppSpacing.medium),
                  preview,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 360, child: list),
                const SizedBox(width: AppSpacing.medium),
                Expanded(child: preview),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _RouteList extends StatelessWidget {
  final List<OperationRoute> routes;
  final String selectedRouteId;
  final ValueChanged<String> onSelected;

  const _RouteList({
    required this.routes,
    required this.selectedRouteId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final activeRoutes = routes
        .where((route) => route.status != OperationRouteStatus.archived)
        .toList();
    final archivedRoutes = routes
        .where((route) => route.status == OperationRouteStatus.archived)
        .toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('رحلات التشغيل', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.medium),
          ...activeRoutes.map(
            (route) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.medium),
              child: RouteCard(
                route: route,
                selected: route.id == selectedRouteId,
                onTap: () => onSelected(route.id),
              ),
            ),
          ),
          if (archivedRoutes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.small),
            Text('الأرشيف', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.medium),
            ...archivedRoutes.map(
              (route) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.medium),
                child: RouteCard(
                  route: route,
                  selected: route.id == selectedRouteId,
                  onTap: () => onSelected(route.id),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoutePreview extends StatelessWidget {
  final OperationRoute route;
  final VoidCallback onEditRoute;
  final VoidCallback onDuplicateRoute;
  final VoidCallback onArchiveRoute;
  final ReorderCallback onReorder;
  final VoidCallback onAddStation;
  final ValueChanged<RouteStation> onEditStation;
  final ValueChanged<RouteStation> onDeleteStation;

  const _RoutePreview({
    required this.route,
    required this.onEditRoute,
    required this.onDuplicateRoute,
    required this.onArchiveRoute,
    required this.onReorder,
    required this.onAddStation,
    required this.onEditStation,
    required this.onDeleteStation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _JourneyHeader(
          route: route,
          onEditRoute: onEditRoute,
          onDuplicateRoute: onDuplicateRoute,
          onArchiveRoute: onArchiveRoute,
        ),
        const SizedBox(height: AppSpacing.medium),
        RouteTimeline(route: route),
        const SizedBox(height: AppSpacing.medium),
        StationsManager(
          route: route,
          onReorder: onReorder,
          onAddStation: onAddStation,
          onEditStation: onEditStation,
          onDeleteStation: onDeleteStation,
        ),
      ],
    );
  }
}

class _JourneyHeader extends StatelessWidget {
  final OperationRoute route;
  final VoidCallback onEditRoute;
  final VoidCallback onDuplicateRoute;
  final VoidCallback onArchiveRoute;

  const _JourneyHeader({
    required this.route,
    required this.onEditRoute,
    required this.onDuplicateRoute,
    required this.onArchiveRoute,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.xSmall),
                    Text(
                      '${route.startCity} ← ${route.endCity} • ${route.duration} • ${route.distance}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: [
                  AppButton(
                    label: 'تعديل',
                    height: 40,
                    outline: true,
                    onPressed: onEditRoute,
                  ),
                  AppButton(
                    label: 'نسخ',
                    height: 40,
                    outline: true,
                    onPressed: onDuplicateRoute,
                  ),
                  if (route.status != OperationRouteStatus.archived)
                    AppButton(
                      label: 'أرشفة',
                      height: 40,
                      outline: true,
                      onPressed: onArchiveRoute,
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          Container(
            height: 190,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Center(
                    child: Icon(
                      Icons.alt_route_outlined,
                      size: 72,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Positioned(
                  right: 28,
                  top: 28,
                  child: _MapPill(label: route.startCity),
                ),
                Positioned(
                  left: 28,
                  bottom: 28,
                  child: _MapPill(label: route.endCity),
                ),
                Positioned(
                  right: 120,
                  bottom: 48,
                  child: _MapPill(label: '${route.stations.length} محطات'),
                ),
              ],
            ),
          ),
          if (route.notes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.medium),
            Text(route.notes.join(' • ')),
          ],
        ],
      ),
    );
  }
}

class _MapPill extends StatelessWidget {
  final String label;

  const _MapPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.small,
          vertical: AppSpacing.xSmall,
        ),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: scheme.onPrimaryContainer),
        ),
      ),
    );
  }
}

class _RoutesError extends StatelessWidget {
  final String message;

  const _RoutesError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: AppSpacing.medium),
            AppButton(
              label: 'إعادة المحاولة',
              onPressed: () => context.read<RoutesCubit>().load(),
            ),
          ],
        ),
      ),
    );
  }
}

void _openStationDialog(BuildContext context, {RouteStation? station}) {
  showDialog<void>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: context.read<RoutesCubit>(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: StationFormDialog(
          station: station,
          onSubmit: (value) {
            final cubit = context.read<RoutesCubit>();
            if (station == null) {
              cubit.addStation(value);
            } else {
              cubit.updateStation(value);
            }
          },
        ),
      ),
    ),
  );
}
