/// The **layout** half of the seat system — where seats sit in the cabin,
/// which side the aisle is on, where the driver and the door are.
///
/// This is deliberately separate from **seat data** (`trip_seats` rows: id,
/// label, row, column, state). Seat data says which seats exist and whether
/// they are free; a blueprint says how to draw them. Both apps render the same
/// blueprint with their own tiles, so the Owner Dashboard and the Client App
/// can look different while describing the same physical vehicle.
///
/// Pure Dart on purpose: no Flutter, no Supabase. See `vehicle_seat_layouts.dart`
/// for the per-vehicle-type blueprints and the resolver both apps call.
library;

/// What occupies one cell of the cabin grid.
enum SeatSlotKind {
  /// A bookable passenger seat.
  seat,

  /// The driver / co-driver bench. Never bookable.
  driver,

  /// The passenger entrance. Never bookable — drawn so the rider can tell
  /// front from rear and which seats sit by the door.
  door,

  /// The walkway between seat banks. Rendered as a gap.
  aisle,

  /// Structural empty space (wheel arch, cowl). Rendered as a gap.
  blank,
}

/// One cell of the cabin grid.
class SeatSlot {
  const SeatSlot({
    required this.kind,
    required this.row,
    required this.column,
    this.seatNumber = 0,
    this.label = '',
    this.isWindow = false,
  });

  final SeatSlotKind kind;

  /// 1-based grid position. [column] counts aisle/blank cells too, so it is a
  /// drawing coordinate — the same coordinate persisted for real seats.
  final int row;
  final int column;

  /// 1-based seat number in reading order, or 0 for non-seat slots.
  final int seatNumber;

  /// Decoration text for [SeatSlotKind.driver] / [SeatSlotKind.door] cells.
  final String label;

  /// Whether the slot sits against an outer wall of the cabin.
  final bool isWindow;

  bool get isSeat => kind == SeatSlotKind.seat;

  /// Whether the slot renders as empty space rather than a tile.
  bool get isGap => kind == SeatSlotKind.aisle || kind == SeatSlotKind.blank;
}

/// A seat as it is **stored**, not as it is drawn: what the Owner Dashboard
/// writes into `vehicles.seat_configuration` and what trip creation copies into
/// `trip_seats`.
class SeatDefinition {
  const SeatDefinition({
    required this.label,
    required this.row,
    required this.column,
    this.isDriver = false,
  });

  final String label;
  final int row;
  final int column;
  final bool isDriver;
}

/// A complete cabin layout: a grid of [SeatSlot]s plus the derived seat list.
class SeatLayoutBlueprint {
  const SeatLayoutBlueprint({
    required this.rows,
    required this.capacity,
    required this.columns,
    this.driverLabels = const [],
  });

  /// The cabin grid, front row first.
  final List<List<SeatSlot>> rows;

  /// How many bookable seats the blueprint describes.
  final int capacity;

  /// Widest row, counting aisle and blank cells.
  final int columns;

  /// Labels shown on the driver bench, front to back.
  final List<String> driverLabels;

  /// Every bookable slot in reading order — the order real seat data is
  /// poured into. See [seatSlotAt].
  List<SeatSlot> get seatSlots => [
    for (final row in rows)
      for (final slot in row)
        if (slot.isSeat) slot,
  ];

  /// How many leading rows form the **front cabin** — the driver's compartment,
  /// which is a different part of the vehicle from the passenger cabin behind
  /// it and is drawn as one.
  ///
  /// Derived rather than declared: a front cabin is exactly the run of rows at
  /// the nose of the vehicle that hold a driver position. A grid derived from
  /// seat data has none (`trip_seats` never stores the driver), and then the
  /// cabin is undivided — guessing a bulkhead from passenger seats alone would
  /// be inventing structure.
  int get frontCabinRows {
    var count = 0;
    for (final row in rows) {
      if (!row.any((slot) => slot.kind == SeatSlotKind.driver)) break;
      count++;
    }
    // A front cabin that swallowed the whole vehicle is not a front cabin.
    return count == rows.length ? 0 : count;
  }

