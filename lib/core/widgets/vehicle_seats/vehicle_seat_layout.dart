import 'package:flutter/material.dart';

import 'package:bmt_app/core/vehicles/vehicles.dart';
import 'package:bmt_app/core/widgets/vehicle_seats/vehicle_seat.dart';
import 'package:bmt_app/core/widgets/vehicle_seats/vehicle_seat_data.dart';
import 'package:bmt_app/core/widgets/vehicle_seats/vehicle_seat_legend.dart';
import 'package:bmt_app/core/widgets/vehicle_seats/vehicle_seat_palette.dart';

/// How a seat map is being used. Modes change what the map *offers*, never what
/// it *renders* — the same cabin, the same tiles, the same geometry.
enum SeatLayoutMode {
  /// Shows the cabin and its states. No interaction.
  preview,

  /// A rider picking a seat. Taps are reported for seats the parent enabled.
  selection,

  /// An operator working the manifest. Taps are reported for every enabled
  /// seat, including ones that are already taken — reassigning a sold seat is
  /// a legitimate operator action, and deciding that is the parent's job.
  management,

  /// Pure visualisation, semantically distinct from [preview] for callers that
  /// want to say "this is a record, not a preview". Behaves identically.
  readOnly;

  bool get isInteractive =>
      this == SeatLayoutMode.selection || this == SeatLayoutMode.management;
}

/// How much room the map is allowed to take.
///
/// This is the only knob that changes seat size, and it changes it within
/// bounds — a seat never stretches to fill the width, because a vehicle whose
/// seats grow with the window stops looking like a vehicle.
enum SeatLayoutDensity {
  /// Dashboard cards, side panels, list previews.
  compact(minSeat: 26, maxSeat: 40, gap: 4, rowGap: 6, floorPadding: 10),

  /// The rider's booking map and any screen where the cabin is the subject.
  comfortable(minSeat: 40, maxSeat: 62, gap: 8, rowGap: 10, floorPadding: 16);

  const SeatLayoutDensity({
    required this.minSeat,
    required this.maxSeat,
    required this.gap,
    required this.rowGap,
    required this.floorPadding,
  });

  final double minSeat;
  final double maxSeat;
  final double gap;
  final double rowGap;

  /// Floor margin between the body wall and the outermost seats.
  final double floorPadding;
}

/// **The** vehicle seat map for the whole EWT ecosystem.
///
/// Give it a cabin [SeatLayoutBlueprint] and a list of [VehicleSeatData] and it
/// draws the vehicle: nose, windshield, driver area, aisle, seat banks, rear.
/// The Client App's booking flow, the Owner Dashboard's trip and fleet screens
/// and anything added later all render through this one widget, which is what
/// makes a seat look like an EWT seat wherever it appears.
///
/// Three rules hold the design together:
///
/// 1. **Layout and state are independent.** The blueprint says where seats sit;
///    [VehicleSeatData] says how each one reads. The same Hiace cabin serves a
///    rider picking a seat and an operator managing a manifest.
/// 2. **No business rules live here.** The widget reports [onSeatTap] and
///    nothing else. Whether a tap is allowed, what it costs, what it changes —
///    all of that is the parent's.
/// 3. **The vehicle keeps its proportions.** Seats are sized within the
///    density's bounds and the cabin is centred at its intrinsic width. It
///    never stretches to fill a desktop panel.
///
/// Seats map to slots by position: `seats[slot.seatNumber - 1]`. Supply them in
/// `(row, column)` reading order — the order every seat source in this codebase
/// already sorts into. Anything beyond the blueprint's capacity is drawn in the
/// overflow section instead of being silently dropped.
class VehicleSeatLayout extends StatelessWidget {
  const VehicleSeatLayout({
    super.key,
    required this.blueprint,
    required this.seats,
    this.mode = SeatLayoutMode.preview,
    this.density = SeatLayoutDensity.comfortable,
    this.onSeatTap,
    this.labels = const VehicleSeatLabels(),
    this.showLegend = false,
    this.showOrientationLabels = true,
    this.showWheels = true,
    this.caption,
    this.maxWidth,
    this.palette,
  });

