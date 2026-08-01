import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../../domain/entities/operation_route.dart';
import '../../../domain/usecases/search_places_usecase.dart';
import '../../cubit/route_builder_cubit.dart';
import '../../cubit/route_builder_state.dart';
import 'route_builder_map.dart';
import 'route_builder_panel.dart';

/// Create-and-edit workspace for a route.
///
/// One screen, three zones that never move: the summary on top, the map and the
/// stop list side by side, the save bar at the bottom. It replaces a
/// page-length scroll of seven stacked cards (identity, readiness checklist,
/// map, points, metrics, preview) where the map and the list it drove were
/// screens apart.
class RouteBuilderView extends StatelessWidget {
  /// The route being edited; `null` creates a new one.
  final OperationRoute? route;

  /// Codes already in use, so a new route can reserve the next free one.
  final List<String> existingCodes;
  final bool saving;
  final String saveError;
  final VoidCallback onCancel;
  final ValueChanged<OperationRoute> onSave;

  const RouteBuilderView({
    super.key,
    required this.route,
    required this.existingCodes,
    required this.saving,
    required this.saveError,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RouteBuilderCubit>(
      create: (_) =>
          dashboardDi<RouteBuilderCubit>()
            ..start(route: route, existingCodes: existingCodes),
      child: _RouteBuilderBody(
        saving: saving,
        saveError: saveError,
        onCancel: onCancel,
        onSave: onSave,
      ),
    );
  }
}

class _RouteBuilderBody extends StatelessWidget {
  final bool saving;
  final String saveError;
  final VoidCallback onCancel;
  final ValueChanged<OperationRoute> onSave;

