import 'package:flutter/material.dart';

import 'package:bmt_app/core/vehicles/vehicles.dart';

typedef SeatSlotBuilder = Widget Function(BuildContext context, SeatSlot slot);

/// Draws a cabin from a [SeatLayoutBlueprint]. The blueprint decides where
/// seats, the aisle, the driver bench and the door sit; the caller decides what
/// a tile looks like, so the booking flow and Trip Details keep their own
/// visuals while agreeing on the shape of the vehicle.
///
/// [seatBuilder] receives each bookable slot; `slot.seatNumber - 1` is the
/// index into the trip's seat list sorted by `(row, column)`.
class ClientSeatMap extends StatelessWidget {
  const ClientSeatMap({
    super.key,
    required this.blueprint,
    required this.seatBuilder,
    required this.decorationBuilder,
    this.slotWidth,
    this.rowGap = 10,
    this.gap = 8,
    this.aisleGap = 34,
    this.centerRows = false,
    this.clusterBuilder,
  });

  final SeatLayoutBlueprint blueprint;
  final SeatSlotBuilder seatBuilder;

  /// Builds the driver-bench and door tiles.
  final SeatSlotBuilder decorationBuilder;

  /// Fixed tile width, or null to let tiles share the row evenly.
  final double? slotWidth;
  final double rowGap;
  final double gap;
  final double aisleGap;
  final bool centerRows;

  /// Wraps a **bench** — the run of seat/driver slots between two aisle gaps
  /// — so a caller can draw a shared background behind it (e.g. a card behind
  /// a 2-seat pair, a separate one behind the single seat across the aisle).
  /// Left null, rows render exactly as before; existing callers are
  /// unaffected.
  final Widget Function(BuildContext context, List<SeatSlot> cluster, Widget child)?
  clusterBuilder;

  @override
  Widget build(BuildContext context) {
    // A cabin is a physical object and does not mirror with the writing system.
    // Column 1 of a blueprint is the driver's side of a left-hand-drive vehicle,
    // so under Arabic the ambient RTL would flip the whole van: steering wheel on
    // the right, the aisle on the wrong side, and every window seat against the
    // opposite wall from the one the rider will actually sit by. Seat *labels* are
    // unaffected — they travel with their tile — so this corrects the drawing
    // without changing which seat any number refers to.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        children: [
          for (var r = 0; r < blueprint.rows.length; r++)
            Padding(
              padding: EdgeInsets.only(top: r == 0 ? 0 : rowGap),
              child: Row(
                mainAxisSize: centerRows ? MainAxisSize.min : MainAxisSize.max,
                mainAxisAlignment: centerRows
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: _rowChildren(context, blueprint.rows[r]),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _rowChildren(BuildContext context, List<SeatSlot> slots) {
    final builder = clusterBuilder;
    if (builder == null) {
      final children = <Widget>[];
      for (var i = 0; i < slots.length; i++) {
        final slot = slots[i];
        // The aisle is the gap, so it never gets padding of its own.
        if (i > 0 && !slot.isGap && !slots[i - 1].isGap) {
          children.add(SizedBox(width: gap));
        }
        children.add(_cell(context, slot));
      }
      return children;
    }

    // Same shape, split into aisle-separated benches so each one can carry
    // its own background.
    final children = <Widget>[];
    var i = 0;
    while (i < slots.length) {
      if (slots[i].isGap) {
        children.add(_cell(context, slots[i]));
        i++;
        continue;
      }
      final cluster = <SeatSlot>[];
      final cells = <Widget>[];
      while (i < slots.length && !slots[i].isGap) {
        if (cluster.isNotEmpty) cells.add(SizedBox(width: gap));
        cluster.add(slots[i]);
        cells.add(_cell(context, slots[i]));
        i++;
      }
      children.add(
        Expanded(
          flex: cluster.length,
          child: builder(context, cluster, Row(children: cells)),
        ),
      );
    }
    return children;
  }

  Widget _cell(BuildContext context, SeatSlot slot) {
    if (slot.kind == SeatSlotKind.aisle) return SizedBox(width: aisleGap);

    final child = switch (slot.kind) {
      SeatSlotKind.seat => seatBuilder(context, slot),
      SeatSlotKind.driver || SeatSlotKind.door => decorationBuilder(
        context,
        slot,
      ),
      _ => const SizedBox.shrink(),
    };

    final width = slotWidth;
    return width == null
        ? Expanded(child: child)
        : SizedBox(width: width, child: child);
  }
}
