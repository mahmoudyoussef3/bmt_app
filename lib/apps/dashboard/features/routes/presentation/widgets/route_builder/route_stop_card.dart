import 'package:flutter/material.dart';

import 'package:bmt_app/core/geo/geo_models.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';

import '../../../domain/entities/route_draft.dart';
import '../../../domain/usecases/search_places_usecase.dart';
import 'route_place_field.dart';

/// One intermediate stop in the builder's list.
///
/// Collapsed it is a single readable line — order, name, area, timing — so a
/// six-stop route fits on screen. Expanded (only ever one at a time, the stop
/// the operator is working on) it reveals the three things a stop actually has:
/// where it is, what riders may do there, and how long the bus waits.
class RouteStopCard extends StatelessWidget {
  /// Position along the route, used for the visible number and the stop's
  /// label. Stop 1 is the first one *after* the origin.
  final int index;

  /// Position within the reorderable list, which holds only the intermediate
  /// stops — one less than [index]. Handing the drag listener the route
  /// position instead would drag the wrong row.
  final int dragIndex;
  final RouteStopDraft stop;
  final bool expanded;
  final bool picking;
  final SearchPlacesUseCase? searchPlaces;
  final VoidCallback onToggle;
  final VoidCallback onPickOnMap;
  final VoidCallback onRemove;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<GeoPlace> onPlaceSelected;
  final ValueChanged<RouteStopBoarding> onBoardingChanged;
  final ValueChanged<int> onDwellChanged;

  const RouteStopCard({
    super.key,
    required this.index,
    required this.dragIndex,
    required this.stop,
    required this.expanded,
    required this.picking,
    required this.searchPlaces,
    required this.onToggle,
    required this.onPickOnMap,
    required this.onRemove,
    required this.onNameChanged,
    required this.onPlaceSelected,
    required this.onBoardingChanged,
    required this.onDwellChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final highlighted = expanded || picking;
    return AnimatedContainer(
      duration: AppTokens.motionBase,
      margin: const EdgeInsets.only(bottom: AppSpacing.small),
      decoration: BoxDecoration(
        color: highlighted
            ? scheme.primaryContainer.withAlpha(40)
            : scheme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radius),
        border: Border.all(
          color: highlighted
              ? scheme.primary
              : stop.isComplete
              ? scheme.outline.withAlpha(60)
              : scheme.error.withAlpha(110),
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          _Header(
            index: index,
            dragIndex: dragIndex,
            stop: stop,
            expanded: expanded,
            onToggle: onToggle,
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.medium,
                0,
                AppSpacing.medium,
                AppSpacing.medium,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: RoutePlaceField(
                          key: ValueKey('stop-field-${stop.key}'),
                          label: 'محطة $index',
                          icon: Icons.pin_drop_outlined,
                          value: stop.name,
                          focusPoint: stop.point,
                          searchPlaces: searchPlaces,
                          onChanged: onNameChanged,
                          onPlaceSelected: onPlaceSelected,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.small),
                      MapPickButton(active: picking, onPressed: onPickOnMap),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  BoardingSelector(
                    value: stop.boarding,
                    onChanged: onBoardingChanged,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  Row(
                    children: [
                      Expanded(
                        child: DwellStepper(
                          minutes: stop.dwellMinutes,
                          onChanged: onDwellChanged,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: onRemove,
                        style: TextButton.styleFrom(
                          foregroundColor: scheme.error,
                        ),
                        icon: const Icon(Icons.delete_outline_rounded, size: 18),
                        label: const Text('حذف'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int index;
  final int dragIndex;
  final RouteStopDraft stop;
  final bool expanded;
  final VoidCallback onToggle;

  const _Header({
    required this.index,
    required this.dragIndex,
    required this.stop,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final meta = <String>[
      if (stop.area.trim().isNotEmpty) stop.area.trim(),
      if (stop.arrivalOffset.isNotEmpty) 'وصول ${stop.arrivalOffset}',
      if (stop.dwellMinutes > 0) 'توقف ${stop.dwellMinutes} د',
      if (stop.boarding != RouteStopBoarding.both) stop.boarding.label,
    ];

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(AppTokens.radius),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: dragIndex,
              child: Icon(
                Icons.drag_indicator_rounded,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            CircleAvatar(
              radius: 13,
              backgroundColor: stop.isLocated
                  ? scheme.primary
                  : scheme.errorContainer,
              child: Text(
                '$index',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: stop.isLocated
                      ? scheme.onPrimary
                      : scheme.onErrorContainer,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stop.name.trim().isEmpty ? 'محطة بدون اسم' : stop.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: stop.isNamed ? null : scheme.error,
                    ),
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      meta.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!stop.isLocated)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: AppSpacing.xSmall),
                child: Tooltip(
                  message: 'بدون موقع على الخريطة',
                  child: Icon(
                    Icons.location_off_outlined,
                    size: 18,
                    color: scheme.error,
                  ),
                ),
              ),
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: AppTokens.motionBase,
              child: Icon(
                Icons.expand_more_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Arms the map for one point. Reads as a toggle, because that is what it is:
/// while it is on, the next map tap belongs to this stop and nothing else.
class MapPickButton extends StatelessWidget {
  final bool active;
  final VoidCallback onPressed;
  final bool dense;

  const MapPickButton({
    super.key,
    required this.active,
    required this.onPressed,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: active ? 'اضغط على الخريطة الآن' : 'تحديد على الخريطة',
      child: IconButton.filledTonal(
        onPressed: onPressed,
        visualDensity: dense ? VisualDensity.compact : null,
        style: IconButton.styleFrom(
          backgroundColor: active ? scheme.primary : null,
          foregroundColor: active ? scheme.onPrimary : null,
        ),
        icon: Icon(active ? Icons.my_location_rounded : Icons.add_location_alt_outlined),
      ),
    );
  }
}

/// Replaces the two independent "allow pickup" / "allow dropoff" checkboxes,
/// which could both be unchecked — a stop nobody can use.
class BoardingSelector extends StatelessWidget {
  final RouteStopBoarding value;
  final ValueChanged<RouteStopBoarding> onChanged;

  const BoardingSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<RouteStopBoarding>(
        segments: RouteStopBoarding.values
            .map(
              (option) => ButtonSegment(
                value: option,
                label: Text(option.label, style: const TextStyle(fontSize: 12)),
              ),
            )
            .toList(),
        selected: {value},
        showSelectedIcon: false,
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}

/// Dwell time as a stepper instead of a free-text minutes field: it cannot be
/// typed wrong, and it feeds the arrival times shown on every stop.
class DwellStepper extends StatelessWidget {
  final int minutes;
  final ValueChanged<int> onChanged;

  const DwellStepper({
    super.key,
    required this.minutes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.timer_outlined, size: 18, color: scheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.xSmall),
        Text(
          'التوقف',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(width: AppSpacing.small),
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: scheme.outline.withAlpha(90)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StepButton(
                icon: Icons.remove_rounded,
                onPressed: minutes <= 0 ? null : () => onChanged(minutes - 1),
              ),
              SizedBox(
                width: 46,
                child: Text(
                  '$minutes د',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _StepButton(
                icon: Icons.add_rounded,
                onPressed: minutes >= 120 ? null : () => onChanged(minutes + 1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _StepButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 16,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}
