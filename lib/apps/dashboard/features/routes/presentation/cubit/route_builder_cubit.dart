import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/geo/geo_models.dart';

import '../../domain/entities/operation_route.dart';
import '../../domain/entities/route_draft.dart';
import '../../domain/services/route_identity.dart';
import '../../domain/services/route_schedule_calculator.dart';
import '../../domain/services/route_stop_library.dart';
import '../../domain/usecases/get_route_geometry_usecase.dart';
import 'route_builder_state.dart';

/// Drives the route builder: an ordered list of named places, plus totals that
/// keep themselves up to date once those places have coordinates.
///
/// Two things are *derived, never typed*: the route's identity (name `origin -
/// destination`, sequential `RT-nn` code) and its measurements (distance,
/// duration, per-stop arrival/departure offsets). There is no "احسب المسار"
/// button — recalculation is debounced and automatic, and simply does not
/// happen while some stop is still un-pinned.
///
/// What this cubit no longer has is an *armed map*. Placing a point used to be
/// a mode — arm the map, find the spot, tap, hope nothing else stole the arm —
/// which put the map at the centre of a job that is mostly typing two city
/// names. A location is now picked in a dialog that returns one coordinate, and
/// only when the operator asks for it.
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

  /// Opens the builder on a new route, on [route] to edit it, or on [draft] for
  /// a route prepared elsewhere (the return leg of an existing one).
  /// [existingCodes] are the codes already in use so a new route can reserve the
  /// next free one, and [library] is the office's own stops.
  void start({
    OperationRoute? route,
    RouteDraft? draft,
    Iterable<String> existingCodes = const [],
    RouteStopLibrary library = RouteStopLibrary.empty,
  }) {
    final opened =
        draft ??
        (route == null
            ? RouteDraft.blank(
                suggestedCode: RouteIdentity.suggestCode(existingCodes),
              )
            : RouteDraft.fromRoute(route));
    emit(
      RouteBuilderState(
        draft: opened,
        geoEnabled: _geometry.enabled,
        library: library,
      ),
    );
    if (opened.allStopsLocated) _scheduleRecalculate(immediate: true);
  }

  /// Marks which stop the operator is talking about, so the preview map can
  /// centre on it. Purely presentational — nothing about the draft changes.
  void focusStop(int index) {
    if (index < -1 || index >= state.draft.stops.length) return;
    if (state.activeIndex == index) return;
    emit(state.copyWith(activeIndex: index));
  }

  /// Sends the operator to the next unfinished point instead of making them
  /// hunt for it down the timeline.
  void focusNextIssue() {
    final target = state.draft.issues
        .map((issue) => issue.stopIndex)
        .whereType<int>()
        .firstOrNull;
    if (target == null) return;
    emit(state.copyWith(activeIndex: target));
  }

  /// Replaces a stop wholesale — what the stop editor returns when the operator
  /// confirms it.
  void applyStop(int index, RouteStopDraft stop) {
    final current = _stopAt(index);
    if (current == null) return;
    emit(
      state.copyWith(
        draft: state.draft.replaceStop(index, stop),
        activeIndex: index,
      ),
    );
    _scheduleRecalculate();
  }

  /// Fills a stop from a geocoder result: title, area and coordinates together,
  /// which is what the operator means by "this is the stop".
  void selectPlace(int index, GeoPlace place) {
    final stop = _stopAt(index);
    if (stop == null) return;
    applyStop(index, stop.withPlace(place));
  }

  /// Fills a stop from one the office already uses, coordinates included when
  /// that stop had them.
  void selectSuggestion(int index, RouteStopSuggestion suggestion) {
    final stop = _stopAt(index);
    if (stop == null) return;
    applyStop(index, suggestion.toStop(stop.key).copyWith(id: stop.id));
  }

  void renameStop(int index, String value) {
    final stop = _stopAt(index);
    if (stop == null || stop.name == value) return;
    emit(
      state.copyWith(
        draft: state.draft.replaceStop(index, stop.copyWith(name: value)),
      ),
    );
  }

  void setStopArea(int index, String value) {
    final stop = _stopAt(index);
    if (stop == null) return;
    emit(
      state.copyWith(
        draft: state.draft.replaceStop(index, stop.copyWith(area: value)),
      ),
    );
  }

  void setStopDescription(int index, String value) {
    final stop = _stopAt(index);
    if (stop == null) return;
    emit(
      state.copyWith(
        draft: state.draft.replaceStop(
          index,
          stop.copyWith(description: value),
        ),
      ),
    );
  }

  /// Saves a coordinate the operator chose on the map. Optional by design: a
  /// stop with no point is still a valid, bookable stop.
  void setStopPoint(int index, GeoPoint point) {
    final stop = _stopAt(index);
    if (stop == null) return;
    applyStop(index, stop.withPoint(point));
  }

  void clearStopPoint(int index) {
    final stop = _stopAt(index);
    if (stop == null || !stop.isLocated) return;
    emit(
      state.copyWith(
        draft: state.draft.replaceStop(index, stop.withoutPoint()),
        
        path: const [],
      ),
    );
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
        draft: state.draft.replaceStop(
          index,
          stop.copyWith(boarding: boarding),
        ),
      ),
    );
  }

  /// Inserts a stop at [index], pushing the rest of the journey down. Passing
  /// [stop] fills it in the same move — the editor collects the stop before the
  /// timeline gains a row, so a cancelled dialog leaves no blank behind.
  void addStopAt(int index, {RouteStopDraft? stop}) {
    final draft = state.draft.addStopAt(index, stop: stop);
    emit(
      state.copyWith(
        draft: draft,
        activeIndex: index.clamp(1, draft.stops.length - 2),
      ),
    );
    _scheduleRecalculate();
  }

  void addStop() => addStopAt(state.draft.stops.length - 1);

  void removeStop(int index) {
    final draft = state.draft.removeStop(index);
    if (identical(draft, state.draft)) return;
    emit(state.copyWith(draft: draft, activeIndex: -1));
    _scheduleRecalculate();
  }

  /// Flips the whole route end for end, in place.
  ///
  /// Used while *building*: the operator entered the two places the wrong way
  /// round. Turning a saved route into its return leg is a different act — it
  /// creates a second route — and lives on the details screen.
  void reverseDirection() {
    if (state.draft.stops.length < 2) return;
    emit(
      state.copyWith(
        draft: state.draft.copyWith(stops: state.draft.stops.reversed.toList()),
        activeIndex: -1,
      ),
    );
    _scheduleRecalculate();
  }

  void moveStop(int oldIndex, int newIndex) {
    final draft = state.draft.moveStop(oldIndex, newIndex);
    if (identical(draft, state.draft)) return;
    emit(state.copyWith(draft: draft, activeIndex: -1));
    _scheduleRecalculate();
  }

  void setName(String value) =>
      emit(state.copyWith(draft: state.draft.copyWith(nameOverride: value)));

  void setCode(String value) =>
      emit(state.copyWith(draft: state.draft.copyWith(codeOverride: value)));

  void setStatus(OperationRouteStatus status) =>
      emit(state.copyWith(draft: state.draft.copyWith(status: status)));

  /// Manual totals, for a route the provider cannot measure — no geocoding key,
  /// or stops the operator chose not to pin.
  void setDistance(String value) =>
      emit(state.copyWith(draft: state.draft.copyWith(distance: value)));

  void setDuration(String value) =>
      emit(state.copyWith(draft: state.draft.copyWith(duration: value)));

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
  ///
  /// Does nothing while any stop is un-pinned: there is no road to measure
  /// through a place the provider was never told the location of. The builder
  /// says so, and the route still saves.
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
        dwellMinutes: state.draft.stops
            .map((stop) => stop.dwellMinutes)
            .toList(),
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

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
