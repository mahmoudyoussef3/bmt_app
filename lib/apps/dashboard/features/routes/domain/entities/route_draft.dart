import 'package:bmt_app/core/geo/geo_models.dart';

import '../services/route_identity.dart';
import 'operation_route.dart';

/// What a stop is allowed to be used for when a client books a seat.
///
/// The old create form never asked, so every station it wrote allowed both —
/// while the route details screen exposed two separate checkboxes. One control
/// with three meaningful choices replaces the pair of booleans that could also
/// be set to the invalid "neither" combination.
enum RouteStopBoarding {
  both('صعود ونزول'),
  pickupOnly('صعود فقط'),
  dropoffOnly('نزول فقط');

  final String label;

  const RouteStopBoarding(this.label);

  bool get pickupAllowed => this != RouteStopBoarding.dropoffOnly;

  bool get dropoffAllowed => this != RouteStopBoarding.pickupOnly;

  static RouteStopBoarding fromFlags({
    required bool pickupAllowed,
    required bool dropoffAllowed,
  }) {
    if (pickupAllowed && !dropoffAllowed) return RouteStopBoarding.pickupOnly;
    if (!pickupAllowed && dropoffAllowed) return RouteStopBoarding.dropoffOnly;
    return RouteStopBoarding.both;
  }
}

/// One ordered point of a route being built. Index 0 is the origin, the last
/// index is the destination, everything between is an intermediate stop.
class RouteStopDraft {
  /// Stable local identity, used for widget keys and reordering. Unlike [id] it
  /// exists before the stop has ever been saved.
  final String key;

  /// `route_stations.id` once persisted; empty for a stop added in this session.
  final String id;
  final String name;
  final String area;
  final String description;
  final GeoPoint? point;

  /// Minutes the bus waits at this stop; feeds the arrival/departure schedule.
  final int dwellMinutes;
  final RouteStopBoarding boarding;

  /// `HH:MM` offsets from the route start, computed from the road geometry.
  final String arrivalOffset;
  final String departureOffset;
  final String notes;

  const RouteStopDraft({
    required this.key,
    this.id = '',
    this.name = '',
    this.area = '',
    this.description = '',
    this.point,
    this.dwellMinutes = 0,
    this.boarding = RouteStopBoarding.both,
    this.arrivalOffset = '',
    this.departureOffset = '',
    this.notes = '',
  });

  /// A local identity for a stop that has never been saved. Unique per call, so
  /// two stops added in the same second still reorder independently.
  static String freshKey() =>
      'stop-${DateTime.now().microsecondsSinceEpoch}-${_counter++}';

  static int _counter = 0;

  bool get isLocated => point != null;

  bool get isNamed => name.trim().isNotEmpty;

  /// A stop is valid as soon as it has a name. Coordinates are an optional
  /// refinement that improves what riders and captains see — never a
  /// precondition for saving the route.
  bool get isComplete => isNamed;

  RouteStopDraft copyWith({
    String? id,
    String? name,
    String? area,
    String? description,
    GeoPoint? point,
    bool clearPoint = false,
    int? dwellMinutes,
    RouteStopBoarding? boarding,
    String? arrivalOffset,
    String? departureOffset,
    String? notes,
  }) {
    return RouteStopDraft(
      key: key,
      id: id ?? this.id,
      name: name ?? this.name,
      area: area ?? this.area,
      description: description ?? this.description,
      point: clearPoint ? null : point ?? this.point,
      dwellMinutes: dwellMinutes ?? this.dwellMinutes,
      boarding: boarding ?? this.boarding,
      arrivalOffset: arrivalOffset ?? this.arrivalOffset,
      departureOffset: departureOffset ?? this.departureOffset,
      notes: notes ?? this.notes,
    );
  }

  /// Applies a picked place: title, area and coordinates in one move, which is
  /// what the operator means by "this is the stop".
  RouteStopDraft withPlace(GeoPlace place) {
    return copyWith(
      name: RouteIdentity.shortPlaceLabel(place.label),
      area: RouteIdentity.areaFromLabel(place.label),
      description: place.label,
      point: place.point,
    );
  }

