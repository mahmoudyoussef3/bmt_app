import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/core/maps/map_route_stop.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';
import 'package:bmt_app/core/widgets/route_direction_text.dart';

import '../../domain/entities/operation_route.dart';
import '../cubit/routes_cubit.dart';
import '../cubit/routes_state.dart';
import 'route_preview_map.dart';
import 'route_timeline_node.dart';
import 'routes_list_view.dart' show RouteCodeBadge;

/// One route, read top to bottom: where it goes, then the journey itself.
///
/// This page used to open on four KPI tiles, a "route readiness" checklist and
/// a quick-actions column before showing a single stop — with un-pinned stops
/// counted as failures in red. Missing coordinates are optional by design, so
/// nothing here reports them as a problem.
class RouteDetailsView extends StatelessWidget {
  final RoutesLoaded state;

  const RouteDetailsView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final route = state.selectedRoute;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        _DetailsHeader(route: route),
        const SizedBox(height: AppSpacing.medium),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1080;
            final journey = _JourneyPanel(route: route);
            final map = _MapPanel(route: route);

            if (!wide) {
              return Column(
                children: [
                  journey,
                  const SizedBox(height: AppSpacing.medium),
                  map,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: journey),
                const SizedBox(width: AppSpacing.medium),
                Expanded(flex: 5, child: map),
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
    final facts = <String>[
      '${route.stations.length} نقاط',
      if (route.duration.isNotEmpty) route.duration,
      if (route.distance.isNotEmpty) route.distance,
    ];

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 900;

          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  RouteCodeBadge(code: route.routeCode),
                  StatusChip(label: route.status.label),
                ],
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                _headline(route, Directionality.of(context)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xSmall),
              Text(
                'مسار نقل · ${facts.join(' · ')}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                icon: const Icon(DashboardIcons.back),
                label: const Text('رجوع'),
              ),
              FilledButton.icon(
                onPressed: () => cubit.showEditRoute(route),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('تعديل المسار'),
              ),
              OutlinedButton.icon(
                onPressed: () => cubit.showReturnLeg(route),
                icon: const Icon(Icons.swap_vert_rounded),
                label: const Text('إنشاء مسار العودة'),
              ),
              _RouteActionsMenu(route: route),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: title),
              const SizedBox(width: AppSpacing.medium),
              actions,
            ],
          );
        },
      ),
    );
  }

  /// `origin ← destination`, read right to left like the rest of the console.
  ///
  /// Each endpoint is wrapped in a first-strong isolate (U+2068 … U+2069) so
  /// the arrow lands between two *neutral* objects and follows the RTL
  /// paragraph instead of the names' own script. Without it, two Latin names —
  /// which is what the geocoder returns for "New Cairo" or "Zefta" — resolve
  /// the whole line left to right and the arrow ends up pointing at the
  /// origin, announcing the route backwards. The controls render as nothing.
  static String _headline(OperationRoute route, TextDirection direction) {
    final from = route.startCity.trim();
    final to = route.endCity.trim();
    if (from.isEmpty || to.isEmpty) return route.name;
    return routeDirectionLabel(from, to, direction: direction);
  }
}

class _RouteActionsMenu extends StatelessWidget {
  final OperationRoute route;

  const _RouteActionsMenu({required this.route});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RoutesCubit>();
    final scheme = Theme.of(context).colorScheme;
    final active = route.status == OperationRouteStatus.active;

    return MenuAnchor(
      builder: (context, controller, _) => OutlinedButton.icon(
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
        icon: const Icon(Icons.more_horiz_rounded),
        label: const Text('المزيد'),
      ),
      menuChildren: [
        if (active)
          MenuItemButton(
            leadingIcon: const Icon(Icons.pause_circle_outline_rounded),
            onPressed: () => cubit.pauseRoute(route),
            child: const Text('إيقاف مؤقت'),
          )
        else
          MenuItemButton(
            leadingIcon: const Icon(Icons.play_circle_outline_rounded),
            onPressed: () => cubit.activateRoute(route),
            child: const Text('تنشيط المسار'),
          ),
        MenuItemButton(
          leadingIcon: const Icon(Icons.archive_outlined),
          onPressed: route.status == OperationRouteStatus.archived
              ? null
              : () => confirmArchiveRoute(context, route),
          child: const Text('أرشفة'),
        ),
        MenuItemButton(
          leadingIcon: Icon(Icons.delete_outline_rounded, color: scheme.error),
          onPressed: () => confirmDeleteRoute(context, route),
          child: Text('حذف نهائي', style: TextStyle(color: scheme.error)),
        ),
      ],
    );
  }
}

/// The journey, as a timeline. One rendering of the stops — this page used to
/// carry three (an editable list, a timeline, and a "client preview" of pickup
/// and drop-off groups), all of the same rows.
class _JourneyPanel extends StatelessWidget {
  final OperationRoute route;