  /// Resolves the cabin from a [VehicleType] instead of a prepared blueprint —
  /// the short form for callers that have a type and a seat list and nothing
  /// else.
  ///
  /// A modelled type always gets its own cabin, on the same grounds as
  /// [VehicleSeatLayouts.resolve]: a vehicle's physical layout is a property of
  /// the vehicle, not of how many seat rows happen to be configured. Only a
  /// type with no blueprint is drawn as a derived grid.
  factory VehicleSeatLayout.forType({
    Key? key,
    required VehicleType type,
    required List<VehicleSeatData> seats,
    SeatLayoutMode mode = SeatLayoutMode.preview,
    SeatLayoutDensity density = SeatLayoutDensity.comfortable,
    ValueChanged<VehicleSeatData>? onSeatTap,
    VehicleSeatLabels labels = const VehicleSeatLabels(),
    bool showLegend = false,
    bool showOrientationLabels = true,
    bool showWheels = true,
    String? caption,
    double? maxWidth,
    VehicleSeatPalette? palette,
  }) {
    final defined = VehicleSeatLayouts.blueprintFor(type);
    final blueprint = defined != null && seats.isNotEmpty
        ? defined
        : SeatLayoutBlueprint.fromSeatGrid([
            for (var i = 0; i < seats.length; i++)
              (row: (i ~/ 4) + 1, column: (i % 4) + 1),
          ]);

    return VehicleSeatLayout(
      key: key,
      blueprint: blueprint,
      seats: seats,
      mode: mode,
      density: density,
      onSeatTap: onSeatTap,
      labels: labels,
      showLegend: showLegend,
      showOrientationLabels: showOrientationLabels,
      showWheels: showWheels,
      caption: caption,
      maxWidth: maxWidth,
      palette: palette,
    );
  }

  final SeatLayoutBlueprint blueprint;
  final List<VehicleSeatData> seats;
  final SeatLayoutMode mode;
  final SeatLayoutDensity density;

  /// Reported when an enabled seat is tapped in an interactive [mode]. The
  /// widget takes no action of its own.
  final ValueChanged<VehicleSeatData>? onSeatTap;

  final VehicleSeatLabels labels;

  /// Off by default. A legend earns its place on a booking screen and clutters
  /// a compact card, so the parent decides. Only states actually present in
  /// [seats] are listed.
  final bool showLegend;

  final bool showOrientationLabels;
  final bool showWheels;

  /// A line under the cabin naming the vehicle, its capacity, or a caveat.
  final String? caption;

  final double? maxWidth;
  final VehicleSeatPalette? palette;

  @override
  Widget build(BuildContext context) {
    final colors = palette ?? VehicleSeatPalette.of(context);
    final overflow = seats.length > blueprint.capacity
        ? seats.sublist(blueprint.capacity)
        : const <VehicleSeatData>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showLegend) ...[
          VehicleSeatLegend(
            states: {for (final seat in seats) seat.state}.toList(),
            labels: labels,
            palette: colors,
          ),
          SizedBox(height: density.floorPadding),
        ],
        Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final geometry = _CabinGeometry.resolve(
                blueprint: blueprint,
                density: density,
                availableWidth: _availableWidth(constraints),
              );
              return _Cabin(
                blueprint: blueprint,
                seats: seats,
                geometry: geometry,
                colors: colors,
                labels: labels,
                mode: mode,
                onSeatTap: onSeatTap,
                showOrientationLabels: showOrientationLabels,
                showWheels: showWheels,
              );
            },
          ),
        ),
        if (caption != null) ...[
          SizedBox(height: density.floorPadding * 0.5),
          Text(
            caption!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.caption,
            ),
          ),
        ],
        if (overflow.isNotEmpty) ...[
          SizedBox(height: density.floorPadding),
          _OverflowSeats(
            seats: overflow,
            geometry: _CabinGeometry.resolve(
              blueprint: blueprint,
              density: density,
              availableWidth: maxWidth ?? 320,
            ),
            colors: colors,
            labels: labels,
            mode: mode,
            onSeatTap: onSeatTap,
          ),
        ],
      ],
    );
  }

  double _availableWidth(BoxConstraints constraints) {
    final bounded = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : (maxWidth ?? 420);
    return maxWidth == null ? bounded : bounded.clamp(0.0, maxWidth!);
  }
}