  /// Applies a coordinate chosen on the map, keeping any name already typed.
  RouteStopDraft withPoint(GeoPoint value) => copyWith(point: value);

  /// Drops the coordinate. The stop stays valid and bookable — it simply loses
  /// its pin on the rider's and captain's maps.
  RouteStopDraft withoutPoint() => copyWith(clearPoint: true);
}

/// A blocking gap between the current draft and a saveable route. [stopIndex]
/// points at the stop to focus when the operator taps the issue.
class RouteDraftIssue {
  final String message;
  final int? stopIndex;

  const RouteDraftIssue(this.message, {this.stopIndex});
}

/// The route being built or edited, as an immutable value.
///
/// Everything the old form spread across seven cards and a `GlobalKey<FormState>`
/// lives here instead: identity, ordered points, computed totals. It is pure
/// Dart, so the rules that decide whether a route can be saved are testable
/// without pumping a widget.
class RouteDraft {
  final String id;

  /// Empty means "use the suggested name" — the operator has not overridden it.
  final String nameOverride;
  final String codeOverride;

  /// Sequential code reserved for this draft when the builder opened.
  final String suggestedCode;
  final OperationRouteStatus status;
  final List<RouteStopDraft> stops;
  final String distance;
  final String duration;
  final List<String> notes;

  const RouteDraft({
    required this.id,
    required this.stops,
    this.nameOverride = '',
    this.codeOverride = '',
    this.suggestedCode = '',
    this.status = OperationRouteStatus.active,
    this.distance = '',
    this.duration = '',
    this.notes = const [],
  });

  /// A fresh route: an origin and a destination, nothing else. Adding stops,
  /// naming and coding it are all optional refinements from here.
  factory RouteDraft.blank({required String suggestedCode}) {
    return RouteDraft(
      id: '',
      suggestedCode: suggestedCode,
      stops: [
        RouteStopDraft(key: RouteStopDraft.freshKey()),
        RouteStopDraft(key: RouteStopDraft.freshKey()),
      ],
    );
  }

  factory RouteDraft.fromRoute(OperationRoute route) {
    final stops = route.stations.indexed.map((entry) {
      final (index, station) = entry;
      return RouteStopDraft(
        key: station.id.isNotEmpty ? station.id : RouteStopDraft.freshKey(),
        id: station.id,
        name: station.name,
        area: station.area,
        description: station.locationDescription,
        point: (station.latitude != null && station.longitude != null)
            ? GeoPoint(station.latitude!, station.longitude!)
            : null,
        dwellMinutes: _dwellBetween(
          station.arrivalOffset,
          station.departureOffset,
        ),
        boarding: RouteStopBoarding.fromFlags(
          pickupAllowed: station.pickupAllowed,
          dropoffAllowed: station.dropoffAllowed,
        ),
        arrivalOffset: station.arrivalOffset,
        departureOffset: station.departureOffset,
        notes: station.notes,
      );
    }).toList();

    while (stops.length < 2) {
      stops.add(RouteStopDraft(key: RouteStopDraft.freshKey()));
    }

    return RouteDraft(
      id: route.id,
      nameOverride: route.name,
      codeOverride: route.routeCode,
      suggestedCode: route.routeCode,
      status: route.status == OperationRouteStatus.archived
          ? OperationRouteStatus.paused
          : route.status,
      stops: stops,
      distance: route.distance,
      duration: route.duration,
      notes: route.notes,
    );
  }

  bool get isEditing => id.isNotEmpty;

  RouteStopDraft get origin => stops.first;

  RouteStopDraft get destination => stops.last;

  /// Stops between the endpoints, paired with their index in [stops].
  List<({int index, RouteStopDraft stop})> get intermediateStops => stops
      .indexed
      .where((entry) => entry.$1 != 0 && entry.$1 != stops.length - 1)
      .map((entry) => (index: entry.$1, stop: entry.$2))
      .toList();

  String get suggestedName =>
      RouteIdentity.suggestName(origin.name, destination.name);

  /// What will actually be saved: the operator's text when they typed one, the
  /// suggestion otherwise.
  String get name =>
      nameOverride.trim().isNotEmpty ? nameOverride.trim() : suggestedName;

  String get code =>
      codeOverride.trim().isNotEmpty ? codeOverride.trim() : suggestedCode;

