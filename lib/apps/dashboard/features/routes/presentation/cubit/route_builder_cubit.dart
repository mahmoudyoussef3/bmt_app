import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/geo/geo_models.dart';

import '../../domain/entities/operation_route.dart';
import '../../domain/entities/route_draft.dart';
import '../../domain/services/route_identity.dart';
import '../../domain/services/route_schedule_calculator.dart';
import '../../domain/usecases/get_route_geometry_usecase.dart';
import 'route_builder_state.dart';

/// Drives the route builder: one draft, one active stop, and totals that keep
/// themselves up to date.
///
/// The distance, the duration and every stop's arrival/departure offset are
/// *derived*, never typed — the operator places points, this recalculates. The
/// old form exposed the same calculation behind two separate "احسب المسار" /
/// "إعادة الحساب" buttons and left the operator to remember to press one.
class RouteBuilderCubit extends Cubit<RouteBuilderState> {
  final GetRouteGeometryUseCase _geometry;

  Timer? _debounce;

  /// Guards against a slow calculation landing after a newer one.
  int _calculationToken = 0;

  RouteBuilderCubit(this._geometry)
    : super(
        RouteBuilderState(
          draft: RouteDraft.blank(suggestedCode: ''),
          geoEnabled: _geometry.enabled,
        ),
      );

  /// Opens the builder on a new route, or on [route] to edit it. [existingCodes]
  /// are the codes already in use so a new route can reserve the next free one.
  void start({OperationRoute? route, Iterable<String> existingCodes = const []}) {
    final draft = route == null
        ? RouteDraft.blank(suggestedCode: RouteIdentity.suggestCode(existingCodes))
        : RouteDraft.fromRoute(route);
    emit(
      RouteBuilderState(
        draft: draft,
        geoEnabled: _geometry.enabled,
        // A new route starts on its origin — the one field that must be filled
        // first. An edited route starts with nothing expanded, because its
        // stops are already complete and the operator came to change one.
        activeIndex: route == null ? 0 : -1,
      ),
    );
    if (route != null) _scheduleRecalculate(immediate: true);
  }

  // ── Focus & map picking ─────────────────────────────────────────────

  void focusStop(int index) {
    if (index < -1 || index >= state.draft.stops.length) return;
    emit(state.copyWith(activeIndex: index, picking: false));
  }

  /// Arms the map: the next tap places [index]. Any other interaction cancels.
  void pickOnMap(int index) {
    if (index < 0 || index >= state.draft.stops.length) return;
    emit(state.copyWith(activeIndex: index, picking: true));
  }

  void cancelPicking() {
    if (!state.picking) return;
    emit(state.copyWith(picking: false));
  }

  /// Sends the operator to the next unfinished point instead of making them
  /// hunt for it down the list.
  void focusNextIssue() {
    final target = state.draft.issues
        .map((issue) => issue.stopIndex)
        .whereType<int>()
        .firstOrNull;
    if (target == null) return;
    emit(state.copyWith(activeIndex: target, picking: true));
  }

  // ── Stop editing ────────────────────────────────────────────────────

  void selectPlace(int index, GeoPlace place) {
    final stop = _stopAt(index);
    if (stop == null) return;
    emit(
      state.copyWith(
        draft: state.draft.replaceStop(index, stop.withPlace(place)),
        activeIndex: index,
        picking: false,
      ),
    );
    _scheduleRecalculate();
  }

  /// A tap on the map while [RouteBuilderState.picking] is armed.
  void placeOnMap(GeoPoint point) {
    if (!state.picking) return;
    final index = state.activeIndex;
    final stop = _stopAt(index);
    if (stop == null) return;
    final placed = stop.withPoint(point);
    emit(
      state.copyWith(
        draft: state.draft.replaceStop(
          index,
          placed.name.trim().isEmpty
              ? placed.copyWith(name: _defaultStopName(index))
              : placed,
        ),
        picking: false,
      ),
    );
    _scheduleRecalculate();
  }

  void renameStop(int index, String value) {
    final stop = _stopAt(index);
    if (stop == null || stop.name == value) return;
    emit(state.copyWith(draft: state.draft.replaceStop(index, stop.copyWith(name: value))));
  }

  void setStopArea(int index, String value) {
    final stop = _stopAt(index);
    if (stop == null) return;
    emit(state.copyWith(draft: state.draft.replaceStop(index, stop.copyWith(area: value))));
  }

  void setDwellMinutes(int index, int minutes) {
    final stop = _stopAt(index);
    if (stop == null) return;
    final clamped = minutes.clamp(0, 120);
    if (stop.dwellMinutes == clamped) return;
    emit(
      state.copyWith(
        draft: state.draft.replaceStop(
          index,
          stop.copyWith(dwellMinutes: clamped),
        ),
      ),
    );
    _scheduleRecalculate();
  }

