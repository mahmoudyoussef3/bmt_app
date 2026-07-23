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

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }

  List<Widget> _rowChildren(BuildContext context, List<SeatSlot> slots) {
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
