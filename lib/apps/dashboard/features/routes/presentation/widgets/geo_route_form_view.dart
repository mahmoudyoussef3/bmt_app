import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:bmt_app/apps/dashboard/core/di/dashboard_di.dart';
import 'package:bmt_app/core/geo/geo_models.dart';
import 'package:bmt_app/core/theme/spacing.dart';
import 'package:bmt_app/core/widgets/app_card.dart';

import '../../domain/entities/operation_route.dart';
import '../../domain/services/route_schedule_calculator.dart';
import '../../domain/usecases/get_route_geometry_usecase.dart';
import '../../domain/usecases/search_places_usecase.dart';
import '../cubit/routes_cubit.dart';
import 'place_search_field.dart';
import 'route_point_row.dart';
import 'route_timeline.dart';

/// Single-page, geo-powered route create/edit form. Replaces the old 4-step
/// stepper. Start/destination/stops use [PlaceSearchField] autocomplete; total
/// distance + duration and per-stop arrival/departure times auto-calculate via
/// OpenRouteService and recompute on any change. Falls back to manual entry
/// when geocoding is disabled.
class GeoRouteFormView extends StatefulWidget {
  final OperationRoute? route;
  const GeoRouteFormView({super.key, this.route});

  @override
  State<GeoRouteFormView> createState() => _GeoRouteFormViewState();
}

class _GeoRouteFormViewState extends State<GeoRouteFormView> {
  final _formKey = GlobalKey<FormState>();
  late final SearchPlacesUseCase _searchPlaces;
  late final GetRouteGeometryUseCase _geometry;
  late final MapController _mapController;

  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _distance;
  late final TextEditingController _duration;
  late OperationRouteStatus _status;
  late List<RoutePointDraft> _points;
  int _activePointIndex = 0;

  Timer? _debounce;
  bool _calculating = false;
  String _geoError = '';

  bool get _isEditing => widget.route != null;
  bool get _geoEnabled => _searchPlaces.enabled;
  int get _locatedPointsCount => _points.where((p) => p.point != null).length;
  List<int> get _missingPointIndexes => _points.indexed
      .where((entry) => entry.$2.point == null)
      .map((entry) => entry.$1)
      .toList();
  bool get _canCalculate =>
      _geoEnabled &&
      _points.length >= 2 &&
      _locatedPointsCount == _points.length;
  bool get _readyToSave =>
      _name.text.trim().isNotEmpty &&
      _code.text.trim().isNotEmpty &&
      _distance.text.trim().isNotEmpty &&
      _duration.text.trim().isNotEmpty &&
      _points.length >= 2 &&
      _points.every(
        (p) =>
            p.label.trim().isNotEmpty &&
            p.area.trim().isNotEmpty &&
            (!_geoEnabled || p.point != null),
      );

  @override
  void initState() {
    super.initState();
    _searchPlaces = dashboardDi<SearchPlacesUseCase>();
    _geometry = dashboardDi<GetRouteGeometryUseCase>();
    _mapController = MapController();
    final route = widget.route;
    _name = TextEditingController(text: route?.name ?? '');
    _code = TextEditingController(text: route?.routeCode ?? '');
    _distance = TextEditingController(text: route?.distance ?? '');
    _duration = TextEditingController(text: route?.duration ?? '');
    _status = route?.status == OperationRouteStatus.archived
        ? OperationRouteStatus.paused
        : route?.status ?? OperationRouteStatus.active;
    _points = _initialPoints(route);
    _activePointIndex = _points.length > 1 ? 0 : -1;
  }

  List<RoutePointDraft> _initialPoints(OperationRoute? route) {
    final stations = route?.stations ?? const [];
    if (stations.isEmpty) {
      return [
        RoutePointDraft(id: _draftId(0), dwellMinutes: 0),
        RoutePointDraft(id: _draftId(1), dwellMinutes: 0),
      ];
    }
    return stations.map((s) {
      final dwell = _dwellFromOffsets(s.arrivalOffset, s.departureOffset);
      return RoutePointDraft(
        id: s.id.isNotEmpty ? s.id : _draftId(s.order),
        label: s.name,
        area: s.area,
        locationDescription: s.locationDescription,
        point: (s.latitude != null && s.longitude != null)
            ? GeoPoint(s.latitude!, s.longitude!)
            : null,
        dwellMinutes: dwell,
        arrivalOffset: s.arrivalOffset,
        departureOffset: s.departureOffset,
      );
    }).toList();
  }

