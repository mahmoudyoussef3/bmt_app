import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/core/maps/map_route_stop.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../../domain/entities/operation_route.dart';
import '../../../domain/entities/route_draft.dart';
import '../../../domain/services/route_stop_library.dart';
import '../../../domain/usecases/search_places_usecase.dart';
import '../../cubit/route_builder_cubit.dart';
import '../../cubit/route_builder_state.dart';
import '../route_preview_map.dart';
import '../route_timeline_node.dart';
import 'route_stop_editor.dart';
import 'route_timeline_editor.dart';

/// Create-and-edit workspace for a route.
///
/// One page, read top to bottom: where the route goes, then — folded away until
/// wanted — what it is called and what it looks like on a map. The whole flow is
/// *choose from → choose to → add optional stops → save*, and an operator who
/// only does the first two gets a working, sellable route.
///
/// It replaces a map-beside-list workspace in which the map was permanently
/// mounted, half the screen wide, and load-bearing: nothing could be saved until
/// every stop had been pinned on it and the provider had returned a distance.
/// That made "add the Banha–Cairo line" a mapping exercise. The map is now an
/// enhancement reached from one button inside the stop editor.
class RouteBuilderView extends StatelessWidget {
  /// The route being edited; `null` creates a new one.
  final OperationRoute? route;

  /// A prepared draft — the return leg of an existing route. Wins over [route].
  final RouteDraft? draft;

  /// Codes already in use, so a new route can reserve the next free one.
  final List<String> existingCodes;

  /// Stops the office already uses, offered instead of retyping them.
  final RouteStopLibrary library;
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
    this.draft,
    this.library = RouteStopLibrary.empty,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RouteBuilderCubit>(
      create: (_) => dashboardDi<RouteBuilderCubit>()
        ..start(
          route: route,
          draft: draft,
          existingCodes: existingCodes,
          library: library,
        ),
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

  SearchPlacesUseCase? _searchPlaces(RouteBuilderState state) =>
      state.geoEnabled ? dashboardDi<SearchPlacesUseCase>() : null;

  Future<void> _editStop(
    BuildContext context,
    RouteBuilderCubit cubit,
    RouteBuilderState state,
    int index,
  ) async {
    cubit.focusStop(index);
    final stop = state.draft.stops[index];
    final result = await showRouteStopEditor(
      context,
      stop: stop,
      role: _roleAt(index, state.draft.stops.length),
      library: state.library,
      searchPlaces: _searchPlaces(state),

      isNew: !stop.isNamed,
    );
    if (result == null) return;
    cubit.applyStop(index, result.stop);
    if (result.addAnother && context.mounted) {
      await _addStop(context, cubit, state, index + 1);
    }
  }

  /// Collects the stop *before* the timeline grows a row, so cancelling the
  /// dialog leaves no blank placeholder for the operator to clean up.
  ///
  /// Reopens itself at the next position for as long as the operator keeps
  /// choosing "حفظ والتالي" — a route commonly needs several stops in one
  /// sitting, and this is the difference between doing that in one flow or
  /// reopening the dialog from scratch each time.
  Future<void> _addStop(
    BuildContext context,
    RouteBuilderCubit cubit,
    RouteBuilderState state,
    int index,
  ) async {
    var at = index;
    while (true) {
      final result = await showRouteStopEditor(
        context,
        stop: RouteStopDraft(key: RouteStopDraft.freshKey()),
        role: RouteStopRole.waypoint,
        library: state.library,
        searchPlaces: _searchPlaces(state),
        isNew: true,
      );
      if (result == null) return;
      cubit.addStopAt(at, stop: result.stop);
      if (!result.addAnother || !context.mounted) return;
      at += 1;
    }
  }

  static RouteStopRole _roleAt(int index, int total) {
    if (index == 0) return RouteStopRole.origin;
    if (index == total - 1) return RouteStopRole.destination;
    return RouteStopRole.waypoint;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RouteBuilderCubit>();

    return BlocBuilder<RouteBuilderCubit, RouteBuilderState>(
      builder: (context, state) {
        final draft = state.draft;
        final issueIndex = draft.issues
            .map((issue) => issue.stopIndex)
            .whereType<int>()
            .firstOrNull;

        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.large),
                children: [
                  _BuilderHeader(state: state, onCancel: onCancel),
                  const SizedBox(height: AppSpacing.medium),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 920),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppCard(
                            padding: const EdgeInsets.all(AppSpacing.large),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _SectionTitle(
                                  icon: Icons.alt_route_rounded,
                                  title: 'خط السير',
                                  subtitle:
                                      'من أين إلى أين يتحرك الأتوبيس، والنقاط التي يمر بها في الطريق.',
                                  trailing: TextButton.icon(
                                    onPressed: draft.stops.length < 2
                                        ? null
                                        : cubit.reverseDirection,
                                    style: TextButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    icon: const Icon(
                                      Icons.swap_vert_rounded,
                                      size: 18,
                                    ),
                                    label: const Text('عكس الاتجاه'),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.large),
                                RouteTimelineEditor(
                                  draft: draft,
                                  activeIndex: state.activeIndex,
                                  issueIndex: issueIndex,
                                  onEditStop: (index) =>
                                      _editStop(context, cubit, state, index),
                                  onAddStopAt: (index) =>
                                      _addStop(context, cubit, state, index),
                                  onRemoveStop: cubit.removeStop,
                                  onReorder: cubit.moveStop,
                                ),
                                const SizedBox(height: AppSpacing.medium),
                                _DirectionNote(draft: draft),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.medium),
                          _DetailsSection(state: state, cubit: cubit),
                          const SizedBox(height: AppSpacing.medium),
                          _MapSection(state: state),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.large,
                0,
                AppSpacing.large,
                AppSpacing.large,
              ),
              child: Column(
                children: [
                  if (saveError.isNotEmpty) ...[
                    _SaveErrorBar(message: saveError),
                    const SizedBox(height: AppSpacing.medium),
                  ],
                  _BuilderFooter(
                    state: state,
                    saving: saving,
                    onCancel: onCancel,
                    onFocusIssue: cubit.focusNextIssue,
                    onSave: () => onSave(state.draft.toRoute()),
                  ),
                ],
              ),
            ),
          ],
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
                if (draft.directionLabel.isEmpty)
                  Text(
                    'اختر نقطة الانطلاق والوجهة — النقاط في الطريق اختيارية.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  )
                else
                  RouteDirectionChain(
                    stops: draft.stops.map((stop) => stop.name).toList(),
                    maxLines: 1,
                  ),
              ],
            ),
          ),
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

