import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _distance;
  late final TextEditingController _duration;
  late OperationRouteStatus _status;
  late List<RoutePointDraft> _points;

  Timer? _debounce;
  bool _calculating = false;
  String _geoError = '';

  bool get _isEditing => widget.route != null;
  bool get _geoEnabled => _searchPlaces.enabled;

  @override
  void initState() {
    super.initState();
    _searchPlaces = dashboardDi<SearchPlacesUseCase>();
    _geometry = dashboardDi<GetRouteGeometryUseCase>();
    final route = widget.route;
    _name = TextEditingController(text: route?.name ?? '');
    _code = TextEditingController(text: route?.routeCode ?? '');
    _distance = TextEditingController(text: route?.distance ?? '');
    _duration = TextEditingController(text: route?.duration ?? '');
    _status = route?.status == OperationRouteStatus.archived
        ? OperationRouteStatus.paused
        : route?.status ?? OperationRouteStatus.active;
    _points = _initialPoints(route);
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
      final geometry =
          await _geometry(_points.map((p) => p.point!).toList());
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
        _distance.text =
            RouteScheduleCalculator.formatDistance(geometry.totalDistanceMeters);
        _duration.text =
            RouteScheduleCalculator.formatDuration(geometry.totalDurationSeconds);
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
      _points.insert(
        insertAt,
        RoutePointDraft(id: _draftId(_points.length)),
      );
    });
    _scheduleRecalc();
  }

  void _removePoint(int index) {
    if (_points.length <= 2) return;
    setState(() => _points.removeAt(index));
    _scheduleRecalc();
  }

  void _movePoint(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _points.length) return;
    setState(() {
      final p = _points.removeAt(index);
      _points.insert(target, p);
    });
    _scheduleRecalc();
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
          area: '',
          arrivalOffset: p.arrivalOffset,
          departureOffset: p.departureOffset,
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

  void _onSave() {
    if (_formKey.currentState?.validate() != true) return;
    final missingCoords =
        _geoEnabled && _points.any((p) => p.point == null);
    if (missingCoords) {
      setState(() => _geoError = 'يرجى اختيار كل النقاط من نتائج البحث.');
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
            'أول نقطة هي البداية وآخر نقطة هي النهاية. رتّب المحطات بينهما.',
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
                  _points[i].point = place.point;
                });
                _scheduleRecalc();
              },
              onManualLabel: (text) => _points[i].label = text,
              onDwellChanged: (mins) {
                _points[i].dwellMinutes = mins;
                _scheduleRecalc();
              },
              onMoveUp: () => _movePoint(i, -1),
              onMoveDown: () => _movePoint(i, 1),
              onRemove: () => _removePoint(i),
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
                  onPressed: _calculating ? null : _recalculate,
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
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'المسافة مطلوبة'
                      : null,
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
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'المدة مطلوبة'
                      : null,
                ),
              ),
            ],
          ),
          if (_geoError.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.small),
            Text(
              _geoError,
              style: TextStyle(color: scheme.error, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }
}