  const _RouteBuilderBody({
    required this.saving,
    required this.saveError,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RouteBuilderCubit>();
    final searchPlaces = dashboardDi<SearchPlacesUseCase>();

    return BlocBuilder<RouteBuilderCubit, RouteBuilderState>(
      builder: (context, state) {
        final panel = RouteBuilderPanel(
          state: state,
          cubit: cubit,
          searchPlaces: state.geoEnabled ? searchPlaces : null,
        );
        final map = RouteBuilderMap(
          stops: state.draft.stops,
          path: state.path,
          activeIndex: state.activeIndex,
          picking: state.picking,
          onMapTap: cubit.placeOnMap,
          onStopTap: cubit.focusStop,
          onCancelPicking: cubit.cancelPicking,
        );

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Column(
            children: [
              _BuilderHeader(state: state, onCancel: onCancel),
              if (!state.geoEnabled) const _GeoDisabledNotice(),
              const SizedBox(height: AppSpacing.medium),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth >= 1080) {
                      return Row(
                        children: [
                          SizedBox(
                            width: 440,
                            child: AppCard(
                              padding: EdgeInsets.zero,
                              child: panel,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.medium),
                          Expanded(child: map),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        SizedBox(height: 300, child: map),
                        const SizedBox(height: AppSpacing.medium),
                        Expanded(
                          child: AppCard(
                            padding: EdgeInsets.zero,
                            child: panel,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (saveError.isNotEmpty) _SaveErrorBar(message: saveError),
              const SizedBox(height: AppSpacing.medium),
              _BuilderFooter(
                state: state,
                saving: saving,
                onCancel: onCancel,
                onFocusIssue: cubit.focusNextIssue,
                onSave: () => onSave(state.draft.toRoute()),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BuilderHeader extends StatelessWidget {
  final RouteBuilderState state;
  final VoidCallback onCancel;

  const _BuilderHeader({required this.state, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final draft = state.draft;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: scheme.primaryContainer,
            child: Icon(Icons.alt_route_rounded, color: scheme.primary),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  draft.isEditing ? 'تعديل المسار' : 'مسار جديد',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  draft.name.isEmpty
                      ? 'حدد نقطة الانطلاق والوجهة، وسنحسب المسار والمسافة والتوقيتات تلقائياً.'
                      : draft.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.small),
          _RouteMetricsPill(state: state),
          const SizedBox(width: AppSpacing.small),
          IconButton(
            tooltip: 'إغلاق',
            onPressed: onCancel,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

/// Distance, duration and stop count — recalculated on every change, so the
/// operator never presses a "calculate" button. While a calculation is in
/// flight the pill says so instead of showing stale numbers.
class _RouteMetricsPill extends StatelessWidget {
  final RouteBuilderState state;

  const _RouteMetricsPill({required this.state});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final draft = state.draft;
    final hasError = state.geoError.isNotEmpty;

    final Widget content;
    if (state.calculating) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.small),
          Text(
            'جارٍ حساب المسار',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ],
      );
    } else if (hasError) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 16, color: scheme.error),
          const SizedBox(width: AppSpacing.small),
          Text(
            'تعذر حساب المسار',
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: scheme.error),
          ),
          const SizedBox(width: AppSpacing.xSmall),
          TextButton(
            onPressed: context.read<RouteBuilderCubit>().recalculate,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      );
    } else if (draft.hasMetrics) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Metric(icon: Icons.straighten_rounded, value: draft.distance),
          const SizedBox(width: AppSpacing.medium),
          _Metric(icon: Icons.schedule_rounded, value: draft.duration),
          const SizedBox(width: AppSpacing.medium),
          _Metric(
            icon: Icons.pin_drop_outlined,
            value: '${draft.stops.length} نقاط',
          ),
        ],
      );
    } else {
      content = Text(
        'بانتظار تحديد النقطتين',
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(70),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: hasError
              ? scheme.error.withAlpha(120)
              : scheme.outline.withAlpha(60),
        ),
      ),
      child: content,
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String value;

  const _Metric({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: scheme.primary),
        const SizedBox(width: 5),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _GeoDisabledNotice extends StatelessWidget {
  const _GeoDisabledNotice();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.small),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.small),
        decoration: BoxDecoration(
          color: scheme.tertiaryContainer.withAlpha(80),
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          border: Border.all(color: scheme.tertiary.withAlpha(90)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 18, color: scheme.tertiary),
            const SizedBox(width: AppSpacing.small),
            const Expanded(
              child: Text(
                'خدمة الخرائط غير مفعّلة: حدد النقاط على الخريطة وأدخل المسافة والمدة يدوياً من بيانات المسار.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveErrorBar extends StatelessWidget {
  final String message;

  const _SaveErrorBar({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.medium),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.medium),
        decoration: BoxDecoration(
          color: scheme.errorContainer.withAlpha(120),
          borderRadius: BorderRadius.circular(AppTokens.radius),
          border: Border.all(color: scheme.error.withAlpha(120)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: scheme.error),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Save bar. The single readiness sentence names the *next* thing to do and
/// jumps to it when tapped, instead of the old checklist card that listed every
/// unmet condition and left the operator to find them.
class _BuilderFooter extends StatelessWidget {
  final RouteBuilderState state;
  final bool saving;
  final VoidCallback onCancel;
  final VoidCallback onFocusIssue;
  final VoidCallback onSave;

  const _BuilderFooter({
    required this.state,
    required this.saving,
    required this.onCancel,
    required this.onFocusIssue,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final draft = state.draft;
    final issues = draft.issues;
    final ready = issues.isEmpty;
    final firstIssue = issues.isEmpty ? null : issues.first;

    final status = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          ready ? Icons.verified_rounded : Icons.pending_actions_rounded,
          size: 18,
          color: ready ? scheme.primary : scheme.tertiary,
        ),
        const SizedBox(width: AppSpacing.small),
        Flexible(
          child: Text(
            ready
                ? 'جاهز للحفظ — ${draft.stops.length} نقاط على ${draft.distance}'
                : firstIssue!.message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ready ? scheme.primary : scheme.onSurfaceVariant,
              fontWeight: ready ? FontWeight.bold : null,
            ),
          ),
        ),
        if (!ready && firstIssue?.stopIndex != null) ...[
          const SizedBox(width: AppSpacing.xSmall),
          TextButton(
            onPressed: onFocusIssue,
            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            child: const Text('اذهب إليها'),
          ),
        ],
      ],
    );

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final actions = [
            OutlinedButton(
              onPressed: saving ? null : onCancel,
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              key: const ValueKey('route-builder-save'),
              onPressed: ready && !saving ? onSave : null,
              icon: saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded),
              label: Text(
                saving
                    ? 'جارٍ الحفظ...'
                    : draft.isEditing
                    ? 'حفظ التعديلات'
                    : 'حفظ المسار',
              ),
            ),
          ];

          if (constraints.maxWidth < 640) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                status,
                const SizedBox(height: AppSpacing.small),
                Row(
                  children: [
                    Expanded(child: actions[0]),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(child: actions[1]),
                  ],
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: status),
              const SizedBox(width: AppSpacing.medium),
              actions[0],
              const SizedBox(width: AppSpacing.small),
              actions[1],
            ],
          );
        },
      ),
    );
  }
}
