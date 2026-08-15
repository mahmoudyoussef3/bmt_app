import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../../domain/entities/route_draft.dart';
import '../route_timeline_node.dart';

/// The route as a journey you can edit: origin at the top, destination at the
/// bottom, and a "+ إضافة نقطة" in every gap between them.
///
/// The order is the picture. There is no separate "stops" list to reconcile
/// with a map, no numbering to keep in sync, and no way to drag an endpoint out
/// of its position — the origin is always first and the destination always last
/// because they are rendered outside the reorderable region entirely.
class RouteTimelineEditor extends StatelessWidget {
  final RouteDraft draft;

  /// Stop the operator is working on, drawn with the brand outline.
  final int activeIndex;

  /// Index of the stop the save bar is currently complaining about, if any.
  final int? issueIndex;

  final ValueChanged<int> onEditStop;

  /// Insert a new stop *at* this index, pushing the rest down.
  final ValueChanged<int> onAddStopAt;
  final ValueChanged<int> onRemoveStop;
  final void Function(int oldIndex, int newIndex) onReorder;

  const RouteTimelineEditor({
    super.key,
    required this.draft,
    required this.activeIndex,
    required this.issueIndex,
    required this.onEditStop,
    required this.onAddStopAt,
    required this.onRemoveStop,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    final stops = draft.stops;
    final waypoints = draft.intermediateStops;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StopRow(
          stop: stops.first,
          role: RouteTimelineRole.origin,
          position: 1,

          roleLabel: 'من',
          active: activeIndex == 0,
          flagged: issueIndex == 0,
          emptyPrompt: 'اضغط لتحديد نقطة الانطلاق',
          onTap: () => onEditStop(0),

          onAddBelow: () => onAddStopAt(1),
        ),
        if (waypoints.isNotEmpty)
          _WaypointColumn(
            waypoints: waypoints,
            activeIndex: activeIndex,
            issueIndex: issueIndex,
            onEditStop: onEditStop,
            onAddStopAt: onAddStopAt,
            onRemoveStop: onRemoveStop,
            onReorder: onReorder,
          ),
        _StopRow(
          stop: stops.last,
          role: RouteTimelineRole.destination,
          position: stops.length,
          roleLabel: 'إلى',
          active: activeIndex == stops.length - 1,
          flagged: issueIndex == stops.length - 1,
          emptyPrompt: 'اضغط لتحديد الوجهة النهائية',
          onTap: () => onEditStop(stops.length - 1),
        ),
      ],
    );
  }
}

/// The reorderable middle of the journey: the stops between the two endpoints.
///
/// These are ordinary [Column] children carrying their own drag-and-drop, not a
/// `ReorderableListView`. That widget is a *scroll view*, and mounting one here
/// put a second viewport inside the page's own — with `shrinkWrap` and
/// [NeverScrollableScrollPhysics] to hide the fact. Two things followed from
/// it: its drag proxy moves the item's global key into the app overlay and back
/// while the dashboard shell rebuilds this whole subtree from inside layout,
/// which asserts with *"a _RenderLayoutBuilder was mutated in
/// _RenderLayoutBuilder.performLayout"*; and its auto-scroller binds to the
/// nearest [Scrollable] — the inner, unscrollable one — so a stop could never
/// be dragged past the bottom of the window on a route with several stops.
///
/// A drag here carries a label chip, and the row it is over is outlined: the
/// dropped stop takes that row's place.
class _WaypointColumn extends StatefulWidget {
  final List<({int index, RouteStopDraft stop})> waypoints;
  final int activeIndex;
  final int? issueIndex;
  final ValueChanged<int> onEditStop;
  final ValueChanged<int> onAddStopAt;
  final ValueChanged<int> onRemoveStop;
  final void Function(int oldIndex, int newIndex) onReorder;

  const _WaypointColumn({
    required this.waypoints,
    required this.activeIndex,
    required this.issueIndex,
    required this.onEditStop,
    required this.onAddStopAt,
    required this.onRemoveStop,
    required this.onReorder,
  });

  @override
  State<_WaypointColumn> createState() => _WaypointColumnState();
}

class _WaypointColumnState extends State<_WaypointColumn> {
  /// Position within [_WaypointColumn.waypoints], not within the route's stops.
  int? _dragging;
  int? _hovering;

  void _clearDrag() {
    if (_dragging == null && _hovering == null) return;
    setState(() {
      _dragging = null;
      _hovering = null;
    });
  }

  /// Translates "put the stop at [from] where the stop at [to] is" into the
  /// insert-before indices the draft reorders by.
  void _drop(int from, int to) {
    _clearDrag();
    if (from == to) return;
    widget.onReorder(from + 1, (to > from ? to + 1 : to) + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var position = 0; position < widget.waypoints.length; position++)
          _row(position),
      ],
    );
  }

  Widget _row(int position) {
    final entry = widget.waypoints[position];
    final dragged = _dragging == position;

    return DragTarget<int>(
      key: ValueKey(entry.stop.key),
      onWillAcceptWithDetails: (details) => details.data != position,
      onMove: (_) {
        if (_hovering == position) return;
        setState(() => _hovering = position);
      },
      onLeave: (_) {
        if (_hovering != position) return;
        setState(() => _hovering = null);
      },
      onAcceptWithDetails: (details) => _drop(details.data, position),
      builder: (context, candidate, rejected) => Opacity(
        opacity: dragged ? 0.4 : 1,
        child: _StopRow(
          stop: entry.stop,
          role: RouteTimelineRole.waypoint,
          position: entry.index + 1,
          active: widget.activeIndex == entry.index,
          flagged: widget.issueIndex == entry.index,
          dropTarget: _hovering == position && !dragged,
          emptyPrompt: 'اضغط لتسمية هذه النقطة',
          onTap: () => widget.onEditStop(entry.index),
          onRemove: () => widget.onRemoveStop(entry.index),
          onAddBelow: () => widget.onAddStopAt(entry.index + 1),
          handle: Draggable<int>(
            data: position,
            affinity: Axis.vertical,
            onDragStarted: () => setState(() => _dragging = position),
            onDraggableCanceled: (_, _) => _clearDrag(),
            onDragEnd: (_) => _clearDrag(),
            feedback: _DragChip(stop: entry.stop, position: entry.index + 1),
            child: const _DragHandle(),
          ),
        ),
      ),
    );
  }
}