/// States the direction in words, right under the timeline that draws it.
/// A route row is one directed chain, so this is never ambiguous — and it is
/// never flipped behind the operator's back.
class _DirectionNote extends StatelessWidget {
  final RouteDraft draft;

  const _DirectionNote({required this.draft});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (draft.directionLabel.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(45),
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(color: scheme.outline.withAlpha(45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.swap_calls_rounded,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'اتجاه المسار',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                RouteDirectionChain(
                  stops: draft.stops.map((stop) => stop.name).toList(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.xSmall),
                Text(
                  'يبيع هذا المسار في هذا الاتجاه فقط. لرحلات العودة أنشئ مساراً منفصلاً من صفحة تفاصيل المسار.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
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

/// Name, code and status — all three have a sensible default, so the section
/// stays folded and shows what will be saved on its header line.
class _DetailsSection extends StatefulWidget {
  final RouteBuilderState state;
  final RouteBuilderCubit cubit;

  const _DetailsSection({required this.state, required this.cubit});

  @override
  State<_DetailsSection> createState() => _DetailsSectionState();
}

class _DetailsSectionState extends State<_DetailsSection> {
  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _distance;
  late final TextEditingController _duration;
  bool _open = false;

  RouteDraft get _draft => widget.state.draft;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: _draft.nameOverride);
    _code = TextEditingController(text: _draft.codeOverride);
    _distance = TextEditingController(text: _draft.distance);
    _duration = TextEditingController(text: _draft.duration);
  }

  @override
  void didUpdateWidget(_DetailsSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    _sync(_distance, _draft.distance);
    _sync(_duration, _draft.duration);
  }

  void _sync(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _distance.dispose();
    _duration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.state.draft;
    final cubit = widget.cubit;
    final summary = [
      draft.name.isEmpty ? 'بلا اسم بعد' : draft.name,
      draft.code,
      draft.status.label,
    ].where((part) => part.isNotEmpty).join(' · ');

    return _FoldableCard(
      icon: Icons.tune_rounded,
      title: 'بيانات المسار',
      summary: summary,
      open: _open,
      onToggle: () => setState(() => _open = !_open),
      child: Column(
        children: [
          TextField(
            controller: _name,
            onChanged: cubit.setName,
            decoration: InputDecoration(
              labelText: 'اسم المسار',
              prefixIcon: const Icon(Icons.short_text_rounded),
              isDense: true,
              border: const OutlineInputBorder(),
              hintText: draft.suggestedName.isEmpty
                  ? 'يُقترح تلقائياً بعد تحديد النقطتين'
                  : draft.suggestedName,
              helperText: draft.usesSuggestedName
                  ? 'يُستخدم الاسم المقترح تلقائياً'
                  : null,
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: cubit.setCode,
                  decoration: InputDecoration(
                    labelText: 'كود المسار',
                    prefixIcon: const Icon(Icons.tag_rounded),
                    isDense: true,
                    border: const OutlineInputBorder(),
                    hintText: draft.suggestedCode,
                    helperText: draft.usesSuggestedCode
                        ? 'كود تلقائي غير مستخدم'
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: DropdownButtonFormField<OperationRouteStatus>(
                  initialValue: draft.status,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'الحالة',
                    prefixIcon: Icon(Icons.toggle_on_outlined),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
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
                      cubit.setStatus(value ?? OperationRouteStatus.active),
                ),
              ),
            ],
          ),

          if (widget.state.metricsManual) ...[
            const SizedBox(height: AppSpacing.medium),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _distance,
                    onChanged: cubit.setDistance,
                    decoration: const InputDecoration(
                      labelText: 'المسافة (اختياري)',
                      hintText: 'مثال: 42 كم',
                      prefixIcon: Icon(Icons.straighten_rounded),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.medium),
                Expanded(
                  child: TextField(
                    controller: _duration,
                    onChanged: cubit.setDuration,
                    decoration: const InputDecoration(
                      labelText: 'المدة (اختياري)',
                      hintText: 'مثال: 1 س 10 د',
                      prefixIcon: Icon(Icons.timer_outlined),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// The map, folded away. It opens on request and shows only what is actually
/// pinned — never a demand to pin the rest.
class _MapSection extends StatefulWidget {
  final RouteBuilderState state;

  const _MapSection({required this.state});

  @override
  State<_MapSection> createState() => _MapSectionState();
}

class _MapSectionState extends State<_MapSection> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final draft = widget.state.draft;
    final located = draft.stops.where((stop) => stop.isLocated).toList();
    final total = draft.stops.length;

    final summary = located.isEmpty
        ? 'لا توجد مواقع محددة — المسار يعمل بدونها'
        : '${located.length} من $total نقطة محددة على الخريطة';

    return _FoldableCard(
      icon: Icons.map_outlined,
      title: 'خريطة المسار',
      summary: summary,
      open: _open,
      onToggle: () => setState(() => _open = !_open),
      child: located.isEmpty
          ? const _NoLocationsNote()
          : RoutePreviewMap(
              stops: [
                for (final stop in located)
                  MapRouteStop(
                    coordinate: LatLng(stop.point!.lat, stop.point!.lng),
                    name: stop.name,
                  ),
              ],
              path: widget.state.path
                  .map((point) => LatLng(point.lat, point.lng))
                  .toList(),
              focusIndex: -1,
              height: 340,
            ),
    );
  }
}

class _NoLocationsNote extends StatelessWidget {
  const _NoLocationsNote();

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
      child: Row(
        children: [
          Icon(Icons.explore_outlined, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Text(
              'لم تحدد مواقع على الخريطة بعد. المسار صالح تماماً بدونها — '
              'تحديد المواقع يحسّن فقط ما يراه العميل والكابتن على الخريطة.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoldableCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String summary;
  final bool open;
  final VoidCallback onToggle;
  final Widget child;

  const _FoldableCard({
    required this.icon,
    required this.title,
    required this.summary,
    required this.open,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(AppTokens.radius),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.large),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: scheme.primary),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          summary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: AppTokens.motionBase,
                    child: const Icon(Icons.expand_more_rounded),
                  ),
                ],
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.large,
                0,
                AppSpacing.large,
                AppSpacing.large,
              ),
              child: child,
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: scheme.primary),
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
        ?trailing,
      ],
    );
  }
}

class _SaveErrorBar extends StatelessWidget {
  final String message;

  const _SaveErrorBar({required this.message});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
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
    );
  }
}

/// Save bar. The single readiness sentence names the *next* thing to do and
/// jumps to it when tapped, instead of a checklist that lists every unmet
/// condition and leaves the operator to find them.
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
          color: ready ? scheme.primary : scheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.small),
        Flexible(
          child: Text(
            ready ? _readySummary(draft, state) : firstIssue!.message,
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
        if (state.calculating) ...[
          const SizedBox(width: AppSpacing.medium),
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.small),
          Text(
            'جارٍ حساب المسافة',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ],
    );

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cancel = OutlinedButton(
            onPressed: saving ? null : onCancel,
            child: const Text('إلغاء'),
          );
          final save = Tooltip(
            message: ready || saving ? '' : firstIssue!.message,
            child: FilledButton.icon(
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
          );

          if (constraints.maxWidth < 640) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                status,
                const SizedBox(height: AppSpacing.small),
                Row(
                  children: [
                    Expanded(child: cancel),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(child: save),
                  ],
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: status),
              const SizedBox(width: AppSpacing.medium),
              cancel,
              const SizedBox(width: AppSpacing.small),
              save,
            ],
          );
        },
      ),
    );
  }

  /// What is about to be saved, in the operator's terms: how many points, and
  /// the measured length when there is one.
  static String _readySummary(RouteDraft draft, RouteBuilderState state) {
    final points = '${draft.stops.length} نقاط';
    if (draft.hasMetrics) {
      return 'جاهز للحفظ — $points على ${draft.distance}';
    }
    return 'جاهز للحفظ — $points';
  }
}
