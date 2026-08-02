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
          // "من" / "إلى" spell out the two questions a route is, so the
          // timeline doubles as the From/To form instead of repeating the
          // endpoints in a separate pair of fields above it.
          roleLabel: 'من',
          active: activeIndex == 0,
          flagged: issueIndex == 0,
          emptyPrompt: 'اضغط لتحديد نقطة الانطلاق',
          onTap: () => onEditStop(0),
          // The gap under the origin: a stop added here is the first thing the
          // bus reaches after leaving.
          onAddBelow: () => onAddStopAt(1),
        ),
        if (waypoints.isNotEmpty)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: waypoints.length,
            // The list holds only the stops between the endpoints, so positions
            // are shifted by one to address the draft's full ordered list.
            onReorder: (oldIndex, newIndex) =>
                onReorder(oldIndex + 1, newIndex + 1),
            itemBuilder: (context, position) {
              final entry = waypoints[position];
              return _StopRow(
                key: ValueKey(entry.stop.key),
                stop: entry.stop,
                role: RouteTimelineRole.waypoint,
                position: entry.index + 1,
                dragIndex: position,
                active: activeIndex == entry.index,
                flagged: issueIndex == entry.index,
                emptyPrompt: 'اضغط لتسمية هذه النقطة',
                onTap: () => onEditStop(entry.index),
                onRemove: () => onRemoveStop(entry.index),
                onAddBelow: () => onAddStopAt(entry.index + 1),
              );
            },
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

/// One point of the journey plus the gap beneath it.
///
/// Keeping the "+" inside the row above the gap it fills is what makes the
/// insert position unambiguous: the operator points at the place in the journey
/// where the bus stops, instead of adding to the end and dragging it up.
class _StopRow extends StatelessWidget {
  final RouteStopDraft stop;
  final RouteTimelineRole role;
  final int position;
  final int? dragIndex;
  final bool active;
  final bool flagged;
  final String emptyPrompt;

  /// "من" / "إلى" for the endpoints; waypoints are identified by their number.
  final String? roleLabel;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final VoidCallback? onAddBelow;

  const _StopRow({
    super.key,
    required this.stop,
    required this.role,
    required this.position,
    required this.active,
    required this.flagged,
    required this.emptyPrompt,
    required this.onTap,
    this.roleLabel,
    this.dragIndex,
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
                      color: active
                          ? scheme.primaryContainer.withAlpha(40)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppTokens.radius),
                      border: Border.all(
                        color: active || flagged
                            ? scheme.primary
                            : scheme.outline.withAlpha(60),
                        width: active || flagged ? 1.5 : 1,
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
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
                        if (dragIndex != null)
                          ReorderableDragStartListener(
                            index: dragIndex!,
                            child: Tooltip(
                              message: 'اسحب لتغيير الترتيب',
                              child: Padding(
                                padding: const EdgeInsets.all(AppSpacing.small),
                                child: Icon(
                                  Icons.drag_indicator_rounded,
                                  size: 20,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
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
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.small,
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('إضافة نقطة'),
          ),
        ],
      ),
    );
  }
}