  /// The rows of the passenger cabin, front to back — everything behind
  /// [frontCabinRows].
  List<List<SeatSlot>> get passengerCabinRows => rows.sublist(frontCabinRows);

  /// The rows that are a **bench**: seats all the way across, wall to wall,
  /// with no walkway through them.
  ///
  /// A rear bench is not a row of the seat grid — it is where the cabin runs
  /// out of aisle and fits one more seat across, which is why its seats are
  /// slightly narrower than the ones in front of them and why they sit flush
  /// against each other rather than in the columns above. Drawing it on the
  /// grid is what makes the last seat look like a stray single.
  ///
  /// Derived, not declared: a row with nothing but seats in it has nowhere to
  /// walk, and that is exactly what a bench is.
  Set<int> get benchRows => {
    for (var r = 0; r < rows.length; r++)
      if (rows[r].isNotEmpty && rows[r].every((slot) => slot.isSeat)) r,
  };

  /// The 1-based columns that are walkway for the whole length of the cabin.
  ///
  /// A column counts as aisle when some row walks through it and **no** row
  /// puts a seat, a driver or a door in it. That is what makes the walkway one
  /// channel rather than a per-row gap: the renderer can narrow these columns
  /// and run a single line down them, and a row that happens to leave the
  /// column empty (the front cabin's walk-through) does not break the channel.
  ///
  /// Bench rows are ignored here. A bench spans the cabin instead of sitting in
  /// the columns, so the seat it puts "in" the aisle column is not a seat in
  /// the aisle — counting it would close the walkway for the whole vehicle.
  Set<int> get aisleColumns {
    final benches = benchRows;
    final walked = <int>{};
    final occupied = <int>{};
    for (var r = 0; r < rows.length; r++) {
      if (benches.contains(r)) continue;
      for (final slot in rows[r]) {
        if (slot.kind == SeatSlotKind.aisle) {
          walked.add(slot.column);
        } else if (!slot.isGap) {
          occupied.add(slot.column);
        }
      }
    }
    return walked.difference(occupied);
  }

  /// How many bookable seats sit in each row, front to back. The shape of the
  /// cabin in one line — `[1, 3, 3, 3, 4]` is a Hiace.
  List<int> get seatsPerRow => [
    for (final row in rows) row.where((slot) => slot.isSeat).length,
  ];

  /// The slot that holds the `index`-th real seat (0-based), or null when the
  /// blueprint has fewer slots than the trip has seats.
  SeatSlot? seatSlotAt(int index) {
    final slots = seatSlots;
    return index >= 0 && index < slots.length ? slots[index] : null;
  }

  /// The seat rows as the Owner Dashboard persists them.
  ///
  /// Seats are labelled `'1'`..`'N'` in reading order — the same labels
  /// `SeatConfiguration.generateDefault` has always produced — so an operator's
  /// manifest, the rider's ticket and `trip_seats.seat_label` all agree.
  List<SeatDefinition> seatDefinitions() {
    final definitions = <SeatDefinition>[];
    for (final row in rows) {
      for (final slot in row) {
        if (slot.kind == SeatSlotKind.driver) {
          definitions.add(
            SeatDefinition(
              label: slot.label.isEmpty ? 'D' : slot.label,
              row: slot.row,
              column: slot.column,
              isDriver: true,
            ),
          );
        } else if (slot.isSeat) {
          definitions.add(
            SeatDefinition(
              label: '${slot.seatNumber}',
              row: slot.row,
              column: slot.column,
            ),
          );
        }
      }
    }
    return definitions;
  }