/// Where every cell of the cabin sits, in one place.
///
/// Pulled out of the widget because the aisle channel has to be drawn *behind*
/// the rows to run continuously through the row gaps, which means two different
/// painters need to agree on the same coordinates. Being a plain value object,
/// it is also the part that can be unit-tested without pumping a widget.
@immutable
class _CabinGeometry {
  const _CabinGeometry({
    required this.seatSize,
    required this.columnWidths,
    required this.gap,
    required this.rowGap,
    required this.floorPadding,
    required this.rows,
    required this.frontCabinRows,
    required this.benchRows,
    required this.bulkheadHeight,
  });

  /// An aisle's share of a seat's width.
  ///
  /// A walkway is floor, not a seat that was left out, so it must not be a
  /// seat wide. Getting this wrong is most of what makes a seat map look like a
  /// spreadsheet: a Hiace with five equal columns is drawn a fifth wider than
  /// the vehicle is, and the rows stop reading as `2 + 1`.
  static const double aisleWidthFactor = 0.58;

  factory _CabinGeometry.resolve({
    required SeatLayoutBlueprint blueprint,
    required SeatLayoutDensity density,
    required double availableWidth,
  }) {
    final columns = blueprint.columns == 0 ? 1 : blueprint.columns;
    final aisles = blueprint.aisleColumns;
    // Width is measured in seat-widths: aisle columns count for a fraction of
    // one, so narrowing the walkway widens the seats instead of shrinking the
    // vehicle.
    final units = (columns - aisles.length) + aisles.length * aisleWidthFactor;
    final chrome = (density.floorPadding + _Cabin.wallWidth) * 2;
    final forSeats = availableWidth - chrome - density.gap * (columns - 1);
    final seatSize = (forSeats / (units <= 0 ? 1 : units))
        .clamp(density.minSeat, density.maxSeat)
        .toDouble();

    // The front cabin is the driver's compartment at the nose of the vehicle.
    // A derived grid describes none — `trip_seats` holds no driver row — and
    // then the vehicle is undivided, because guessing a bulkhead from
    // passenger seats alone would be inventing structure.
    final frontCabinRows = blueprint.frontCabinRows;

    return _CabinGeometry(
      seatSize: seatSize,
      columnWidths: [
        for (var column = 1; column <= columns; column++)
          aisles.contains(column) ? seatSize * aisleWidthFactor : seatSize,
      ],
      gap: density.gap,
      rowGap: density.rowGap,
      floorPadding: density.floorPadding,
      rows: blueprint.rows.length,
      frontCabinRows: frontCabinRows,
      benchRows: blueprint.benchRows,
      bulkheadHeight: frontCabinRows == 0 ? 0 : density.rowGap * 2.4,
    );
  }

  final double seatSize;

  /// Width of each 1-based cabin column, seat columns and aisle columns alike.
  final List<double> columnWidths;

  final double gap;
  final double rowGap;
  final double floorPadding;
  final int rows;

  /// How many rows at the front belong to the driver's compartment. Zero when
  /// the cabin does not describe one.
  final int frontCabinRows;

  /// Rows that span the cabin as a bench rather than sitting in the columns.
  final Set<int> benchRows;

  /// The height of the divide between the front cabin and the passenger cabin.
  final double bulkheadHeight;

  int get columns => columnWidths.length;

  double get contentWidth =>
      columnWidths.fold<double>(0, (sum, w) => sum + w) + gap * (columns - 1);

  double get contentHeight =>
      rows == 0 ? 0 : seatSize * rows + rowGap * (rows - 1) + bulkheadHeight;

