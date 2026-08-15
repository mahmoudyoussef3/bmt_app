import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/core/widgets/debounced_search_field.dart';
import 'package:bmt_app/core/widgets/status_chip.dart';

import '../../domain/entities/operation_route.dart';
import '../cubit/routes_cubit.dart';
import '../cubit/routes_state.dart';
import 'route_timeline_node.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';

/// The board of routes.
///
/// A route card answers one question — *where does this line go* — so it leads
/// with the direction and the chain of places, the two things an operator
/// recognises a route by. The version this replaces led with a route code and a
/// 64-pixel map thumbnail, and spent a third of its height on a progress bar
/// measuring how many stops had been pinned.
class RoutesListView extends StatelessWidget {
  final RoutesLoaded state;

  const RoutesListView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RoutesCubit>();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.large),
      children: [
        _RoutesToolbar(state: state),
        const SizedBox(height: AppSpacing.medium),
        _RoutesBoard(state: state, cubit: cubit),
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

    return DashboardModuleHeader(
      icon: DashboardIcons.routesActive,
      title: 'المسارات',
      subtitle:
          'خطوط السير التي تُبنى عليها الرحلات والحجوزات — من أين إلى أين، وما بينهما.',
      actions: [
        FilledButton.icon(
          onPressed: cubit.showBuilder,
          icon: const Icon(Icons.add_rounded),
          label: const Text('إضافة مسار جديد'),
        ),
      ],
      // Search and the status filter are pinned: on an office with forty
      // routes they are the only way to reach a specific one.
      pinned: LayoutBuilder(
        builder: (context, constraints) {
          final search = DebouncedSearchField(
            hintText: 'ابحث باسم المسار أو مدينة أو محطة',
            onChanged: cubit.updateSearch,
          );
          final filter = _StatusFilter(state: state);
          final summary = _CountSummary(state: state);

          if (constraints.maxWidth < 820) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                search,
                const SizedBox(height: AppSpacing.small),
                Row(
                  children: [
                    Expanded(child: filter),
                    const SizedBox(width: AppSpacing.medium),
                    summary,
                  ],
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: search),
              const SizedBox(width: AppSpacing.medium),
              SizedBox(width: 220, child: filter),
              const SizedBox(width: AppSpacing.medium),
              summary,
            ],
          );
        },
      ),
    );
  }
}

/// The counts an operator actually acts on, as one line instead of a four-card
/// KPI grid measuring things like "station map readiness".
class _CountSummary extends StatelessWidget {
  final RoutesLoaded state;

  const _CountSummary({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shown = state.filteredRoutes.length;
    final total = state.routes.length;
    return Text(
      shown == total
          ? '$total مسار · ${state.activeCount} نشط · ${state.pausedCount} متوقف'
          : '$shown من $total مسار',
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
    );
  }
}

class _StatusFilter extends StatelessWidget {
  final RoutesLoaded state;

  const _StatusFilter({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RoutesCubit>();
    return DropdownButtonFormField<OperationRouteStatus?>(
      isExpanded: true,
      initialValue: state.statusFilter,
      decoration: const InputDecoration(labelText: 'الحالة', isDense: true),
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
    );
  }
}

class _RoutesBoard extends StatelessWidget {
  final RoutesLoaded state;
  final RoutesCubit cubit;

  const _RoutesBoard({required this.state, required this.cubit});

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
            mainAxisExtent: 218,
          ),
          itemBuilder: (context, index) {
            final route = routes[index];
            return RouteCard(
              route: route,
              onView: () => cubit.showDetails(route),
              onEdit: () => cubit.showEditRoute(route),
            );
          },
        );
      },
    );
  }
}

class RouteCard extends StatelessWidget {
  final OperationRoute route;
  final VoidCallback onView;
  final VoidCallback onEdit;

  const RouteCard({
    super.key,
    required this.route,
    required this.onView,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stops = route.stations.map((station) => station.name).toList();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      onTap: onView,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _Direction(
                  from: route.startCity,
                  to: route.endCity,
                  fallback: route.name,
                ),
              ),
              StatusChip(label: route.status.label),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Row(
            children: [
              RouteCodeBadge(code: route.routeCode),
              const SizedBox(width: AppSpacing.small),
              Text(
                '${route.stations.length} نقاط',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (route.duration.isNotEmpty) ...[
                Text(' · ', style: TextStyle(color: scheme.onSurfaceVariant)),
                Text(
                  route.duration,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (route.distance.isNotEmpty) ...[
                Text(' · ', style: TextStyle(color: scheme.onSurfaceVariant)),
                Text(
                  route.distance,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: stops.isEmpty
                  ? Text(
                      'لا توجد نقاط بعد',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    )
                  : RouteDirectionChain(stops: stops, maxLines: 3),
            ),
          ),
          Row(
            children: [
              FilledButton.tonalIcon(
                onPressed: onView,
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('التفاصيل'),
              ),
              const SizedBox(width: AppSpacing.small),
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('تعديل'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// `بنها → القاهرة` as the card's headline. Falls back to the stored route name
/// for old rows saved before endpoints were derived from the stops.
class _Direction extends StatelessWidget {
  final String from;
  final String to;
  final String fallback;

  const _Direction({
    required this.from,
    required this.to,
    required this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);

    if (from.trim().isEmpty || to.trim().isEmpty) {
      return Text(
        fallback,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    return Row(
      children: [
        Flexible(
          child: Text(
            from,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Icon(
            DashboardIcons.transition,
            size: 16,
            color: scheme.onSurfaceVariant,
          ),
        ),
        Flexible(
          child: Text(
            to,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
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
          Icon(Icons.alt_route_rounded, size: 34, color: scheme.primary),
          const SizedBox(height: AppSpacing.small),
          Text(
            hasRoutes ? 'لا توجد مسارات مطابقة' : 'ابدأ بإضافة أول مسار',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xSmall),
          Text(
            hasRoutes
                ? 'غيّر البحث أو الحالة لعرض مسارات أخرى.'
                : 'المسار هو خط سير: من أين يبدأ الأتوبيس، وأين ينتهي، وما يمر به. '
                      'يكفي اسمان لإنشائه — تحديد المواقع على الخريطة اختياري.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.medium),
          FilledButton.icon(
            onPressed: cubit.showBuilder,
            icon: const Icon(Icons.add_rounded),
            label: const Text('إضافة مسار جديد'),
          ),
        ],
      ),
    );
  }
}
