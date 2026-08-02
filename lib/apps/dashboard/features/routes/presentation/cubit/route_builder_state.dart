import 'package:bmt_app/core/geo/geo_models.dart';

import '../../domain/entities/route_draft.dart';
import '../../domain/services/route_stop_library.dart';

/// State of the route builder workspace.
///
/// One flat value rather than a sealed union: the builder is never "loading" or
/// "error" as a whole — it always shows an editable draft, and a failed
/// calculation or save is a message *inside* that draft, never a screen that
/// replaces the operator's work.
class RouteBuilderState {
  final RouteDraft draft;

  /// The stops the office already uses, offered when a new stop is named.
  final RouteStopLibrary library;

  /// The stop the operator last touched, highlighted on the preview map so the
  /// timeline and the map agree on what is being talked about. `-1` for none.
  final int activeIndex;

  final bool calculating;

  /// Why the last distance/duration calculation failed, if it did.
  final String geoError;

  /// Road shape returned by the directions provider, drawn instead of straight
  /// lines between stops when available.
  final List<GeoPoint> path;

  /// False when no geocoding key is configured: place search is unavailable and
  /// the operator types stop names, distance and duration by hand. Route
  /// creation itself never depends on it.
  final bool geoEnabled;

  const RouteBuilderState({
    required this.draft,
    required this.geoEnabled,
    this.library = RouteStopLibrary.empty,
    this.activeIndex = -1,
    this.calculating = false,
    this.geoError = '',
    this.path = const [],
  });

  /// Distance and duration are read off the road network, so they only exist
  /// once every stop has a pin and the provider has answered. Missing ones are
  /// a *pending* refinement, not a defect — the route saves and sells without
  /// them, and the operator may fill them in by hand.
  bool get metricsPending => !draft.hasMetrics;

  /// True when nothing is going to derive the totals, so the manual fields are
  /// the only way they will ever be filled.
  bool get metricsManual => metricsPending && !calculating;

  RouteBuilderState copyWith({
    RouteDraft? draft,
    RouteStopLibrary? library,
    int? activeIndex,
    bool? calculating,
    String? geoError,
    List<GeoPoint>? path,
    bool? geoEnabled,
  }) {
    return RouteBuilderState(
      draft: draft ?? this.draft,
      geoEnabled: geoEnabled ?? this.geoEnabled,
      library: library ?? this.library,
      activeIndex: activeIndex ?? this.activeIndex,
      calculating: calculating ?? this.calculating,
      geoError: geoError ?? this.geoError,
      path: path ?? this.path,
    );
  }
}
