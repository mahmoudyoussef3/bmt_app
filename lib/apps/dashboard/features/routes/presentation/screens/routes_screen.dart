import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../domain/entities/operation_route.dart';
import '../cubit/routes_cubit.dart';
import '../cubit/routes_state.dart';

class RoutesScreen extends StatelessWidget {
  const RoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutesCubit, RoutesState>(
      builder: (context, state) {
        return switch (state) {
          RoutesLoading() => const Center(child: CircularProgressIndicator()),
          RoutesError(:final message) => _RoutesError(message: message),
          RoutesLoaded() => switch (state.view) {
            RoutesView.list => _RoutesListView(state: state),
            RoutesView.details => _RouteDetailsView(state: state),
            RoutesView.form => _RouteFormView(route: state.editingRoute),
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
        const SizedBox(height: AppSpacing.large),
        _RoutesTable(
          routes: state.filteredRoutes,
          onView: cubit.showDetails,
          onEdit: cubit.showEditRoute,
          onPause: cubit.pauseRoute,
          onArchive: (route) => _confirmArchive(context, route),
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
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'إدارة المسارات',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.xSmall),
                    Text(
                      'مسارات ثابتة يتم استخدامها لاحقاً في إنشاء الرحلات.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: cubit.showBuilder,
                icon: const Icon(Icons.add_rounded),
                label: const Text('إضافة مسار'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 980;
              final search = TextField(
                onChanged: cubit.updateSearch,
                textDirection: TextDirection.rtl,
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

              if (compact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    search,
                    const SizedBox(height: AppSpacing.small),
                    filters,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(flex: 2, child: search),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(flex: 3, child: filters),
                ],
              );
            },
          ),
        ],
      ),
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
      width: 170,
      child: DropdownButtonFormField<OperationRouteStatus?>(
        initialValue: state.statusFilter,
        decoration: const InputDecoration(labelText: 'الحالة'),
        items: [
          const DropdownMenuItem(value: null, child: Text('كل الحالات')),
          ...OperationRouteStatus.values
              .where((status) => status != OperationRouteStatus.draft)
              .map(
                (status) =>
                    DropdownMenuItem(value: status, child: Text(status.label)),
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
      width: 190,
      child: DropdownButtonFormField<String>(
        initialValue: state.cityFilter,
        decoration: const InputDecoration(labelText: 'المدينة'),
        items: state.cityOptions
            .map((city) => DropdownMenuItem(value: city, child: Text(city)))
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
      width: 180,
      child: DropdownButtonFormField<StopsCountFilter>(
        initialValue: state.stopsFilter,
        decoration: const InputDecoration(labelText: 'عدد المحطات'),
        items: StopsCountFilter.values
            .map(
              (filter) =>
                  DropdownMenuItem(value: filter, child: Text(filter.label)),
            )
            .toList(),
        onChanged: (value) =>
            cubit.updateStopsFilter(value ?? StopsCountFilter.all),
      ),
    );
  }
}

class _RoutesTable extends StatelessWidget {
  final List<OperationRoute> routes;
  final ValueChanged<OperationRoute> onView;
  final ValueChanged<OperationRoute> onEdit;
  final ValueChanged<OperationRoute> onPause;
  final ValueChanged<OperationRoute> onArchive;

  const _RoutesTable({
    required this.routes,
    required this.onView,
    required this.onEdit,
    required this.onPause,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 1180,
          child: Column(
            children: [
              _TableHeader(
                columns: const [
                  'اسم المسار',
                  'نقطة البداية',
                  'نقطة النهاية',
                  'المحطات',
                  'المدة',
                  'رحلات نشطة',
                  'الحالة',
                  'إجراءات',
                ],
              ),
              if (routes.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.large),
                  child: Text(
                    'لا توجد مسارات مطابقة للفلاتر الحالية',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ...routes.map(
                  (route) => _RouteTableRow(
                    route: route,
                    onView: () => onView(route),
                    onEdit: () => onEdit(route),
                    onPause: () => onPause(route),
                    onArchive: () => onArchive(route),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final List<String> columns;

  const _TableHeader({required this.columns});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      color: scheme.surfaceContainerHighest.withAlpha(90),
      child: Row(
        children: columns
            .map(
              (column) => Expanded(
                child: Text(
                  column,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _RouteTableRow extends StatelessWidget {
  final OperationRoute route;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onPause;
  final VoidCallback onArchive;

  const _RouteTableRow({
    required this.route,
    required this.onView,
    required this.onEdit,
    required this.onPause,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outline.withAlpha(90))),
      ),
      child: Row(
        children: [
          Expanded(child: Text(route.name)),
          Expanded(child: Text(route.startCity)),
          Expanded(child: Text(route.endCity)),
          Expanded(child: Text('${route.stations.length}')),
          Expanded(child: Text(route.duration)),
          Expanded(child: Text('${route.tripsCount}')),
          Expanded(child: StatusChip(label: route.status.label)),
          Expanded(
            child: Wrap(
              spacing: AppSpacing.xSmall,
              runSpacing: AppSpacing.xSmall,
              children: [
                TextButton(onPressed: onView, child: const Text('عرض')),
                TextButton(onPressed: onEdit, child: const Text('تعديل')),
                TextButton(
                  onPressed: route.status == OperationRouteStatus.archived
                      ? null
                      : onPause,
                  child: const Text('إيقاف'),
                ),
                TextButton(
                  onPressed: route.status == OperationRouteStatus.archived
                      ? null
                      : onArchive,
                  child: const Text('أرشفة'),
                ),
              ],
            ),
          ),
        ],
      ),
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
        const SizedBox(height: AppSpacing.large),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 1040;
            final info = _BasicInfoPanel(route: route);
            final stats = _StatsPanel(route: route);
            if (compact) {
              return Column(
                children: [
                  info,
                  const SizedBox(height: AppSpacing.medium),
                  stats,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: info),
                const SizedBox(width: AppSpacing.medium),
                Expanded(flex: 2, child: stats),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.large),
        _StopsTimelinePanel(route: route),
        const SizedBox(height: AppSpacing.large),
        _StopManagementPanel(
          route: route,
          onAdd: (station) => cubit.addStation(station),
          onEdit: (station) => cubit.updateStation(station),
          onDelete: cubit.deleteStation,
          onReorder: cubit.reorderStations,
        ),
        const SizedBox(height: AppSpacing.large),
        _ActiveTripsPanel(route: route),
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
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Row(
        children: [
          Icon(Icons.alt_route_rounded, color: scheme.primary, size: 34),
          const SizedBox(width: AppSpacing.medium),
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
                  '${route.startCity} ← ${route.endCity} - ${route.duration} - ${route.distance}',
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
              OutlinedButton.icon(
                onPressed: cubit.showOperations,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('رجوع'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => cubit.showEditRoute(route),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('تعديل'),
              ),
              OutlinedButton.icon(
                onPressed: route.status == OperationRouteStatus.archived
                    ? null
                    : () => _confirmArchive(context, route),
                icon: const Icon(Icons.archive_outlined),
                label: const Text('أرشفة'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BasicInfoPanel extends StatelessWidget {
  final OperationRoute route;

  const _BasicInfoPanel({required this.route});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'البيانات الأساسية',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.medium),
          _InfoGrid(
            items: [
              ('اسم المسار', route.name),
              ('نقطة البداية', route.startCity),
              ('نقطة النهاية', route.endCity),
              ('المدة', route.duration),
              ('المسافة', route.distance),
              ('الحالة', route.status.label),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsPanel extends StatelessWidget {
  final OperationRoute route;

  const _StatsPanel({required this.route});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'إحصائيات التشغيل',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.medium),
          _InfoGrid(
            items: [
              ('عدد الرحلات', '${route.statistics.tripsCount}'),
              ('عدد الحجوزات', '${route.statistics.bookingsCount}'),
              ('متوسط الإشغال', route.statistics.averageOccupancy),
              ('إجمالي المشتركين', '${route.statistics.subscribersCount}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final List<(String, String)> items;

  const _InfoGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.medium,
            mainAxisSpacing: AppSpacing.medium,
            mainAxisExtent: 64,
          ),
          itemBuilder: (context, index) {
            final (label, value) = items[index];
            return DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withAlpha(70),
                borderRadius: BorderRadius.circular(AppTokens.radius),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.small),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Text(value, style: Theme.of(context).textTheme.titleSmall),
                  ],
                ),
              ),
            );
          },
        );
      },
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
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'إدارة المحطات',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              FilledButton.icon(
                onPressed: () => _openStopDialog(context, onSubmit: onAdd),
                icon: const Icon(Icons.add_rounded),
                label: const Text('إضافة محطة'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          ReorderableListView.builder(
            shrinkWrap: true,
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
      padding: const EdgeInsets.all(AppSpacing.small),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(60),
        borderRadius: BorderRadius.circular(AppTokens.radius),
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            index: index,
            child: const Icon(Icons.drag_handle_rounded),
          ),
          const SizedBox(width: AppSpacing.small),
          CircleAvatar(radius: 15, child: Text('${station.order}')),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  station.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xSmall),
                Text(
                  '${station.area} - وصول ${station.arrivalOffset} - مغادرة ${station.departureOffset}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'تعديل',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'حذف',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _ActiveTripsPanel extends StatelessWidget {
  final OperationRoute route;

  const _ActiveTripsPanel({required this.route});

  @override
  Widget build(BuildContext context) {
    return _SimpleTablePanel(
      title: 'الرحلات النشطة على المسار',
      headers: const [
        'رقم الرحلة',
        'السائق',
        'المركبة',
        'عدد الركاب',
        'الحالة',
      ],
      rows: route.activeTrips
          .map(
            (trip) => [
              trip.tripNumber,
              trip.driver,
              trip.vehicle,
              '${trip.passengersCount}',
              trip.status,
            ],
          )
          .toList(),
    );
  }
}

class _SimpleTablePanel extends StatelessWidget {
  final String title;
  final List<String> headers;
  final List<List<String>> rows;

  const _SimpleTablePanel({
    required this.title,
    required this.headers,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.medium),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 920,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.small),
                    color: scheme.surfaceContainerHighest.withAlpha(90),
                    child: Row(
                      children: headers
                          .map(
                            (header) => Expanded(
                              child: Text(
                                header,
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  ...rows.map(
                    (row) => Container(
                      padding: const EdgeInsets.all(AppSpacing.small),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: scheme.outline.withAlpha(90)),
                        ),
                      ),
                      child: Row(
                        children: row
                            .map((cell) => Expanded(child: Text(cell)))
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteFormView extends StatefulWidget {
  final OperationRoute? route;

  const _RouteFormView({this.route});

  @override
  State<_RouteFormView> createState() => _RouteFormViewState();
}

class _RouteFormViewState extends State<_RouteFormView> {
  late final TextEditingController _name;
  late final TextEditingController _start;
  late final TextEditingController _end;
  late final TextEditingController _duration;
  late final TextEditingController _distance;
  late List<RouteStation> _stations;
  late OperationRouteStatus _status;
  int _step = 0;

  bool get _isEditing => widget.route != null;

  @override
  void initState() {
    super.initState();
    final route = widget.route;
    _name = TextEditingController(text: route?.name ?? '');
    _start = TextEditingController(text: route?.startCity ?? '');
    _end = TextEditingController(text: route?.endCity ?? '');
    _duration = TextEditingController(text: route?.duration ?? '');
    _distance = TextEditingController(text: route?.distance ?? '');
    _stations =
        route?.stations.map((station) => station.copyWith()).toList() ??
        [
          const RouteStation(
            id: 'draft-start',
            name: 'نقطة الانطلاق',
            area: 'القاهرة',
            arrivalOffset: '٠ دقيقة',
            departureOffset: '٣ دقائق',
            locationDescription: 'نقطة تجمع بداية المسار',
            order: 1,
          ),
          const RouteStation(
            id: 'draft-end',
            name: 'نقطة الوصول',
            area: 'القاهرة',
            arrivalOffset: '٦٠ دقيقة',
            departureOffset: '٦٠ دقيقة',
            locationDescription: 'نقطة نهاية المسار',
            order: 2,
          ),
        ];
    _status = route?.status == OperationRouteStatus.archived
        ? OperationRouteStatus.paused
        : route?.status ?? OperationRouteStatus.active;
  }

  @override
  void dispose() {
    _name.dispose();
    _start.dispose();
    _end.dispose();
    _duration.dispose();
    _distance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RoutesCubit>();
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        _FormHeader(isEditing: _isEditing),
        const SizedBox(height: AppSpacing.large),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Stepper(
            currentStep: _step,
            onStepTapped: (step) => setState(() => _step = step),
            controlsBuilder: (context, details) => const SizedBox.shrink(),
            steps: [
              Step(
                title: const Text('البيانات الأساسية'),
                isActive: _step == 0,
                content: _BasicInfoForm(
                  name: _name,
                  start: _start,
                  end: _end,
                  duration: _duration,
                  distance: _distance,
                  status: _status,
                  onStatusChanged: (status) => setState(() => _status = status),
                ),
              ),
              Step(
                title: const Text('المحطات'),
                isActive: _step == 1,
                content: _StopsFormEditor(
                  stations: _stations,
                  onChanged: (stations) => setState(() => _stations = stations),
                ),
              ),
              Step(
                title: const Text('المراجعة'),
                isActive: _step == 2,
                content: _RouteReview(route: _buildRoute()),
              ),
              Step(
                title: const Text('إنشاء المسار'),
                isActive: _step == 3,
                content: _FinalCreateStep(isEditing: _isEditing),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        Row(
          children: [
            OutlinedButton(
              onPressed: cubit.showOperations,
              child: const Text('إلغاء'),
            ),
            const Spacer(),
            if (_step > 0)
              TextButton(
                onPressed: () => setState(() => _step -= 1),
                child: const Text('السابق'),
              ),
            const SizedBox(width: AppSpacing.small),
            FilledButton(
              onPressed: _step == 3
                  ? () => cubit.saveRoute(_buildRoute())
                  : () => setState(() => _step += 1),
              child: Text(
                _step == 3
                    ? (_isEditing ? 'حفظ التعديل' : 'إنشاء المسار')
                    : 'التالي',
              ),
            ),
          ],
        ),
      ],
    );
  }

  OperationRoute _buildRoute() {
    final existing = widget.route;
    final activeTrips = existing?.activeTrips ?? const <RouteActiveTrip>[];
    final packages = existing?.packages ?? const <RoutePackage>[];
    return OperationRoute(
      id: existing?.id ?? '',
      name: _name.text.trim().isEmpty ? 'مسار جديد' : _name.text.trim(),
      startCity: _start.text.trim().isEmpty ? 'نقطة بداية' : _start.text.trim(),
      endCity: _end.text.trim().isEmpty ? 'نقطة نهاية' : _end.text.trim(),
      duration: _duration.text.trim().isEmpty
          ? 'غير محدد'
          : _duration.text.trim(),
      distance: _distance.text.trim().isEmpty
          ? 'غير محدد'
          : _distance.text.trim(),
      tripsCount: existing?.tripsCount ?? activeTrips.length,
      activePackagesCount: packages.length,
      status: _status,
      stations: _normalize(_stations),
      activeTrips: activeTrips,
      packages: packages,
      statistics:
          existing?.statistics ??
          const RouteStatistics(
            tripsCount: 0,
            bookingsCount: 0,
            averageOccupancy: '٠٪',
            subscribersCount: 0,
          ),
      notes: existing?.notes ?? const ['تم إنشاء المسار من مركز التشغيل'],
    );
  }
}

class _FormHeader extends StatelessWidget {
  final bool isEditing;

  const _FormHeader({required this.isEditing});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isEditing ? 'تعديل مسار' : 'إضافة مسار جديد',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          OutlinedButton.icon(
            onPressed: context.read<RoutesCubit>().showOperations,
            icon: const Icon(Icons.close_rounded),
            label: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}

class _BasicInfoForm extends StatelessWidget {
  final TextEditingController name;
  final TextEditingController start;
  final TextEditingController end;
  final TextEditingController duration;
  final TextEditingController distance;
  final OperationRouteStatus status;
  final ValueChanged<OperationRouteStatus> onStatusChanged;

  const _BasicInfoForm({
    required this.name,
    required this.start,
    required this.end,
    required this.duration,
    required this.distance,
    required this.status,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _FormGrid(
      children: [
        TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'اسم المسار'),
        ),
        TextField(
          controller: start,
          decoration: const InputDecoration(labelText: 'نقطة البداية'),
        ),
        TextField(
          controller: end,
          decoration: const InputDecoration(labelText: 'نقطة النهاية'),
        ),
        TextField(
          controller: duration,
          decoration: const InputDecoration(labelText: 'المدة'),
        ),
        TextField(
          controller: distance,
          decoration: const InputDecoration(labelText: 'المسافة'),
        ),
        DropdownButtonFormField<OperationRouteStatus>(
          initialValue: status,
          decoration: const InputDecoration(labelText: 'الحالة'),
          items: const [
            DropdownMenuItem(
              value: OperationRouteStatus.active,
              child: Text('نشط'),
            ),
            DropdownMenuItem(
              value: OperationRouteStatus.paused,
              child: Text('متوقف'),
            ),
          ],
          onChanged: (value) =>
              onStatusChanged(value ?? OperationRouteStatus.active),
        ),
      ],
    );
  }
}

class _FormGrid extends StatelessWidget {
  final List<Widget> children;

  const _FormGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.medium,
            mainAxisSpacing: AppSpacing.medium,
            mainAxisExtent: 72,
          ),
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

class _StopsFormEditor extends StatelessWidget {
  final List<RouteStation> stations;
  final ValueChanged<List<RouteStation>> onChanged;

  const _StopsFormEditor({required this.stations, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => _openStopDialog(
              context,
              onSubmit: (station) => onChanged(
                _normalize([
                  ...stations,
                  station.copyWith(id: 'draft-${stations.length + 1}'),
                ]),
              ),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('إضافة محطة'),
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: stations.length,
          onReorder: (oldIndex, newIndex) {
            final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
            final next = [...stations];
            final station = next.removeAt(oldIndex);
            next.insert(adjusted, station);
            onChanged(_normalize(next));
          },
          itemBuilder: (context, index) {
            final station = stations[index];
            return _StopManagementRow(
              key: ValueKey(station.id),
              station: station,
              index: index,
              onEdit: () => _openStopDialog(
                context,
                station: station,
                onSubmit: (updated) => onChanged(
                  _normalize(
                    stations
                        .map((item) => item.id == station.id ? updated : item)
                        .toList(),
                  ),
                ),
              ),
              onDelete: () => onChanged(
                _normalize(
                  stations.where((item) => item.id != station.id).toList(),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RouteReview extends StatelessWidget {
  final OperationRoute route;

  const _RouteReview({required this.route});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoGrid(
          items: [
            ('اسم المسار', route.name),
            ('البداية', route.startCity),
            ('النهاية', route.endCity),
            ('المدة', route.duration),
            ('المسافة', route.distance),
            ('عدد المحطات', '${route.stations.length}'),
          ],
        ),
        const SizedBox(height: AppSpacing.medium),
        _StopsTimelinePanel(route: route),
      ],
    );
  }
}

class _FinalCreateStep extends StatelessWidget {
  final bool isEditing;

  const _FinalCreateStep({required this.isEditing});

  @override
  Widget build(BuildContext context) {
    return Text(
      isEditing
          ? 'راجع البيانات ثم احفظ التعديل لتحديث المسار في الحالة المحلية.'
          : 'راجع البيانات ثم أنشئ المسار. سيظهر فوراً في قائمة المسارات.',
      style: Theme.of(context).textTheme.bodyMedium,
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
    return Center(
      child: SizedBox(
        width: 620,
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
              const SizedBox(height: AppSpacing.large),
              Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: [
                  FilledButton(
                    onPressed: () => cubit.showDetails(route),
                    child: const Text('عرض التفاصيل'),
                  ),
                  OutlinedButton(
                    onPressed: cubit.showOperations,
                    child: const Text('العودة للقائمة'),
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

class _RoutesError extends StatelessWidget {
  final String message;

  const _RoutesError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message),
            const SizedBox(height: AppSpacing.medium),
            FilledButton(
              onPressed: () => context.read<RoutesCubit>().load(),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
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
  late final TextEditingController _name;
  late final TextEditingController _area;
  late final TextEditingController _arrival;
  late final TextEditingController _departure;
  late final TextEditingController _location;

  @override
  void initState() {
    super.initState();
    final station = widget.station;
    _name = TextEditingController(text: station?.name ?? '');
    _area = TextEditingController(text: station?.area ?? '');
    _arrival = TextEditingController(text: station?.arrivalOffset ?? '');
    _departure = TextEditingController(text: station?.departureOffset ?? '');
    _location = TextEditingController(text: station?.locationDescription ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _area.dispose();
    _arrival.dispose();
    _departure.dispose();
    _location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.station == null ? 'إضافة محطة' : 'تعديل محطة'),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'اسم المحطة'),
            ),
            const SizedBox(height: AppSpacing.small),
            TextField(
              controller: _area,
              decoration: const InputDecoration(
                labelText: 'ترتيب / منطقة المحطة',
              ),
            ),
            const SizedBox(height: AppSpacing.small),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _arrival,
                    decoration: const InputDecoration(labelText: 'وقت الوصول'),
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: TextField(
                    controller: _departure,
                    decoration: const InputDecoration(
                      labelText: 'وقت المغادرة',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            TextField(
              controller: _location,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'وصف الموقع'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            final existing = widget.station;
            widget.onSubmit(
              RouteStation(
                id: existing?.id ?? '',
                name: _name.text.trim().isEmpty
                    ? 'محطة جديدة'
                    : _name.text.trim(),
                area: _area.text.trim().isEmpty
                    ? 'غير محدد'
                    : _area.text.trim(),
                arrivalOffset: _arrival.text.trim().isEmpty
                    ? 'غير محدد'
                    : _arrival.text.trim(),
                departureOffset: _departure.text.trim().isEmpty
                    ? _arrival.text.trim()
                    : _departure.text.trim(),
                locationDescription: _location.text.trim().isEmpty
                    ? 'وصف موقع غير محدد'
                    : _location.text.trim(),
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
}

List<RouteStation> _normalize(List<RouteStation> stations) {
  return stations.indexed.map((entry) {
    final (index, station) = entry;
    return station.copyWith(order: index + 1);
  }).toList();
}