/// The grip itself — the only part of a row that starts a drag.
class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'اسحب لتغيير الترتيب',
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.small),
          child: Icon(
            Icons.drag_indicator_rounded,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// What the pointer carries during a drag: the stop, named, so the operator can
/// see which point they are moving while the rows shift under it.
class _DragChip extends StatelessWidget {
  final RouteStopDraft stop;
  final int position;

  const _DragChip({required this.stop, required this.position});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: AppTokens.cardElevation,
      borderRadius: BorderRadius.circular(AppTokens.radius),
      color: scheme.surface,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTokens.radius),
          border: Border.all(color: scheme.primary, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            RouteTimelineDot(
              role: RouteTimelineRole.waypoint,
              position: position,
            ),
            const SizedBox(width: AppSpacing.small),
            Text(
              stop.isNamed ? stop.name.trim() : 'نقطة بلا اسم',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

/// One point of the journey plus the gap beneath it.
///
/// Keeping the "+" inside the row above the gap it fills is what makes the
/// insert position unambiguous: the operator points at the place in the journey
/// where the bus stops, instead of adding to the end and dragging it up.
class _StopRow extends StatelessWidget {
  final RouteStopDraft stop;
  final RouteTimelineRole role;
  final int position;

  /// The grip that starts a reorder; endpoints have none.
  final Widget? handle;
  final bool active;
  final bool flagged;

  /// A stop is being dragged over this row and would take its place.
  final bool dropTarget;
  final String emptyPrompt;

  /// "من" / "إلى" for the endpoints; waypoints are identified by their number.
  final String? roleLabel;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final VoidCallback? onAddBelow;

  const _StopRow({
    required this.stop,
    required this.role,
    required this.position,
    required this.active,
    required this.flagged,
    required this.emptyPrompt,
    required this.onTap,
    this.roleLabel,
    this.handle,
    this.dropTarget = false,
    this.onRemove,
    this.onAddBelow,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final named = stop.isNamed;
    final meta = <String>[
      if (stop.area.trim().isNotEmpty) stop.area.trim(),
      if (stop.arrivalOffset.isNotEmpty && role != RouteTimelineRole.origin)
        'وصول بعد ${stop.arrivalOffset}',
      if (stop.dwellMinutes > 0) 'توقف ${stop.dwellMinutes} د',
      if (role == RouteTimelineRole.waypoint &&
          stop.boarding != RouteStopBoarding.both)
        stop.boarding.label,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.medium),
              child: RouteTimelineDot(role: role, position: position),
            ),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(AppTokens.radius),
                  child: AnimatedContainer(
                    duration: AppTokens.motionBase,
                    padding: const EdgeInsets.all(AppSpacing.medium),
                    decoration: BoxDecoration(
                      color: active || dropTarget
                          ? scheme.primaryContainer.withAlpha(40)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppTokens.radius),
                      border: Border.all(
                        color: active || flagged || dropTarget
                            ? scheme.primary
                            : scheme.outline.withAlpha(60),
                        width: active || flagged || dropTarget ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (roleLabel != null) ...[
                                Text(
                                  roleLabel!,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: routeRoleColor(context, role),
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 2),
                              ],
                              Text(
                                named ? stop.name.trim() : emptyPrompt,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: named
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: named
                                          ? null
                                          : scheme.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.xSmall),
                              Wrap(
                                spacing: AppSpacing.small,
                                runSpacing: AppSpacing.xSmall,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  RouteLocationChip(located: stop.isLocated),
                                  if (meta.isNotEmpty)
                                    Text(
                                      meta.join(' · '),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.small),
                        IconButton(
                          tooltip: 'تعديل',
                          visualDensity: VisualDensity.compact,
                          onPressed: onTap,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                        ),
                        if (onRemove != null)
                          IconButton(
                            tooltip: 'حذف النقطة',
                            visualDensity: VisualDensity.compact,
                            onPressed: onRemove,
                            icon: Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: scheme.error,
                            ),
                          ),
                        ?handle,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (onAddBelow != null) _AddStopGap(onAdd: onAddBelow!),
      ],
    );
  }
}

/// The gap between two points, with the one action it affords.
class _AddStopGap extends StatelessWidget {
  final VoidCallback onAdd;

  const _AddStopGap({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 14),
      child: Row(
        children: [
          const RouteTimelineConnector(height: 34),
          const SizedBox(width: AppSpacing.medium),
          TextButton.icon(
            onPressed: onAdd,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.small),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('إضافة نقطة'),
          ),
        ],
      ),
    );
  }
}