  double get cabinWidth => contentWidth + (floorPadding + _Cabin.wallWidth) * 2;

  double columnWidth(int column) =>
      column >= 0 && column < columns ? columnWidths[column] : seatSize;

  /// Left edge of the 0-based [column].
  double columnLeft(int column) {
    var left = 0.0;
    for (var c = 0; c < column && c < columns; c++) {
      left += columnWidths[c] + gap;
    }
    return left;
  }

  double rowTop(int row) {
    final base = row * (seatSize + rowGap);
    return frontCabinRows > 0 && row >= frontCabinRows
        ? base + bulkheadHeight
        : base;
  }

  /// Where the front cabin ends and the passenger cabin begins.
  double get bulkheadTop =>
      rowTop(frontCabinRows - 1) + seatSize + bulkheadHeight / 2;

  /// One seat's width on a bench of [count] seats.
  ///
  /// A bench spans the cabin wall to wall, so its seats take whatever width is
  /// left after the gaps between them — a little narrower than the seats in
  /// front when the cabin gave up an aisle to fit the extra one, which is
  /// exactly the physical trade the vehicle makes.
  ///
  /// Never *wider* than a normal seat, though: a short bench in a wide cabin
  /// would otherwise inflate into oversized tiles. It stays seat-sized and is
  /// centred instead, which is what [benchLeft] does with the slack.
  double benchSeatSize(int count) {
    if (count <= 0) return seatSize;
    final spread = (contentWidth - gap * (count - 1)) / count;
    return spread < seatSize ? spread : seatSize;
  }

  /// Left edge of the [index]-th seat on a bench of [count].
  double benchLeft(int index, int count) {
    final size = benchSeatSize(count);
    final span = size * count + gap * (count - 1);
    return (contentWidth - span) / 2 + index * (size + gap);
  }
}

/// The vehicle body: nose, windshield, driver area, cabin floor, rear.
class _Cabin extends StatelessWidget {
  const _Cabin({
    required this.blueprint,
    required this.seats,
    required this.geometry,
    required this.colors,
    required this.labels,
    required this.mode,
    required this.onSeatTap,
    required this.showOrientationLabels,
    required this.showWheels,
  });

  final SeatLayoutBlueprint blueprint;
  final List<VehicleSeatData> seats;
  final _CabinGeometry geometry;
  final VehicleSeatPalette colors;
  final VehicleSeatLabels labels;
  final SeatLayoutMode mode;
  final ValueChanged<VehicleSeatData>? onSeatTap;
  final bool showOrientationLabels;
  final bool showWheels;

  static const double wallWidth = 2;

