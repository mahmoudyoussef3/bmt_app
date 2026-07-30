import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/features/trips/presentation/widgets/trip_ui_helpers.dart';
import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_seats/presentation/cubit/trip_seats_cubit.dart';
import 'package:bmt_app/core/theme/tokens.dart';
import 'package:bmt_app/core/vehicles/vehicles.dart';

/// The trip's seats drawn as the **cabin they physically are** — a Hiace looks
/// like a Hiace, a Coaster like a Coaster — instead of a flat grid of numbers.
///
/// The layout comes from the blueprint the vehicle's type resolves to, the same
/// one the Client App draws the rider's seat map from and the same one Fleet
/// previewed when the vehicle was saved. A type with no blueprint (or a vehicle
/// whose seat count disagrees with its type) falls back to the seats' stored
/// coordinates, which is plainer but never a lie.
class TripSeatMap extends StatelessWidget {
  const TripSeatMap({super.key, required this.trip});

  final OperationTrip trip;

  /// Bounds on a seat tile: small enough that a 30-seat Coaster fits a laptop
  /// screen, large enough that a two-digit seat number stays readable.
  static const double _minSeat = 40;
  static const double _maxSeat = 64;
  static const double _gap = 6;

  /// Everything between the outer edge of the bus and the first seat, per side:
  /// the body wall plus the floor margin inside it.
  static const double _wall = _Cabin.padding + _Cabin.border;

  @override
  Widget build(BuildContext context) {
    // Seat data is stored per (row, column); the blueprint pours seats into its
    // slots in that same reading order, so the two must be sorted alike.
    final ordered = [...trip.seats]
      ..sort((a, b) {
        final byRow = a.row.compareTo(b.row);
        return byRow != 0 ? byRow : a.column.compareTo(b.column);
      });

    final type = VehicleTypeParser.fromDatabase(trip.vehicleType);
    final blueprint = VehicleSeatLayouts.resolve(
      type: type,
      seats: [for (final seat in ordered) (row: seat.row, column: seat.column)],
    );
    final extras = ordered.skip(blueprint.capacity).toList();

    // A blueprint drives itself: it says where the driver sits. A grid derived
    // from seat data cannot — `trip_seats` only ever holds passenger seats. But
    // every seat generator in this codebase puts the driver at (1, 1) (both
    // cabin blueprints and `SeatConfiguration.generateDefault`), so a front-left
    // hole in a derived grid is the driver's place and nothing else. Drawing the
    // bench there is what makes an operator-defined van still read as a cabin
    // instead of a floating block of seats.
    final derived = VehicleSeatLayouts.blueprintFor(type) != blueprint;
    final driverAtFrontLeft = derived && _isEmptyFrontLeft(blueprint);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      children: [
        Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = blueprint.columns == 0 ? 1 : blueprint.columns;
              final available =
                  constraints.maxWidth - _wall * 2 - _gap * (columns - 1);
              final seatSize = (available / columns).clamp(_minSeat, _maxSeat);
              return _Cabin(
                blueprint: blueprint,
                seats: ordered,
                seatSize: seatSize,
                gap: _gap,
                caption: _cabinCaption(type, ordered.length),
                driverAtFrontLeft: driverAtFrontLeft,
                onSeatState: (seat, state) => context
                    .read<TripSeatsCubit>()
                    .changeSeatState(trip.id, seat.id, state),
              );
            },
          ),
        ),
        if (extras.isNotEmpty) ...[
          const SizedBox(height: AppTokens.spaceLg),
          _ExtraSeats(
            seats: extras,
            onSeatState: (seat, state) => context
                .read<TripSeatsCubit>()
                .changeSeatState(trip.id, seat.id, state),
          ),
        ],
      ],
    );
  }

  /// Whether the front-left cell of a derived grid is empty — see the call site.
  bool _isEmptyFrontLeft(SeatLayoutBlueprint blueprint) {
    if (blueprint.rows.isEmpty || blueprint.rows.first.isEmpty) return false;
    return blueprint.rows.first.first.isGap;
  }

  /// Names the cabin the operator is looking at.
  ///
  /// A trip whose seat count disagrees with its vehicle type is drawn from its
  /// stored coordinates instead of the type's cabin — truthful, but it hides
  /// the reason the bus looks plain. The caption says it outright, because the
  /// fix (re-typing the vehicle in Fleet) is not on this screen.
  String _cabinCaption(VehicleType type, int seatCount) {
    final label = _typeLabels[type] ?? 'مركبة';
    final fixed = VehicleSeatLayouts.capacityFor(type);
    if (fixed != null && fixed != seatCount) {
      return '$label • $seatCount مقعد — لا يطابق تخطيط النوع ($fixed مقعد)';
    }
    return '$label • $seatCount مقعد';
  }

  static const Map<VehicleType, String> _typeLabels = {
    VehicleType.hiace: 'هايس',
    VehicleType.coaster: 'كوستر',
    VehicleType.sprinter: 'سبرنتر',
    VehicleType.h1: 'فان H1',
    VehicleType.other: 'مركبة',
  };
}