  bool get usesSuggestedName => nameOverride.trim().isEmpty;

  bool get usesSuggestedCode => codeOverride.trim().isEmpty;

  int get locatedStops => stops.where((stop) => stop.isLocated).length;

  bool get allStopsLocated => locatedStops == stops.length;

  bool get hasMetrics =>
      distance.trim().isNotEmpty && duration.trim().isNotEmpty;

  /// Ordered coordinates, used to draw the line and to ask the geo provider for
  /// distance/duration. Empty when any point is still missing.
  List<GeoPoint> get orderedPoints =>
      allStopsLocated ? stops.map((stop) => stop.point!).toList() : const [];

  /// The route direction as one readable sentence: `بنها ← شبين القناطر ← القاهرة`.
  /// Unnamed points are skipped, so it reads sensibly while still being filled in.
  String get directionLabel => stops
      .map((stop) => stop.name.trim())
      .where((name) => name.isNotEmpty)
      .join(' ← ');

  /// True when the two endpoints name the same place — a "route" that goes
  /// nowhere, and the one endpoint combination the operator must fix.
  bool get endpointsCollide {
    final from = origin.name.trim();
    final to = destination.name.trim();
    return from.isNotEmpty && from == to;
  }

  /// Everything still standing between this draft and a saved route, in the
  /// order the operator should deal with it.
  ///
  /// Coordinates are deliberately absent from this list. A stop is a *place the
  /// bus stops at*, and an operator knows those by name long before anyone has
  /// put them on a map; requiring a pin for each one is what made creating a
  /// route a mapping exercise instead of a two-field one.
  List<RouteDraftIssue> get issues {
    final result = <RouteDraftIssue>[];
    if (!origin.isNamed) {
      result.add(const RouteDraftIssue('حدد نقطة الانطلاق', stopIndex: 0));
    }
    if (!destination.isNamed) {
      result.add(
        RouteDraftIssue('حدد الوجهة النهائية', stopIndex: stops.length - 1),
      );
    }
    if (endpointsCollide) {
      result.add(
        RouteDraftIssue(
          'نقطة الانطلاق والوجهة نفس المكان — غيّر إحداهما',
          stopIndex: stops.length - 1,
        ),
      );
    }
    for (final entry in intermediateStops) {
      if (!entry.stop.isNamed) {
        result.add(
          RouteDraftIssue(
            'النقطة رقم ${entry.index + 1} بدون اسم',
            stopIndex: entry.index,
          ),
        );
      }
    }
    if (name.trim().isEmpty) {
      result.add(const RouteDraftIssue('أدخل اسم المسار'));
    }
    if (code.trim().isEmpty) {
      result.add(const RouteDraftIssue('أدخل كود المسار'));
    }
    return result;
  }

  bool get isReady => issues.isEmpty;

  RouteDraft copyWith({
    String? id,
    String? nameOverride,
    String? codeOverride,
    String? suggestedCode,
    OperationRouteStatus? status,
    List<RouteStopDraft>? stops,
    String? distance,
    String? duration,
    List<String>? notes,
  }) {
    return RouteDraft(
      id: id ?? this.id,
      nameOverride: nameOverride ?? this.nameOverride,
      codeOverride: codeOverride ?? this.codeOverride,
      suggestedCode: suggestedCode ?? this.suggestedCode,
      status: status ?? this.status,
      stops: stops ?? this.stops,
      distance: distance ?? this.distance,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
    );
  }

  RouteDraft replaceStop(int index, RouteStopDraft stop) {
    if (index < 0 || index >= stops.length) return this;
    final next = [...stops]..[index] = stop;
    return copyWith(stops: next);
  }

  /// Adds an intermediate stop just before the destination — the position that
  /// keeps the route's endpoints stable, which is what "add a stop on the way"
  /// means.
  RouteDraft addStop() => addStopAt(stops.length - 1);

