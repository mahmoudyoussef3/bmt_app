import 'package:bmt_app/core/geo/geo_models.dart';

import '../../domain/entities/route_draft.dart';

/// State of the route builder workspace.
///
/// One flat value rather than a sealed union: the builder is never "loading" or
/// "error" as a whole — it always shows an editable draft, and a failed
/// calculation or save is a message *inside* that draft, never a screen that
/// replaces the operator's work.
class RouteBuilderState {
  final RouteDraft draft;

  /// The stop currently expanded in the panel and highlighted on the map.
  /// `-1` when nothing is focused.
  final int activeIndex;

  /// True while the map is armed to place [activeIndex] on the next tap. The
  /// old form left every tap live, so a stray click on the map silently moved
  /// whichever point happened to be selected.
  final bool picking;

  final bool calculating;

  /// Why the last distance/duration calculation failed, if it did.
  final String geoError;

  /// Road shape returned by the directions provider, drawn instead of straight
  /// lines between stops when available.
  final List<GeoPoint> path;

  /// False when no geocoding key is configured: search is unavailable and the
  /// operator types distance and duration by hand.
  final bool geoEnabled;

  const RouteBuilderState({
    required this.draft,
    required this.geoEnabled,
    this.activeIndex = 0,
    this.picking = false,
    this.calculating = false,
    this.geoError = '',
    this.path = const [],
  });

  RouteBuilderState copyWith({
    RouteDraft? draft,
    int? activeIndex,
    bool? picking,
    bool? calculating,
    String? geoError,
    List<GeoPoint>? path,
    bool? geoEnabled,
  }) {
    return RouteBuilderState(
      draft: draft ?? this.draft,
      geoEnabled: geoEnabled ?? this.geoEnabled,
      activeIndex: activeIndex ?? this.activeIndex,
      picking: picking ?? this.picking,
      calculating: calculating ?? this.calculating,
      geoError: geoError ?? this.geoError,
      path: path ?? this.path,
    );
  }
}