/// The vehicle body: nose, windshield, seat rows, rear bench wall.
class _Cabin extends StatelessWidget {
  const _Cabin({
    required this.blueprint,
    required this.seats,
    required this.seatSize,
    required this.gap,
    required this.caption,
    required this.driverAtFrontLeft,
    required this.onSeatState,
  });

  final SeatLayoutBlueprint blueprint;
  final List<TripSeat> seats;
  final double seatSize;
  final double gap;
  final String caption;

  /// Draw the driver bench in the empty front-left cell of a derived grid.
  final bool driverAtFrontLeft;
  final void Function(TripSeat seat, TripSeatState state) onSeatState;

  /// Floor margin inside the body wall, and the wall itself. Both count towards
  /// the cabin's width, so the caller sizes seats against the same numbers.
  static const double padding = 16;
  static const double border = 2;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final columns = blueprint.columns == 0 ? 1 : blueprint.columns;
    final width =
        seatSize * columns + gap * (columns - 1) + (padding + border) * 2;

    return Container(
      width: width,
      padding: const EdgeInsets.fromLTRB(padding, 14, padding, 18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(60),
        border: Border.all(color: scheme.outlineVariant, width: border),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(56),
          topRight: Radius.circular(56),
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Windshield(),
          const SizedBox(height: 12),
          // A cabin is a physical object and does not mirror with the writing
          // system. Column 1 of a blueprint is the driver's side of a
          // left-hand-drive vehicle, so the dashboard's ambient RTL would flip
          // the whole bus: steering wheel on the wrong side, the aisle on the
          // wrong side, every window seat against the opposite wall. Seat
          // labels travel with their tile, so pinning the grid to LTR changes
          // nothing about which seat a number refers to.
          Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              children: [
                for (var r = 0; r < blueprint.rows.length; r++)
                  Padding(
                    padding: EdgeInsets.only(top: r == 0 ? 0 : gap),
                    child: Row(
                      children: [
                        for (var c = 0; c < blueprint.rows[r].length; c++) ...[
                          if (c > 0) SizedBox(width: gap),
                          SizedBox(
                            width: seatSize,
                            child: _Slot(
                              slot: blueprint.rows[r][c],
                              seats: seats,
                              size: seatSize,
                              isDriverCell:
                                  driverAtFrontLeft && r == 0 && c == 0,
                              onSeatState: onSeatState,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'مؤخرة المركبة',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// The front glass — the one cue that tells an operator which end of the
/// drawing is the front of the bus.
class _Windshield extends StatelessWidget {
  const _Windshield();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withAlpha(70),
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(40),
          bottom: Radius.circular(8),
        ),
      ),
      child: Text(
        'مقدمة المركبة',
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
    );
  }
}

/// One cell of the cabin grid: a seat, the driver bench, the door, or floor.
class _Slot extends StatelessWidget {
  const _Slot({
    required this.slot,
    required this.seats,
    required this.size,
    required this.isDriverCell,
    required this.onSeatState,
  });

  final SeatSlot slot;
  final List<TripSeat> seats;
  final double size;

  /// This empty cell is the driver's place — see [TripSeatMap].
  final bool isDriverCell;
  final void Function(TripSeat seat, TripSeatState state) onSeatState;

  @override
  Widget build(BuildContext context) {
    if (slot.isGap) {
      if (!isDriverCell) return SizedBox(height: size);
      return _FixtureTile(
        size: size,
        icon: Icons.airline_seat_recline_normal_rounded,
        label: 'سائق',
        tooltip: 'مقعد السائق',
      );
    }

    if (slot.kind == SeatSlotKind.driver) {
      return _FixtureTile(
        size: size,
        icon: Icons.airline_seat_recline_normal_rounded,
        label: slot.label.isEmpty ? 'سائق' : slot.label,
        tooltip: 'مقعد السائق',
      );
    }
    if (slot.kind == SeatSlotKind.door) {
      return _FixtureTile(
        size: size,
        icon: Icons.sensor_door_outlined,
        label: 'باب',
        tooltip: 'باب الركاب',
      );
    }

    final index = slot.seatNumber - 1;
    if (index < 0 || index >= seats.length) return SizedBox(height: size);
    final seat = seats[index];

    return PopupMenuButton<TripSeatState>(
      tooltip: 'مقعد ${seat.label} • ${seat.state.label}',
      padding: EdgeInsets.zero,
      onSelected: (state) => onSeatState(seat, state),
      itemBuilder: (_) => [
        for (final state in TripSeatState.values)
          PopupMenuItem(
            value: state,
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: tripSeatColor(context, state),
                    shape: BoxShape.circle,
                    border: Border.all(color: tripSeatAccent(context, state)),
                  ),
                ),
                const SizedBox(width: 8),
                Text(state.label),
              ],
            ),
          ),
      ],
      child: _SeatTile(seat: seat, size: size),
    );
  }
}

/// A seat drawn as a seat: headrest, backrest, cushion and armrests, filled
/// with the state colour and carrying its real stored label.
class _SeatTile extends StatelessWidget {
  const _SeatTile({required this.seat, required this.size});

  final TripSeat seat;
  final double size;

  @override
  Widget build(BuildContext context) {
    final fill = tripSeatColor(context, seat.state);
    final accent = tripSeatAccent(context, seat.state);
    final foreground = tripSeatOnColor(context, seat.state);
    final armrest = size * 0.13;

    return SizedBox(
      height: size,
      child: Stack(
        children: [
          // Armrests, drawn behind the cushion so they read as side rails.
          Positioned(
            left: 0,
            top: size * 0.34,
            child: _Armrest(width: armrest, height: size * 0.44, color: accent),
          ),
          Positioned(
            right: 0,
            top: size * 0.34,
            child: _Armrest(width: armrest, height: size * 0.44, color: accent),
          ),
          Positioned.fill(
            left: armrest * 0.55,
            right: armrest * 0.55,
            child: Container(
              decoration: BoxDecoration(
                color: fill,
                border: Border.all(color: accent.withAlpha(150)),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(size * 0.32),
                  topRight: Radius.circular(size * 0.32),
                  bottomLeft: Radius.circular(size * 0.16),
                  bottomRight: Radius.circular(size * 0.16),
                ),
              ),
              child: Stack(
                children: [
                  // Headrest: the strip that makes the tile read as a backrest
                  // seen from above rather than a rounded card.
                  Positioned(
                    top: size * 0.08,
                    left: size * 0.2,
                    right: size * 0.2,
                    child: Container(
                      height: size * 0.08,
                      decoration: BoxDecoration(
                        color: accent.withAlpha(120),
                        borderRadius: BorderRadius.circular(size),
                      ),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: size * 0.12),
                      child: Text(
                        seat.label,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: TextStyle(
                          color: foreground,
                          fontWeight: FontWeight.w900,
                          fontSize: size * 0.3,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                  if (_stateIcon(seat.state) case final icon?)
                    Positioned(
                      bottom: size * 0.06,
                      left: 0,
                      right: 0,
                      child: Icon(
                        icon,
                        size: size * 0.2,
                        color: foreground.withAlpha(190),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A glyph for every state a seat is *not* simply free in, so the map still
  /// reads for an operator who cannot separate the fill colours.
  static IconData? _stateIcon(TripSeatState state) => switch (state) {
    TripSeatState.available => null,
    TripSeatState.reserved => Icons.schedule_rounded,
    TripSeatState.paid => Icons.check_circle_rounded,
    TripSeatState.subscription => Icons.card_membership_rounded,
    TripSeatState.blocked => Icons.block_rounded,
  };
}

class _Armrest extends StatelessWidget {
  const _Armrest({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color.withAlpha(90),
        borderRadius: BorderRadius.circular(width),
      ),
    );
  }
}

/// The driver bench and the passenger door: part of the cabin, never bookable.
class _FixtureTile extends StatelessWidget {
  const _FixtureTile({
    required this.size,
    required this.icon,
    required this.label,
    required this.tooltip,
  });

  final double size;
  final IconData icon;
  final String label;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Container(
        height: size,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(size * 0.24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: size * 0.34, color: scheme.onSurfaceVariant),
            SizedBox(height: size * 0.04),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: TextStyle(
                fontSize: size * 0.2,
                fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Seats the trip carries beyond what the cabin blueprint can hold.
///
/// They exist (a vehicle re-typed after its trips were created, say), they are
/// bookable, and hiding them would hide real inventory — so they are listed
/// outside the bus rather than forced into it.
class _ExtraSeats extends StatelessWidget {
  const _ExtraSeats({required this.seats, required this.onSeatState});

  final List<TripSeat> seats;
  final void Function(TripSeat seat, TripSeatState state) onSeatState;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'مقاعد إضافية خارج تخطيط النوع (${seats.length})',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppTokens.spaceSm),
        Wrap(
          spacing: AppTokens.spaceSm,
          runSpacing: AppTokens.spaceSm,
          children: [
            for (final seat in seats)
              SizedBox(
                width: 52,
                child: PopupMenuButton<TripSeatState>(
                  tooltip: 'مقعد ${seat.label} • ${seat.state.label}',
                  padding: EdgeInsets.zero,
                  onSelected: (state) => onSeatState(seat, state),
                  itemBuilder: (_) => [
                    for (final state in TripSeatState.values)
                      PopupMenuItem(value: state, child: Text(state.label)),
                  ],
                  child: _SeatTile(seat: seat, size: 52),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