  /// Inserts a new stop *at* [index], pushing everything from there onwards
  /// down. The timeline offers one "+ إضافة نقطة" per gap, so the operator says
  /// where the bus stops by pointing at the place in the journey it happens —
  /// no adding at the end and dragging it up.
  ///
  /// Index 0 and anything past the destination are clamped inside the
  /// endpoints, which can only be replaced, never displaced.
  RouteDraft addStopAt(int index, {RouteStopDraft? stop}) {
    final position = index.clamp(1, stops.length - 1);
    final next = [
      ...stops,
    ]..insert(position, stop ?? RouteStopDraft(key: RouteStopDraft.freshKey()));
    return copyWith(stops: next);
  }

  /// Endpoints are structural and can only be replaced, never removed.
  RouteDraft removeStop(int index) {
    if (index <= 0 || index >= stops.length - 1) return this;
    final next = [...stops]..removeAt(index);
    return copyWith(stops: next);
  }

  /// Reorders intermediate stops only; a drag that would displace an endpoint
  /// is ignored rather than silently turning the destination into a stop.
  RouteDraft moveStop(int oldIndex, int newIndex) {
    final last = stops.length - 1;
    if (oldIndex <= 0 || oldIndex >= last) return this;
    if (newIndex <= 0 || newIndex > last) return this;
    final next = [...stops];
    final moved = next.removeAt(oldIndex);
    next.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, moved);
    return copyWith(stops: next);
  }

  /// The same places in the opposite order.
  ///
  /// A route row is one *directed* chain — the client sells `pickup.order <
  /// dropoff.order` and nothing else — so the way back is a second route, not a
  /// flag on this one. This produces the draft for it: the stops reversed, the
  /// saved-row identity dropped so nothing overwrites the outbound route, and
  /// the schedule cleared because the offsets no longer describe this order.
  RouteDraft reversedLeg({required String suggestedCode}) {
    return RouteDraft(
      id: '',
      suggestedCode: suggestedCode,
      status: status,
      stops: [
        for (final stop in stops.reversed)
          stop.copyWith(id: '', arrivalOffset: '', departureOffset: ''),
      ],
      distance: distance,
      duration: duration,
    );
  }

  /// Writes the computed schedule back onto the stops, pairing by position.
  RouteDraft withSchedule(List<({String arrival, String departure})> schedule) {
    final next = [
      for (var i = 0; i < stops.length; i++)
        i < schedule.length
            ? stops[i].copyWith(
                arrivalOffset: schedule[i].arrival,
                departureOffset: schedule[i].departure,
              )
            : stops[i],
    ];
    return copyWith(stops: next);
  }

  OperationRoute toRoute() {
    final stations = stops.indexed.map((entry) {
      final (index, stop) = entry;
      final title = stop.name.trim();
      return RouteStation(
        id: stop.id,
        name: title,
        area: stop.area.trim().isEmpty
            ? RouteIdentity.shortPlaceLabel(title)
            : stop.area.trim(),
        arrivalOffset: stop.arrivalOffset,
        departureOffset: stop.departureOffset.isEmpty
            ? stop.arrivalOffset
            : stop.departureOffset,
        locationDescription: stop.description.trim().isEmpty
            ? title
            : stop.description.trim(),
        notes: stop.notes,
        latitude: stop.point?.lat,
        longitude: stop.point?.lng,
        pickupAllowed: stop.boarding.pickupAllowed,
        dropoffAllowed: stop.boarding.dropoffAllowed,
        estimatedArrivalTime: stop.arrivalOffset,
        order: index + 1,
      );
    }).toList();

    return OperationRoute(
      id: id,
      routeCode: code,
      name: name,
      startCity: RouteIdentity.shortPlaceLabel(origin.name),
      endCity: RouteIdentity.shortPlaceLabel(destination.name),
      duration: duration.trim(),
      distance: distance.trim(),
      status: status,
      stations: stations,
      notes: notes,
    );
  }

  /// Rebuilds dwell minutes from stored `HH:MM` offsets (departure − arrival).
  static int _dwellBetween(String arrival, String departure) {
    final from = _minutes(arrival);
    final to = _minutes(departure);
    if (from == null || to == null) return 0;
    final dwell = to - from;
    return dwell > 0 ? dwell : 0;
  }

  static int? _minutes(String hhmm) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(hhmm.trim());
    if (match == null) return null;
    return int.parse(match.group(1)!) * 60 + int.parse(match.group(2)!);
  }
}