  void setBoarding(int index, RouteStopBoarding boarding) {
    final stop = _stopAt(index);
    if (stop == null) return;
    emit(
      state.copyWith(
        draft: state.draft.replaceStop(index, stop.copyWith(boarding: boarding)),
      ),
    );
  }

  void addStop() {
    final draft = state.draft.addStop();
    emit(
      state.copyWith(
        draft: draft,
        // Focus and arm the new stop: adding one always means "and here is
        // where it goes".
        activeIndex: draft.stops.length - 2,
        picking: !state.geoEnabled,
      ),
    );
  }

  void removeStop(int index) {
    final draft = state.draft.removeStop(index);
    if (identical(draft, state.draft)) return;
    emit(
      state.copyWith(
        draft: draft,
        activeIndex: -1,
        picking: false,
      ),
    );
    _scheduleRecalculate();
  }

  /// Flips the whole route end for end. Building the return leg of a route that
  /// already exists is the most common second route an office creates, and it
  /// used to mean retyping every point in reverse.
  void swapEndpoints() {
    if (state.draft.stops.length < 2) return;
    emit(
      state.copyWith(
        draft: state.draft.copyWith(
          stops: state.draft.stops.reversed.toList(),
        ),
        activeIndex: -1,
        picking: false,
      ),
    );
    _scheduleRecalculate();
  }

  void moveStop(int oldIndex, int newIndex) {
    final draft = state.draft.moveStop(oldIndex, newIndex);
    if (identical(draft, state.draft)) return;
    emit(state.copyWith(draft: draft, activeIndex: -1, picking: false));
    _scheduleRecalculate();
  }

  // ── Route identity ──────────────────────────────────────────────────

  void setName(String value) =>
      emit(state.copyWith(draft: state.draft.copyWith(nameOverride: value)));

  void setCode(String value) =>
      emit(state.copyWith(draft: state.draft.copyWith(codeOverride: value)));

  void setStatus(OperationRouteStatus status) =>
      emit(state.copyWith(draft: state.draft.copyWith(status: status)));

  /// Manual totals, used only when geocoding is unavailable.
  void setDistance(String value) =>
      emit(state.copyWith(draft: state.draft.copyWith(distance: value)));

  void setDuration(String value) =>
      emit(state.copyWith(draft: state.draft.copyWith(duration: value)));

  // ── Derived totals ──────────────────────────────────────────────────

  void _scheduleRecalculate({bool immediate = false}) {
    if (!state.geoEnabled) return;
    _debounce?.cancel();
    if (immediate) {
      unawaited(recalculate());
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), recalculate);
  }

  /// Asks the directions provider for the road distance, duration and shape of
  /// the current point order, then derives each stop's schedule from it.
  Future<void> recalculate() async {
    final points = state.draft.orderedPoints;
    if (!state.geoEnabled || points.length < 2) return;

    final token = ++_calculationToken;
    emit(state.copyWith(calculating: true, geoError: ''));
    try {
      final geometry = await _geometry(points);
      if (isClosed || token != _calculationToken) return;

      final schedule = RouteScheduleCalculator.computeStopOffsets(
        legs: geometry.legs,
        dwellMinutes: state.draft.stops.map((stop) => stop.dwellMinutes).toList(),
      );
      emit(
        state.copyWith(
          draft: state.draft
              .withSchedule(
                schedule
                    .map(
                      (entry) => (
                        arrival: entry.arrivalOffset,
                        departure: entry.departureOffset,
                      ),
                    )
                    .toList(),
              )
              .copyWith(
                distance: RouteScheduleCalculator.formatDistance(
                  geometry.totalDistanceMeters,
                ),
                duration: RouteScheduleCalculator.formatDuration(
                  geometry.totalDurationSeconds,
                ),
              ),
          calculating: false,
          path: geometry.path,
        ),
      );
    } catch (error) {
      if (isClosed || token != _calculationToken) return;
      emit(
        state.copyWith(
          calculating: false,
          geoError: error is GeoException ? error.message : error.toString(),
        ),
      );
    }
  }

  RouteStopDraft? _stopAt(int index) {
    if (index < 0 || index >= state.draft.stops.length) return null;
    return state.draft.stops[index];
  }

  String _defaultStopName(int index) {
    if (index == 0) return 'نقطة الانطلاق';
    if (index == state.draft.stops.length - 1) return 'الوجهة النهائية';
    return 'محطة $index';
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
