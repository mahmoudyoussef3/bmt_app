import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bmt_app/core/geo/geo_models.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../../domain/usecases/search_places_usecase.dart';
import 'place_search_field.dart';

/// A single ordered point along the route. The first point is the origin
/// (البداية), the last is the destination (النهاية), the rest are stops.
class RoutePointDraft {
  final String id;
  String label;
  String area;
  String locationDescription;
  GeoPoint? point;
  int dwellMinutes;
  String arrivalOffset;
  String departureOffset;

  RoutePointDraft({
    required this.id,
    this.label = '',
    this.area = '',
    this.locationDescription = '',
    this.point,
    this.dwellMinutes = 3,
    this.arrivalOffset = '',
    this.departureOffset = '',
  });
}

/// Digits-only formatter for dwell-minute inputs.
final dwellInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.digitsOnly,
  LengthLimitingTextInputFormatter(3),
];

/// One editable row in the route's ordered point list: place selector, dwell
/// time, auto-computed arrival/departure offsets, and reorder/remove controls.
class RoutePointRow extends StatelessWidget {
  final int index;
  final int total;
  final RoutePointDraft point;
  final bool geoEnabled;
  final SearchPlacesUseCase searchPlaces;
  final ValueChanged<GeoPlace> onPlaceSelected;
  final ValueChanged<String> onManualLabel;
  final ValueChanged<String> onAreaChanged;
  final ValueChanged<int> onDwellChanged;
  final VoidCallback onSelectOnMap;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;
  final bool selectedForMap;

  const RoutePointRow({
    super.key,
    required this.index,
    required this.total,
    required this.point,
    required this.geoEnabled,
    required this.searchPlaces,
    required this.onPlaceSelected,
    required this.onManualLabel,
    required this.onAreaChanged,
    required this.onDwellChanged,
    required this.onSelectOnMap,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
    this.selectedForMap = false,
  });

  bool get _isFirst => index == 0;
  bool get _isLast => index == total - 1;

  String get _roleLabel => _isFirst
      ? 'البداية'
      : _isLast
      ? 'النهاية'
      : 'محطة $index';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.small),
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: selectedForMap
            ? scheme.primaryContainer.withAlpha(70)
            : scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selectedForMap ? scheme.primary : scheme.outline.withAlpha(70),
          width: selectedForMap ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 14, child: Text('${index + 1}')),
              const SizedBox(width: AppSpacing.small),
              Text(
                _roleLabel,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              if (point.arrivalOffset.isNotEmpty)
                _OffsetChip(
                  label: _isFirst
                      ? 'انطلاق ${point.departureOffset}'
                      : 'وصول ${point.arrivalOffset}',
                ),
              const SizedBox(width: AppSpacing.xSmall),
              Tooltip(
                message: 'تحديد هذه النقطة على الخريطة',
                child: IconButton(
                  onPressed: onSelectOnMap,
                  icon: Icon(
                    selectedForMap
                        ? Icons.my_location_rounded
                        : Icons.add_location_alt_outlined,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _placeField()),
              if (!_isFirst && !_isLast) ...[
                const SizedBox(width: AppSpacing.small),
                SizedBox(width: 110, child: _dwellField()),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          TextFormField(
            key: ValueKey('area-${point.id}-${point.area}'),
            initialValue: point.area,
            decoration: const InputDecoration(
              labelText: 'المنطقة',
              prefixIcon: Icon(Icons.location_city_outlined),
              border: OutlineInputBorder(),
            ),
            onChanged: onAreaChanged,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'أدخل منطقة النقطة' : null,
          ),
          const SizedBox(height: AppSpacing.xSmall),
          Row(
            children: [
              IconButton(
                tooltip: 'تحريك لأعلى',
                onPressed: index == 0 ? null : onMoveUp,
                icon: const Icon(Icons.arrow_upward_rounded, size: 18),
              ),
              IconButton(
                tooltip: 'تحريك لأسفل',
                onPressed: index == total - 1 ? null : onMoveDown,
                icon: const Icon(Icons.arrow_downward_rounded, size: 18),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'حذف النقطة',
                onPressed: total <= 2 ? null : onRemove,
                icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeField() {
    final label = _roleLabel;
    if (geoEnabled) {
      return PlaceSearchField(
        key: ValueKey('search-${point.id}'),
        label: label,
        initialText: point.label,
        searchPlaces: searchPlaces,
        focus: point.point,
        onSelected: onPlaceSelected,
        onChanged: onManualLabel,
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'اختر $label' : null,
      );
    }
    return TextFormField(
      initialValue: point.label,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.place_outlined),
        border: const OutlineInputBorder(),
      ),
      onChanged: onManualLabel,
      validator: (v) => (v == null || v.trim().isEmpty) ? 'أدخل $label' : null,
    );
  }

  Widget _dwellField() {
    return TextFormField(
      initialValue: point.dwellMinutes.toString(),
      keyboardType: TextInputType.number,
      inputFormatters: dwellInputFormatters,
      decoration: const InputDecoration(
        labelText: 'توقف (د)',
        border: OutlineInputBorder(),
      ),
      onChanged: (v) => onDwellChanged(int.tryParse(v) ?? 0),
    );
  }
}

class _OffsetChip extends StatelessWidget {
  final String label;
  const _OffsetChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: scheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