  @override
  Widget build(BuildContext context) {
    if (blueprint.rows.isEmpty) return const SizedBox.shrink();

    final nose = (geometry.seatSize * 1.1).clamp(28.0, 60.0).toDouble();
    final wheel = (geometry.seatSize * 0.26).clamp(8.0, 16.0).toDouble();

    final body = Container(
      width: geometry.cabinWidth,
      padding: EdgeInsets.all(geometry.floorPadding),
      decoration: BoxDecoration(
        color: colors.cabinFill,
        border: Border.all(color: colors.cabinBorder, width: wallWidth),
        // A rounded nose and a squarer tail: the silhouette that says which end
        // of the drawing is the front before a single label is read.
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(nose),
          topRight: Radius.circular(nose),
          bottomLeft: Radius.circular(geometry.seatSize * 0.4),
          bottomRight: Radius.circular(geometry.seatSize * 0.4),
        ),
        // Just enough lift to read as an object sitting on the page rather
        // than a panel drawn on it.
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.10),
            blurRadius: geometry.seatSize * 0.34,
            offset: Offset(0, geometry.seatSize * 0.10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Windshield(
            colors: colors,
            label: showOrientationLabels ? labels.front : null,
            height: (geometry.seatSize * 0.42).clamp(14.0, 26.0).toDouble(),
            radius: nose * 0.7,
          ),
          SizedBox(height: geometry.rowGap),
          // A cabin is a physical object and does not mirror with the writing
          // system. Column 1 of a blueprint is the driver's side of a
          // left-hand-drive vehicle, so under Arabic the ambient RTL would flip
          // the whole vehicle: steering wheel on the wrong side, the aisle on
          // the wrong side, every window seat against the opposite wall from
          // the one the rider will actually sit by. Seat labels travel with
          // their tile, so pinning the grid to LTR changes nothing about which
          // seat a number refers to.
          Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              width: geometry.contentWidth,
              height: geometry.contentHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (geometry.frontCabinRows > 0) ...[
                    _frontCabinFloor(),
                    _bulkhead(),
                  ],
                  ..._aisleChannels(),
                  ..._slots(),
                ],
              ),
            ),
          ),
          SizedBox(height: geometry.rowGap),
          if (showOrientationLabels)
            Text(
              labels.rear,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: colors.caption,
              ),
            ),
        ],
      ),
    );

    if (!showWheels) return body;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        body,
        Positioned(
          left: -wheel * 0.35,
          top: geometry.seatSize * 1.4,
          child: _Wheel(size: wheel, colors: colors),
        ),
        Positioned(
          right: -wheel * 0.35,
          top: geometry.seatSize * 1.4,
          child: _Wheel(size: wheel, colors: colors),
        ),
        Positioned(
          left: -wheel * 0.35,
          bottom: geometry.seatSize * 1.1,
          child: _Wheel(size: wheel, colors: colors),
        ),
        Positioned(
          right: -wheel * 0.35,
          bottom: geometry.seatSize * 1.1,
          child: _Wheel(size: wheel, colors: colors),
        ),
      ],
    );
  }

  /// The walkway, drawn as one lane of floor running the length of the cabin.
  ///
  /// Not a blank column: an empty gap reads as a missing seat, whereas a lane
  /// that runs unbroken from the front cabin to the rear wall reads as
  /// somewhere to walk. Consecutive aisle cells in the same column merge into a
  /// single lane so the row gaps cannot chop it into dashes, and where the lane
  /// begins at the bulkhead it is drawn right up to it — the aisle is the way
  /// through from the driver's compartment, not a channel that starts somewhere
  /// in the middle of the vehicle.
  List<Widget> _aisleChannels() {
    final channels = <Widget>[];

    for (var c = 0; c < geometry.columns; c++) {
      var start = -1;
      for (var r = 0; r <= geometry.rows; r++) {
        final isAisle =
            r < geometry.rows &&
            c < blueprint.rows[r].length &&
            blueprint.rows[r][c].kind == SeatSlotKind.aisle;

        if (isAisle && start < 0) start = r;
        if (!isAisle && start >= 0) {
          final end = r - 1;
          final top =
              geometry.frontCabinRows > 0 && start == geometry.frontCabinRows
              ? geometry.bulkheadTop
              : geometry.rowTop(start) + geometry.seatSize * 0.06;
          // Run to the rear wall, or right up to the bench that ends it — the
          // walkway stops where the vehicle stops having one, not a row early.
          final bottom = end == geometry.rows - 1
              ? geometry.rowTop(end) + geometry.seatSize
              : geometry.benchRows.contains(end + 1)
              ? geometry.rowTop(end) + geometry.seatSize + geometry.rowGap * 0.5
              : geometry.rowTop(end) + geometry.seatSize * 0.94;
          final width = geometry.columnWidth(c);

          channels.add(
            Positioned(
              left: geometry.columnLeft(c),
              top: top,
              height: bottom - top,
              width: width,
              child: DecoratedBox(
                // Keyed so a test can assert the walkway is *one* lane over the
                // rows it serves, which is the whole difference between an
                // aisle and a column of gaps.
                key: ValueKey('cabin-aisle-${c + 1}-${start + 1}'),
                decoration: BoxDecoration(
                  color: colors.aisle.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(width * 0.4),
                ),
              ),
            ),
          );
          start = -1;
        }
      }
    }
    return channels;
  }

  /// The driver's compartment, drawn as a compartment.
  ///
  /// The requirement that the front of the vehicle be immediately
  /// distinguishable is not met by a different tile colour alone — the split
  /// has to be structural. So the front rows get their own floor, bled out to
  /// the body walls, and the passenger cabin starts below it.
  Widget _frontCabinFloor() {
    final pad = geometry.floorPadding;
    final bottom = geometry.bulkheadTop;

    return Positioned(
      left: -pad,
      right: -pad,
      top: -geometry.rowGap * 0.6,
      height: bottom + geometry.rowGap * 0.6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.fixtureFill.withValues(alpha: 0.6),
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(geometry.seatSize * 0.28),
          ),
        ),
      ),
    );
  }

  /// The line the front cabin ends on.
  Widget _bulkhead() {
    final pad = geometry.floorPadding;

    return Positioned(
      left: -pad,
      right: -pad,
      top: geometry.bulkheadTop - 1,
      height: 2,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.cabinBorder.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  /// Whether the empty front-left cell of a **derived** grid is the driver's
  /// place.
  ///
  /// A blueprint states where the driver sits; a grid derived from seat data
  /// cannot, because `trip_seats` only ever holds passenger seats. But every
  /// seat generator in this codebase puts the driver at (1, 1) — both cabin
  /// blueprints and `SeatConfiguration.generateDefault` — so a front-left hole
  /// in a derived grid is the driver's place and nothing else. Drawing the
  /// bench there is what makes an operator-defined van still read as a cabin
  /// instead of a floating block of seats.
  bool get _inferDriverAtFrontLeft {
    if (blueprint.rows.isEmpty || blueprint.rows.first.isEmpty) return false;
    // Never on top of a blueprint that already says where the driver is.
    final hasRealDriver = blueprint.rows.any(
      (row) => row.any((slot) => slot.kind == SeatSlotKind.driver),
    );
    return !hasRealDriver && blueprint.rows.first.first.isGap;
  }

  List<Widget> _slots() {
    final widgets = <Widget>[];
    final inferredDriver = _inferDriverAtFrontLeft;

    for (var r = 0; r < blueprint.rows.length; r++) {
      if (geometry.benchRows.contains(r)) {
        widgets.addAll(_bench(r));
        continue;
      }

      for (final slot in blueprint.rows[r]) {
        if (slot.isGap) {
          if (!(inferredDriver && r == 0 && slot.column == 1)) continue;
          widgets.add(
            Positioned(
              left: geometry.columnLeft(slot.column - 1),
              top: geometry.rowTop(r),
              width: geometry.seatSize,
              height: geometry.seatSize,
              child: VehicleSeatFixture(
                kind: VehicleFixtureKind.driver,
                size: geometry.seatSize,
                label: labels.driver,
                palette: colors,
              ),
            ),
          );
          continue;
        }

        final child = switch (slot.kind) {
          SeatSlotKind.seat => _seat(slot),
          // Column 1 is the driver's own place in the fixed left-hand-drive
          // coordinate system every blueprint is written in; the rest of the
          // bench is crew seating.
          //
          // The driver position always says so — it is the most useful thing
          // that tile can say. The rest of the bench prefers the blueprint's
          // own label (`A2` on a Hiace), because those labels are the same
          // row-letter coordinates the passenger seats use, and dropping them
          // would break the front row out of that language.
          SeatSlotKind.driver => VehicleSeatFixture(
            kind: slot.column == 1
                ? VehicleFixtureKind.driver
                : VehicleFixtureKind.coDriver,
            size: geometry.seatSize,
            label: slot.column == 1
                ? labels.driver
                : slot.label.isEmpty
                ? labels.coDriver
                : slot.label,
            palette: colors,
          ),
          SeatSlotKind.door => VehicleSeatFixture(
            kind: VehicleFixtureKind.door,
            size: geometry.seatSize,
            label: labels.door,
            palette: colors,
          ),
          _ => null,
        };
        if (child == null) continue;

        widgets.add(
          Positioned(
            left: geometry.columnLeft(slot.column - 1),
            top: geometry.rowTop(r),
            width: geometry.seatSize,
            height: geometry.seatSize,
            child: child,
          ),
        );
      }
    }
    return widgets;
  }

  /// A bench row: seats flush against each other, spanning the cabin.
  ///
  /// Laid out across the full floor width rather than in the seat columns,
  /// because that is what the row physically is — the point where the vehicle
  /// gives up its aisle to fit one more seat across. Placing it on the grid
  /// instead would leave the extra seat stranded on the far side of a walkway
  /// that does not exist back there.
  List<Widget> _bench(int row) {
    final slots = blueprint.rows[row];
    final size = geometry.benchSeatSize(slots.length);
    // Slightly narrower seats than the rows in front, centred in the row band
    // so the bench still lines up with them vertically.
    final top = geometry.rowTop(row) + (geometry.seatSize - size) / 2;

    return [
      for (var i = 0; i < slots.length; i++)
        if (_seat(slots[i], size: size) case final child?)
          Positioned(
            left: geometry.benchLeft(i, slots.length),
            top: top,
            width: size,
            height: size,
            child: child,
          ),
    ];
  }

  Widget? _seat(SeatSlot slot, {double? size}) {
    final index = slot.seatNumber - 1;
    // A blueprint slot with no seat behind it. Drawing a placeholder would
    // invent inventory, so the cell is simply left as cabin floor.
    if (index < 0 || index >= seats.length) return null;

    final seat = seats[index];
    return VehicleSeat(
      key: ValueKey('seat-${seat.id}'),
      seat: seat,
      size: size ?? geometry.seatSize,
      palette: colors,
      onTap: mode.isInteractive && seat.enabled && onSeatTap != null
          ? () => onSeatTap!(seat)
          : null,
    );
  }
}

/// The front glass. With the rounded nose above it, the one cue that orients
/// the whole drawing.
class _Windshield extends StatelessWidget {
  const _Windshield({
    required this.colors,
    required this.label,
    required this.height,
    required this.radius,
  });

  final VehicleSeatPalette colors;
  final String? label;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.fixtureFill,
        border: Border.all(color: colors.fixtureBorder),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(radius),
          bottom: const Radius.circular(6),
        ),
      ),
      child: label == null
          ? null
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  label!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: colors.caption,
                  ),
                ),
              ),
            ),
    );
  }
}

