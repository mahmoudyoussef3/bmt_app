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
  /// Used for vehicle types this app does not model yet, and — importantly —
  /// whenever a modelled type's seat count does not match its blueprint (a
  /// vehicle typed `Coaster` that still carries a 14-seat configuration, say).
  /// Better a truthful grid than a Coaster frame with fourteen holes in it.
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
    final ordered = [...placed]..sort((a, b) {
      final byRow = a.row.compareTo(b.row);
      return byRow != 0 ? byRow : a.column.compareTo(b.column);
    });
    final occupied = {for (final c in ordered) '${c.row}:${c.column}'};

    final lastRow = ordered.last.row;
    final widest = ordered
        .map((c) => c.column)
        .reduce((a, b) => a > b ? a : b);

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
