import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/core/geo/geo_models.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/widgets/maps/controls/map_control_cluster.dart';
import 'package:bmt_app/core/widgets/maps/easyway_tile_layer.dart';
import 'package:bmt_app/core/widgets/maps/map_camera_animator.dart';
import 'package:bmt_app/core/widgets/maps/overlays/map_attribution.dart';

import '../../../domain/usecases/search_places_usecase.dart';
import 'route_place_field.dart';

/// What the picker returned: a coordinate, or the operator's decision to have
/// none. `null` from the dialog itself means they cancelled and nothing changes.
class RouteLocationResult {
  final GeoPoint? point;

  const RouteLocationResult(this.point);

  bool get isCleared => point == null;
}

/// Opens the map for exactly one job: choose where a stop is.
///
/// The map used to be permanently mounted beside the stop list, which made
/// route creation look like a mapping task. It is now an *enhancement* reached
/// on request — nothing here blocks saving a route, and the caller is free to
/// never open it.
Future<RouteLocationResult?> showRouteLocationPicker(
  BuildContext context, {
  required String stopName,
  GeoPoint? initial,
  SearchPlacesUseCase? searchPlaces,
}) {
  return showDialog<RouteLocationResult>(
    context: context,
    builder: (_) => _RouteLocationPickerDialog(
      stopName: stopName,
      initial: initial,
      searchPlaces: searchPlaces,
    ),
  );
}

class _RouteLocationPickerDialog extends StatefulWidget {
  final String stopName;
  final GeoPoint? initial;
  final SearchPlacesUseCase? searchPlaces;

  const _RouteLocationPickerDialog({
    required this.stopName,
    required this.initial,
    required this.searchPlaces,
  });

  @override
  State<_RouteLocationPickerDialog> createState() =>
      _RouteLocationPickerDialogState();
}

class _RouteLocationPickerDialogState extends State<_RouteLocationPickerDialog>
    with SingleTickerProviderStateMixin {
  /// Cairo — the centre of the operating area, so an operator who has picked
  /// nothing yet still opens on somewhere they recognise.
  static const _fallbackCenter = LatLng(30.0444, 31.2357);

  late final MapController _controller;
  late final RouteCameraAnimator _camera;
  GeoPoint? _picked;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = MapController();
    _camera = RouteCameraAnimator(vsync: this, controller: _controller);
    _picked = widget.initial;
  }

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  void _place(GeoPoint point, {bool move = false}) {
    setState(() => _picked = point);
    if (move && _ready) {
      _camera.animateTo(center: LatLng(point.lat, point.lng), zoom: 14);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final start = _picked ?? widget.initial;

    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.large),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(stopName: widget.stopName),
            if (widget.searchPlaces != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.large,
                  0,
                  AppSpacing.large,
                  AppSpacing.small,
                ),
                child: RoutePlaceField(
                  label: 'ابحث عن المكان',
                  hint: 'اكتب اسم المكان للانتقال إليه على الخريطة',
                  icon: Icons.search_rounded,
                  value: '',
                  searchPlaces: widget.searchPlaces,
                  focusPoint: start,
                  onChanged: (_) {},
                  onPlaceSelected: (place) =>
                      _place(place.point, move: true),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.large,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTokens.radius),
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _controller,
                        options: MapOptions(
                          initialCenter: start == null
                              ? _fallbackCenter
                              : LatLng(start.lat, start.lng),
                          initialZoom: start == null ? 10 : 14,
                          minZoom: 4,
                          maxZoom: 18,
                          onMapReady: () => _ready = true,
                          onTap: (_, latLng) => _place(
                            GeoPoint(latLng.latitude, latLng.longitude),
                          ),
                        ),
                        children: [
                          const EasyWayTileLayer(),
                          if (_picked != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(_picked!.lat, _picked!.lng),
                                  width: 42,
                                  height: 42,
                                  alignment: Alignment.topCenter,
                                  child: Icon(
                                    Icons.location_on_rounded,
                                    size: 42,
                                    color: scheme.primary,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      if (_picked == null)
                        PositionedDirectional(
                          top: AppSpacing.medium,
                          start: AppSpacing.medium,
                          end: AppSpacing.medium,
                          child: _Hint(
                            text: 'اضغط على الخريطة لتحديد موقع المحطة',
                          ),
                        ),
                      PositionedDirectional(
                        bottom: AppSpacing.medium,
                        end: AppSpacing.medium,
                        child: MapControlCluster(
                          onRecenter: () {
                            final point = _picked;
                            if (point == null) return;
                            _camera.animateTo(
                              center: LatLng(point.lat, point.lng),
                              zoom: 15,
                            );
                          },
                          onZoomIn: () => _camera.animateZoomBy(1),
                          onZoomOut: () => _camera.animateZoomBy(-1),
                          recenterTooltip: 'العودة إلى الموقع المحدد',
                          zoomInTooltip: 'تكبير',
                          zoomOutTooltip: 'تصغير',
                        ),
                      ),
                      const PositionedDirectional(
                        bottom: 4,
                        start: 6,
                        child: MapAttribution(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            _Footer(
              picked: _picked,
              hadInitial: widget.initial != null,
              onClear: () => Navigator.of(
                context,
              ).pop(const RouteLocationResult(null)),
              onCancel: () => Navigator.of(context).pop(),
              onConfirm: _picked == null
                  ? null
                  : () => Navigator.of(
                      context,
                    ).pop(RouteLocationResult(_picked)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String stopName;

  const _Header({required this.stopName});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Row(
        children: [
          Icon(Icons.place_outlined, color: scheme.primary),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تحديد الموقع على الخريطة',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  stopName.trim().isEmpty ? 'محطة جديدة' : stopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'إغلاق',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;

  const _Hint({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        decoration: BoxDecoration(
          color: scheme.surface.withAlpha(235),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: scheme.outline.withAlpha(60)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.ads_click_rounded, size: 16, color: scheme.primary),
            const SizedBox(width: AppSpacing.small),
            Text(text, style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final GeoPoint? picked;
  final bool hadInitial;
  final VoidCallback onClear;
  final VoidCallback onCancel;
  final VoidCallback? onConfirm;

  const _Footer({
    required this.picked,
    required this.hadInitial,
    required this.onClear,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Row(
        children: [
          Expanded(
            child: Text(
              picked == null
                  ? 'لم يتم تحديد موقع بعد'
                  : 'الموقع: ${picked!.lat.toStringAsFixed(5)}, '
                        '${picked!.lng.toStringAsFixed(5)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          if (hadInitial) ...[
            TextButton.icon(
              onPressed: onClear,
              style: TextButton.styleFrom(foregroundColor: scheme.error),
              icon: const Icon(Icons.location_off_outlined, size: 18),
              label: const Text('إزالة الموقع'),
            ),
            const SizedBox(width: AppSpacing.small),
          ],
          OutlinedButton(onPressed: onCancel, child: const Text('إلغاء')),
          const SizedBox(width: AppSpacing.small),
          FilledButton.icon(
            onPressed: onConfirm,
            icon: const Icon(Icons.check_rounded),
            label: const Text('تأكيد الموقع'),
          ),
        ],
      ),
    );
  }
}