class _Wheel extends StatelessWidget {
  const _Wheel({required this.size, required this.colors});

  final double size;
  final VehicleSeatPalette colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * 0.62,
      decoration: BoxDecoration(
        color: colors.cabinBorder,
        borderRadius: BorderRadius.circular(size),
      ),
    );
  }
}

/// Seats the trip carries beyond what the cabin blueprint can hold.
///
/// They happen — a vehicle re-typed after its trips were created, say — and
/// they are real, bookable inventory. Hiding them would hide seats that exist,
/// so they are listed outside the vehicle rather than forced into it.
class _OverflowSeats extends StatelessWidget {
  const _OverflowSeats({
    required this.seats,
    required this.geometry,
    required this.colors,
    required this.labels,
    required this.mode,
    required this.onSeatTap,
  });

  final List<VehicleSeatData> seats;
  final _CabinGeometry geometry;
  final VehicleSeatPalette colors;
  final VehicleSeatLabels labels;
  final SeatLayoutMode mode;
  final ValueChanged<VehicleSeatData>? onSeatTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${labels.overflow} (${seats.length})',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: colors.caption,
          ),
        ),
        SizedBox(height: geometry.rowGap),
        Wrap(
          spacing: geometry.gap,
          runSpacing: geometry.rowGap,
          children: [
            for (final seat in seats)
              VehicleSeat(
                key: ValueKey('seat-${seat.id}'),
                seat: seat,
                size: geometry.seatSize,
                palette: colors,
                onTap: mode.isInteractive && seat.enabled && onSeatTap != null
                    ? () => onSeatTap!(seat)
                    : null,
              ),
          ],
        ),
      ],
    );
  }
}