  /// Builds a blueprint from a compact text grid, one string per cabin row.
  ///
  /// Tokens, space-separated:
  /// `S` seat · `D` driver · `^` door · `|` aisle · `.` blank.
  /// `D` and `^` take an optional `:label` suffix (`D:A1`).
  ///
  /// Seats are numbered in reading order. A slot is a window slot when it sits
  /// in the first or last column of its row.
  factory SeatLayoutBlueprint.parse(List<String> grid) {
    final rows = <List<SeatSlot>>[];
    final driverLabels = <String>[];
    var seatNumber = 0;
    var widest = 0;

    for (var r = 0; r < grid.length; r++) {
      final tokens = grid[r].split(RegExp(r'\s+'))
        ..removeWhere((token) => token.isEmpty);
      final slots = <SeatSlot>[];

      for (var c = 0; c < tokens.length; c++) {
        final token = tokens[c];
        final separator = token.indexOf(':');
        final symbol = separator < 0 ? token : token.substring(0, separator);
        final label = separator < 0 ? '' : token.substring(separator + 1);
        final isWindow = c == 0 || c == tokens.length - 1;

        final kind = switch (symbol) {
          'S' => SeatSlotKind.seat,
          'D' => SeatSlotKind.driver,
          '^' => SeatSlotKind.door,
          '|' => SeatSlotKind.aisle,
          _ => SeatSlotKind.blank,
        };

        if (kind == SeatSlotKind.seat) seatNumber++;
        if (kind == SeatSlotKind.driver) driverLabels.add(label);

        slots.add(
          SeatSlot(
            kind: kind,
            row: r + 1,
            column: c + 1,
            seatNumber: kind == SeatSlotKind.seat ? seatNumber : 0,
            label: label,
            isWindow: isWindow,
          ),
        );
      }

      widest = slots.length > widest ? slots.length : widest;
      rows.add(slots);
    }

    return SeatLayoutBlueprint(
      rows: rows,
      capacity: seatNumber,
      columns: widest,
      driverLabels: driverLabels,
    );
  }

  /// The honest fallback for a vehicle with no predefined blueprint: draw the
  /// seat data exactly as it is stored, one tile per occupied `(row, column)`.
  ///
  /// Used for vehicle types this app does not model yet — and only for those. A
  /// modelled type keeps its own cabin even when the seat count disagrees with
  /// it, because a stale `seat_configuration` is a data problem and redrawing
  /// the vehicle as a grid hides it instead of showing it. See
  /// `VehicleSeatLayouts.resolve`.
  factory SeatLayoutBlueprint.fromSeatGrid(
    List<({int row, int column})> coordinates, {
    int fallbackColumns = 4,
  }) {
    final usable =
        coordinates.isNotEmpty &&
        coordinates.every((c) => c.row >= 1 && c.column >= 1);

    final placed = usable
        ? coordinates
        : [
            for (var i = 0; i < coordinates.length; i++)
              (
                row: (i ~/ fallbackColumns) + 1,
                column: (i % fallbackColumns) + 1,
              ),
          ];

    if (placed.isEmpty) {
      return const SeatLayoutBlueprint(rows: [], capacity: 0, columns: 0);
    }

    // Seats fill the grid in the same reading order the apps sort them in.
    final ordered = [...placed]
      ..sort((a, b) {
        final byRow = a.row.compareTo(b.row);
        return byRow != 0 ? byRow : a.column.compareTo(b.column);
      });
    final occupied = {for (final c in ordered) '${c.row}:${c.column}'};

    final lastRow = ordered.last.row;
    final widest = ordered.map((c) => c.column).reduce((a, b) => a > b ? a : b);

    final rows = <List<SeatSlot>>[];
    var seatNumber = 0;
    for (var r = 1; r <= lastRow; r++) {
      final slots = <SeatSlot>[];
      for (var c = 1; c <= widest; c++) {
        final isSeat = occupied.contains('$r:$c');
        if (isSeat) seatNumber++;
        slots.add(
          SeatSlot(
            kind: isSeat ? SeatSlotKind.seat : SeatSlotKind.blank,
            row: r,
            column: c,
            seatNumber: isSeat ? seatNumber : 0,
            isWindow: c == 1 || c == widest,
          ),
        );
      }
      rows.add(slots);
    }

    return SeatLayoutBlueprint(
      rows: rows,
      capacity: seatNumber,
      columns: widest,
    );
  }
}