  const _JourneyPanel({required this.route});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RoutesCubit>();
    final scheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route_outlined, color: scheme.primary),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  'نقاط المسار',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => cubit.showEditRoute(route),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('تعديل النقاط'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xSmall),
          Text(
            'الترتيب هو اتجاه السير: يبدأ الأتوبيس من الأولى وينتهي عند الأخيرة.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.large),
          if (route.stations.isEmpty)
            _NoStopsNote(onEdit: () => cubit.showEditRoute(route))
          else
            ...route.stations.indexed.map(
              (entry) => _StopTile(
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

class _StopTile extends StatelessWidget {
  final RouteStation station;
  final int index;
  final int total;

  const _StopTile({
    required this.station,
    required this.index,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final role = RouteTimelineRole.at(index, total);
    final last = index == total - 1;
    final located = station.latitude != null && station.longitude != null;
    final meta = <String>[
      if (station.area.trim().isNotEmpty) station.area.trim(),
      if (station.arrivalOffset.isNotEmpty)
        index == 0
            ? 'الانطلاق ${station.departureOffset.isEmpty ? station.arrivalOffset : station.departureOffset}'
            : 'وصول بعد ${station.arrivalOffset}',
      _boardingLabel(station),
    ];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              RouteTimelineDot(role: role, position: index + 1),
              if (!last)
                const Expanded(child: RouteTimelineConnector(height: 40)),
            ],
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : AppSpacing.large),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          station.name.isEmpty ? 'نقطة بدون اسم' : station.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (role.isEndpoint)
                        Text(
                          role == RouteTimelineRole.origin
                              ? 'البداية'
                              : 'النهاية',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: routeRoleColor(context, role),
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xSmall),
                  Wrap(
                    spacing: AppSpacing.small,
                    runSpacing: AppSpacing.xSmall,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      RouteLocationChip(located: located),
                      Text(
                        meta.where((part) => part.isNotEmpty).join(' · '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  if (station.locationDescription.trim().isNotEmpty &&
                      station.locationDescription.trim() !=
                          station.name.trim()) ...[
                    const SizedBox(height: AppSpacing.xSmall),
                    Text(
                      station.locationDescription.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _boardingLabel(RouteStation station) {
    if (station.pickupAllowed && station.dropoffAllowed) return 'صعود ونزول';
    if (station.pickupAllowed) return 'صعود فقط';
    if (station.dropoffAllowed) return 'نزول فقط';
    return 'غير متاحة للركاب';
  }
}

class _NoStopsNote extends StatelessWidget {
  final VoidCallback onEdit;

  const _NoStopsNote({required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(45),
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: scheme.outline.withAlpha(45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'لا توجد نقاط بعد',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xSmall),
          Text(
            'افتح تعديل المسار وحدد نقطة الانطلاق والوجهة على الأقل.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.medium),
          FilledButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('تعديل المسار'),
          ),
        ],
      ),
    );
  }
}

/// The map, showing only what has been pinned. A route with nothing pinned gets
/// a plain explanation of what pinning would add — not a warning about what is
/// missing.
class _MapPanel extends StatelessWidget {
  final OperationRoute route;

  const _MapPanel({required this.route});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final located = route.stations
        .where(
          (station) => station.latitude != null && station.longitude != null,
        )
        .toList();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.map_outlined, color: scheme.primary),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  'خريطة المسار',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (route.stations.isNotEmpty)
                Text(
                  '${located.length}/${route.stations.length}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          if (located.isEmpty)
            Container(
              height: 220,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(AppSpacing.large),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withAlpha(45),
                borderRadius: BorderRadius.circular(AppTokens.radius),
                border: Border.all(color: scheme.outline.withAlpha(45)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.explore_outlined,
                    size: 32,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Text(
                    'لا توجد مواقع محددة',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.xSmall),
                  Text(
                    'المسار يعمل والحجز عليه متاح. تحديد المواقع يضيف فقط خريطة '
                    'يراها العميل والكابتن أثناء الرحلة.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          else
            RoutePreviewMap(
              stops: [
                for (final station in located)
                  MapRouteStop(
                    coordinate: LatLng(station.latitude!, station.longitude!),
                    name: station.name,
                  ),
              ],
              height: 320,
            ),
        ],
      ),
    );
  }
}

void confirmArchiveRoute(BuildContext context, OperationRoute route) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('تأكيد أرشفة المسار'),
      content: Text(
        'سيتم تحويل "${route.name}" إلى مؤرشف، ولن يظهر للعملاء ولا عند إنشاء رحلات جديدة. '
        'الرحلات والحجوزات المرتبطة تبقى كما هي.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            context.read<RoutesCubit>().archiveRoute(route);
          },
          child: const Text('تأكيد الأرشفة'),
        ),
      ],
    ),
  );
}

void confirmDeleteRoute(BuildContext context, OperationRoute route) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('حذف المسار نهائياً'),
      content: Text(
        'سيتم حذف "${route.name}" ونقاطه من قاعدة البيانات. '
        'إذا كانت هناك رحلات مرتبطة به فلن يسمح النظام بالحذف — استخدم الأرشفة بدلاً منه.',
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