  static String _draftId(int i) =>
      'draft-${DateTime.now().microsecondsSinceEpoch}-$i';

  /// Reconstructs dwell minutes from stored offsets (departure - arrival).
  static int _dwellFromOffsets(String arrival, String departure) {
    final a = _offsetToMinutes(arrival);
    final d = _offsetToMinutes(departure);
    if (a == null || d == null) return 3;
    final dwell = d - a;
    return dwell >= 0 ? dwell : 3;
  }

  static int? _offsetToMinutes(String hhmm) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(hhmm.trim());
    if (m == null) return null;
    return int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _name.dispose();
    _code.dispose();
    _distance.dispose();
    _duration.dispose();
    super.dispose();
  }

  void _setActivePoint(int index, {bool moveMap = true}) {
    if (index < 0 || index >= _points.length) return;
    setState(() => _activePointIndex = index);
    final point = _points[index].point;
    if (moveMap && point != null) {
      _mapController.move(LatLng(point.lat, point.lng), 15);
    }
  }

  void _setPointFromMap(int index, LatLng latLng) {
    if (index < 0 || index >= _points.length) return;
    final wasMissing = _points[index].point == null;
    setState(() {
      _activePointIndex = index;
      final point = _points[index];
      point.point = GeoPoint(latLng.latitude, latLng.longitude);
      if (point.label.trim().isEmpty) {
        point.label = _defaultPointLabel(index);
      }
      if (point.area.trim().isEmpty) {
        point.area = 'موقع محدد على الخريطة';
      }
      if (point.locationDescription.trim().isEmpty ||
          point.locationDescription == point.label) {
        point.locationDescription =
            '${latLng.latitude.toStringAsFixed(6)}, ${latLng.longitude.toStringAsFixed(6)}';
      }
      if (wasMissing) {
        final nextMissingCandidates = _points.indexed
            .where((entry) => entry.$1 != index && entry.$2.point == null)
            .map((entry) => entry.$1)
            .toList();
        if (nextMissingCandidates.isNotEmpty) {
          _activePointIndex = nextMissingCandidates.first;
        }
      }
    });
    _scheduleRecalc();
  }

  String _defaultPointLabel(int index) {
    if (index == 0) return 'نقطة بداية محددة من الخريطة';
    if (index == _points.length - 1) return 'نقطة نهاية محددة من الخريطة';
    return 'محطة ${index + 1} محددة من الخريطة';
  }

  void _scheduleRecalc() {
    if (!_geoEnabled) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _recalculate);
  }

  Future<void> _recalculate() async {
    final located = _points.where((p) => p.point != null).toList();
    if (located.length < 2 || located.length != _points.length) return;
    setState(() {
      _calculating = true;
      _geoError = '';
    });
    try {
      final geometry = await _geometry(_points.map((p) => p.point!).toList());
      final schedule = RouteScheduleCalculator.computeStopOffsets(
        legs: geometry.legs,
        dwellMinutes: _points.map((p) => p.dwellMinutes).toList(),
      );
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < _points.length && i < schedule.length; i++) {
          _points[i].arrivalOffset = schedule[i].arrivalOffset;
          _points[i].departureOffset = schedule[i].departureOffset;
        }
        _distance.text = RouteScheduleCalculator.formatDistance(
          geometry.totalDistanceMeters,
        );
        _duration.text = RouteScheduleCalculator.formatDuration(
          geometry.totalDurationSeconds,
        );
        _calculating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _calculating = false;
        _geoError = e.toString();
      });
    }
  }

  void _addStop() {
    setState(() {
      // Insert before the destination so the last point stays the endpoint.
      final insertAt = _points.isNotEmpty ? _points.length - 1 : 0;
      _points.insert(insertAt, RoutePointDraft(id: _draftId(_points.length)));
      _activePointIndex = insertAt;
    });
    _scheduleRecalc();
  }

  void _removePoint(int index) {
    if (_points.length <= 2) return;
    setState(() {
      _points.removeAt(index);
      if (_activePointIndex >= _points.length) {
        _activePointIndex = _points.length - 1;
      } else if (_activePointIndex > index) {
        _activePointIndex--;
      }
    });
    _scheduleRecalc();
  }

  void _movePoint(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _points.length) return;
    setState(() {
      final p = _points.removeAt(index);
      _points.insert(target, p);
      _activePointIndex = target;
    });
    _scheduleRecalc();
  }

  void _focusNextMissingPoint() {
    final missing = _missingPointIndexes;
    if (missing.isEmpty) return;
    final afterCurrent = missing.where((index) => index > _activePointIndex);
    _setActivePoint(afterCurrent.isEmpty ? missing.first : afterCurrent.first);
  }

  void _fitRouteOnMap() {
    final points = _points
        .where((point) => point.point != null)
        .map((point) => LatLng(point.point!.lat, point.point!.lng))
        .toList();
    if (points.isEmpty) return;
    if (points.length == 1) {
      _mapController.move(points.first, 15);
      return;
    }
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(56),
      ),
    );
  }

  OperationRoute _buildRoute() {
    final existing = widget.route;
    final stations = <RouteStation>[];
    for (var i = 0; i < _points.length; i++) {
      final p = _points[i];
      stations.add(
        RouteStation(
          id: p.id.startsWith('draft-') ? '' : p.id,
          name: p.label.trim(),
          area: p.area.trim().isEmpty ? _areaFromLabel(p.label) : p.area.trim(),
          arrivalOffset: p.arrivalOffset,
          departureOffset: p.departureOffset,
          locationDescription: p.locationDescription.trim().isEmpty
              ? p.label.trim()
              : p.locationDescription.trim(),
          latitude: p.point?.lat,
          longitude: p.point?.lng,
          estimatedArrivalTime: p.arrivalOffset,
          order: i + 1,
        ),
      );
    }
    return OperationRoute(
      id: existing?.id ?? '',
      routeCode: _code.text.trim(),
      name: _name.text.trim(),
      startCity: _points.first.label.trim(),
      endCity: _points.last.label.trim(),
      duration: _duration.text.trim(),
      distance: _distance.text.trim(),
      status: _status,
      stations: stations,
      notes: existing?.notes ?? const ['تم إنشاء المسار من مركز التشغيل'],
    );
  }

  String _areaFromLabel(String label) {
    final parts = label
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length >= 2) return parts[parts.length - 2];
    return label.trim();
  }

  void _onSave() {
    if (_formKey.currentState?.validate() != true) return;
    final missingCoords = _geoEnabled && _points.any((p) => p.point == null);
    if (missingCoords) {
      _focusNextMissingPoint();
      setState(() => _geoError = 'يرجى تحديد كل النقاط على الخريطة قبل الحفظ.');
      return;
    }
    if (_points.any((p) => p.label.trim().isEmpty)) {
      setState(() => _geoError = 'يرجى تحديد اسم لكل نقطة.');
      return;
    }
    context.read<RoutesCubit>().saveRoute(_buildRoute());
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RoutesCubit>();
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.large),
        children: [
          _header(context, cubit),
          const SizedBox(height: AppSpacing.large),
          if (!_geoEnabled) _geoDisabledNotice(context),
          _identityCard(),
          const SizedBox(height: AppSpacing.large),
          _RouteReadinessPanel(
            readyToSave: _readyToSave,
            geoEnabled: _geoEnabled,
            locatedPoints: _locatedPointsCount,
            totalPoints: _points.length,
            missingIndexes: _missingPointIndexes,
            hasIdentity:
                _name.text.trim().isNotEmpty && _code.text.trim().isNotEmpty,
            hasMetrics:
                _distance.text.trim().isNotEmpty &&
                _duration.text.trim().isNotEmpty,
            onFocusNextMissing: _focusNextMissingPoint,
          ),
          const SizedBox(height: AppSpacing.large),
          _mapCard(context),
          const SizedBox(height: AppSpacing.large),
          _pointsCard(context),
          const SizedBox(height: AppSpacing.large),
          _metricsCard(context),
          const SizedBox(height: AppSpacing.large),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: RouteTimeline(route: _buildRoute()),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, RoutesCubit cubit) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Text(
              _isEditing ? 'تعديل المسار' : 'إنشاء مسار جديد',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          OutlinedButton(
            onPressed: cubit.showOperations,
            child: const Text('إلغاء'),
          ),
          const SizedBox(width: AppSpacing.small),
          FilledButton.icon(
            onPressed: _onSave,
            icon: const Icon(Icons.save_rounded),
            label: Text(_isEditing ? 'حفظ التعديل' : 'حفظ المسار'),
          ),
        ],
      ),
    );
  }

  Widget _geoDisabledNotice(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.large),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.medium),
        decoration: BoxDecoration(
          color: scheme.tertiaryContainer.withAlpha(80),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.tertiary.withAlpha(90)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: scheme.tertiary),
            const SizedBox(width: AppSpacing.small),
            const Expanded(
              child: Text(
                'خدمة الخرائط غير مفعّلة: أدخل المسافة والمدة وأسماء النقاط يدوياً. '
                'لتفعيل البحث والحساب التلقائي أضف مفتاح OpenRouteService.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _identityCard() {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('بيانات المسار', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.medium),
          Wrap(
            spacing: AppSpacing.medium,
            runSpacing: AppSpacing.medium,
            children: [
              SizedBox(
                width: 280,
                child: TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'اسم المسار',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'يرجى إدخال اسم المسار'
                      : null,
                ),
              ),
              SizedBox(
                width: 280,
                child: TextFormField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'كود المسار',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'يرجى إدخال كود المسار'
                      : null,
                ),
              ),
              SizedBox(
                width: 280,
                child: DropdownButtonFormField<OperationRouteStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'الحالة',
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
                  onChanged: (v) => setState(
                    () => _status = v ?? OperationRouteStatus.active,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pointsCard(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'نقاط المسار',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              FilledButton.icon(
                onPressed: _addStop,
                icon: const Icon(Icons.add_location_alt_outlined),
                label: const Text('إضافة محطة'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xSmall),
          Text(
            'اختر النقطة النشطة ثم اضغط على الخريطة لتحديدها. يمكن كتابة اسم يدوي إذا لم يظهر المكان في البحث.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.medium),
          for (var i = 0; i < _points.length; i++)
            RoutePointRow(
              key: ValueKey(_points[i].id),
              index: i,
              total: _points.length,
              point: _points[i],
              geoEnabled: _geoEnabled,
              searchPlaces: _searchPlaces,
              onPlaceSelected: (place) {
                setState(() {
                  _points[i].label = place.label;
                  _points[i].area = _areaFromLabel(place.label);
                  _points[i].locationDescription = place.label;
                  _points[i].point = place.point;
                  _activePointIndex = i;
                });
                _mapController.move(
                  LatLng(place.point.lat, place.point.lng),
                  15,
                );
                _scheduleRecalc();
              },
              onManualLabel: (text) {
                setState(() => _points[i].label = text);
              },
              onAreaChanged: (text) {
                setState(() => _points[i].area = text);
              },
              onDwellChanged: (mins) {
                _points[i].dwellMinutes = mins;
                _scheduleRecalc();
              },
              onSelectOnMap: () => _setActivePoint(i),
              onMoveUp: () => _movePoint(i, -1),
              onMoveDown: () => _movePoint(i, 1),
              onRemove: () => _removePoint(i),
              selectedForMap: i == _activePointIndex,
            ),
        ],
      ),
    );
  }

  Widget _mapCard(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'اختيار النقاط من الخريطة',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton.icon(
                onPressed: _canCalculate && !_calculating ? _recalculate : null,
                icon: _calculating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.route_outlined),
                label: const Text('حساب المسار'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xSmall),
          Text(
            'اضغط على نقطة من القائمة أو على علامة في الخريطة، ثم اضغط في أي مكان على الخريطة لتحديث موقعها.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.medium),
          _RouteMapPicker(
            controller: _mapController,
            points: _points,
            activeIndex: _activePointIndex,
            onMapTap: (latLng) => _setPointFromMap(_activePointIndex, latLng),
            onMarkerTap: _setActivePoint,
            onFitRoute: _fitRouteOnMap,
            onFocusNextMissing: _focusNextMissingPoint,
            hasMissingPoints: _missingPointIndexes.isNotEmpty,
          ),
          const SizedBox(height: AppSpacing.medium),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: [
              for (var i = 0; i < _points.length; i++)
                ChoiceChip(
                  selected: i == _activePointIndex,
                  avatar: Icon(
                    _points[i].point == null
                        ? Icons.add_location_alt_outlined
                        : Icons.location_on_outlined,
                    size: 18,
                  ),
                  label: Text(
                    _points[i].label.trim().isEmpty
                        ? _defaultPointLabel(i)
                        : _points[i].label,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onSelected: (_) => _setActivePoint(i),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricsCard(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'المسافة والمدة',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (_geoEnabled)
                TextButton.icon(
                  onPressed: _canCalculate && !_calculating
                      ? _recalculate
                      : null,
                  icon: _calculating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.calculate_outlined),
                  label: const Text('إعادة الحساب'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          Wrap(
            spacing: AppSpacing.medium,
            runSpacing: AppSpacing.medium,
            children: [
              SizedBox(
                width: 240,
                child: TextFormField(
                  controller: _distance,
                  readOnly: _geoEnabled,
                  decoration: const InputDecoration(
                    labelText: 'المسافة',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'المسافة مطلوبة' : null,
                ),
              ),
              SizedBox(
                width: 240,
                child: TextFormField(
                  controller: _duration,
                  readOnly: _geoEnabled,
                  decoration: const InputDecoration(
                    labelText: 'المدة',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'المدة مطلوبة' : null,
                ),
              ),
            ],
          ),
          if (_geoError.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.small),
            Text(
              _geoError,
              style: TextStyle(
                color: scheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RouteReadinessPanel extends StatelessWidget {
  final bool readyToSave;
  final bool geoEnabled;
  final int locatedPoints;
  final int totalPoints;
  final List<int> missingIndexes;
  final bool hasIdentity;
  final bool hasMetrics;
  final VoidCallback onFocusNextMissing;

  const _RouteReadinessPanel({
    required this.readyToSave,
    required this.geoEnabled,
    required this.locatedPoints,
    required this.totalPoints,
    required this.missingIndexes,
    required this.hasIdentity,
    required this.hasMetrics,
    required this.onFocusNextMissing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = totalPoints == 0 ? 0.0 : locatedPoints / totalPoints;
    final issues = <String>[
      if (!hasIdentity) 'أكمل اسم وكود المسار',
      if (geoEnabled && missingIndexes.isNotEmpty)
        'حدد ${missingIndexes.length} نقطة على الخريطة',
      if (!hasMetrics) 'احسب أو أدخل المسافة والمدة',
    ];

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: readyToSave
                    ? scheme.primaryContainer
                    : scheme.tertiaryContainer,
                child: Icon(
                  readyToSave
                      ? Icons.verified_outlined
                      : Icons.pending_actions_outlined,
                  size: 20,
                  color: readyToSave ? scheme.primary : scheme.tertiary,
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      readyToSave ? 'جاهز للحفظ' : 'استكمال بيانات المسار',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      readyToSave
                          ? 'كل النقاط والبيانات الأساسية مكتملة.'
                          : issues.join(' • '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (geoEnabled && missingIndexes.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: onFocusNextMissing,
                  icon: const Icon(Icons.my_location_rounded),
                  label: const Text('النقطة التالية'),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: geoEnabled ? progress.clamp(0, 1).toDouble() : null,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.xSmall,
            children: [
              _ReadinessChip(
                label: hasIdentity ? 'الهوية مكتملة' : 'الهوية ناقصة',
                done: hasIdentity,
              ),
              _ReadinessChip(
                label: geoEnabled
                    ? '$locatedPoints/$totalPoints نقاط محددة'
                    : 'تحديد يدوي',
                done: !geoEnabled || locatedPoints == totalPoints,
              ),
              _ReadinessChip(
                label: hasMetrics ? 'المسافة والمدة جاهزة' : 'المسافة ناقصة',
                done: hasMetrics,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReadinessChip extends StatelessWidget {
  final String label;
  final bool done;

  const _ReadinessChip({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      avatar: Icon(
        done ? Icons.check_circle_outline : Icons.radio_button_unchecked,
        size: 18,
        color: done ? scheme.primary : scheme.onSurfaceVariant,
      ),
      label: Text(label),
      backgroundColor: done
          ? scheme.primaryContainer.withAlpha(90)
          : scheme.surface,
      side: BorderSide(color: scheme.outline.withAlpha(90)),
    );
  }
}

class _RouteMapPicker extends StatelessWidget {
  final MapController controller;
  final List<RoutePointDraft> points;
  final int activeIndex;
  final ValueChanged<LatLng> onMapTap;
  final ValueChanged<int> onMarkerTap;
  final VoidCallback onFitRoute;
  final VoidCallback onFocusNextMissing;
  final bool hasMissingPoints;

  const _RouteMapPicker({
    required this.controller,
    required this.points,
    required this.activeIndex,
    required this.onMapTap,
    required this.onMarkerTap,
    required this.onFitRoute,
    required this.onFocusNextMissing,
    required this.hasMissingPoints,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final located = points.indexed
        .where((entry) => entry.$2.point != null)
        .map((entry) => (index: entry.$1, point: entry.$2.point!))
        .toList();
    final center = _center(located);
    final polylinePoints = located
        .map((entry) => LatLng(entry.point.lat, entry.point.lng))
        .toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 380,
        child: Stack(
          children: [
            FlutterMap(
              mapController: controller,
              options: MapOptions(
                initialCenter: center,
                initialZoom: located.length >= 2 ? 11 : 10,
                onTap: (_, latLng) => onMapTap(latLng),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.bmt.app',
                ),
                if (polylinePoints.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: polylinePoints,
                        color: scheme.primary,
                        strokeWidth: 5,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    for (final entry in located)
                      Marker(
                        point: LatLng(entry.point.lat, entry.point.lng),
                        width: 52,
                        height: 58,
                        child: _RouteMapMarker(
                          index: entry.index,
                          selected: entry.index == activeIndex,
                          onTap: () => onMarkerTap(entry.index),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 12,
              right: 12,
              child: _MapInstructionPill(
                text: activeIndex < 0
                    ? 'اختر نقطة من القائمة'
                    : 'تحدد الآن: ${_pointTitle(points, activeIndex)}',
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Wrap(
                spacing: AppSpacing.xSmall,
                runSpacing: AppSpacing.xSmall,
                children: [
                  _MapControlButton(
                    icon: Icons.fit_screen_rounded,
                    label: 'إظهار الكل',
                    onPressed: located.isEmpty ? null : onFitRoute,
                  ),
                  _MapControlButton(
                    icon: Icons.add_location_alt_outlined,
                    label: 'التالي',
                    onPressed: hasMissingPoints ? onFocusNextMissing : null,
                  ),
                ],
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surface.withAlpha(235),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outline.withAlpha(80)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.small),
                  child: Text(
                    'يمكنك التكبير والتحريك ثم الضغط لتثبيت العلامة',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LatLng _center(List<({int index, GeoPoint point})> located) {
    if (activeIndex >= 0 &&
        activeIndex < points.length &&
        points[activeIndex].point != null) {
      final point = points[activeIndex].point!;
      return LatLng(point.lat, point.lng);
    }
    if (located.isNotEmpty) {
      return LatLng(located.first.point.lat, located.first.point.lng);
    }
    return const LatLng(30.0444, 31.2357);
  }

  static String _pointTitle(List<RoutePointDraft> points, int index) {
    final label = points[index].label.trim();
    if (label.isNotEmpty) return label;
    if (index == 0) return 'البداية';
    if (index == points.length - 1) return 'النهاية';
    return 'محطة ${index + 1}';
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _MapControlButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface.withAlpha(235),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Opacity(
          opacity: onPressed == null ? 0.45 : 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: scheme.primary),
                const SizedBox(width: 6),
                Text(label, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RouteMapMarker extends StatelessWidget {
  final int index;
  final bool selected;
  final VoidCallback onTap;

  const _RouteMapMarker({
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.tertiary;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: selected ? 42 : 34,
            height: selected ? 42 : 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: scheme.surface,
                width: selected ? 4 : 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(80),
                  blurRadius: selected ? 14 : 8,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: scheme.onPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Icon(Icons.arrow_drop_down, color: color, size: selected ? 30 : 24),
        ],
      ),
    );
  }
}

class _MapInstructionPill extends StatelessWidget {
  final String text;

  const _MapInstructionPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withAlpha(235),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.primary.withAlpha(80)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: 8,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app_outlined, size: 16, color: scheme.primary),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
