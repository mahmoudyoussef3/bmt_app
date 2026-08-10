import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/dashboard/features/trips/shared/domain/entities/operation_trip.dart';
import 'package:bmt_app/apps/dashboard/features/trips/trip_seats/presentation/cubit/trip_seats_cubit.dart';
import 'package:bmt_app/core/theme/app_light_colors.dart';
import 'package:bmt_app/core/vehicles/vehicles.dart';
import 'package:bmt_app/core/widgets/vehicle_seats/vehicle_seats.dart';

/// The trip's seats drawn as the **cabin they physically are** — a Hiace looks
/// like a Hiace, a Coaster like a Coaster — through the same renderer the
/// Client App draws the rider's map with. What the operator manages here and
/// what the rider booked from are now literally the same widget.
///
/// The layout comes from the blueprint the vehicle's type resolves to. A type
/// with no blueprint (or a vehicle whose seat count disagrees with its type)
/// falls back to the seats' stored coordinates, which is plainer but never a
/// lie.
class TripSeatMap extends StatefulWidget {
  const TripSeatMap({super.key, required this.trip});

  final OperationTrip trip;

  @override
  State<TripSeatMap> createState() => _TripSeatMapState();
}

class _TripSeatMapState extends State<TripSeatMap> {
  /// Where the operator last pressed, so the state menu can open on the seat
  /// they aimed at.
  ///
  /// The seat tiles belong to the shared renderer and it does not hand out
  /// their geometry — correctly, since anchoring a menu is not a seat map's
  /// job. Recording the pointer on the way down costs one listener and keeps
  /// the inline menu the seats tab has always had.
  Offset _pointer = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;

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

    return Listener(
      onPointerDown: (event) => _pointer = event.position,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
        children: [
          VehicleSeatLayout(
            blueprint: blueprint,
            seats: [for (final seat in ordered) _seatData(seat)],
            mode: SeatLayoutMode.management,
            density: SeatLayoutDensity.compact,
            showLegend: true,
            labels: const VehicleSeatLabels(
              // The operator's vocabulary, not the rider's: these are the same
              // words the seat-state menu uses.
              occupied: 'مدفوع',
              reserved: 'محجوز',
              disabled: 'محظور',
            ),
            caption: _cabinCaption(type, ordered.length),
            onSeatTap: (data) => _openStateMenu(
              context,
              ordered.firstWhere((seat) => seat.id == data.id),
            ),
          ),
        ],
      ),
    );
  }

  /// Maps one operational seat state onto the shared presentation states.
  ///
  /// `paid` and `subscription` are both [SeatViewState.occupied] — the cabin
  /// only needs to know the seat is taken — but an operator needs to tell them
  /// apart, so the subscription seat keeps its own glyph and hue. That is what
  /// the per-seat overrides exist for: a shade of a state, not a new state.
  VehicleSeatData _seatData(TripSeat seat) {
    return VehicleSeatData(
      id: seat.id,
      label: seat.label,
      state: switch (seat.state) {
        TripSeatState.available => SeatViewState.available,
        TripSeatState.reserved => SeatViewState.reserved,
        TripSeatState.paid ||
        TripSeatState.subscription => SeatViewState.occupied,
        TripSeatState.blocked => SeatViewState.disabled,
      },
      icon: seat.state == TripSeatState.subscription
          ? Icons.card_membership_rounded
          : null,
      accent: seat.state == TripSeatState.subscription
          ? AppLightColors.special
          : null,
      tooltip: 'مقعد ${seat.label} • ${seat.state.label}',
    );
  }

  Future<void> _openStateMenu(BuildContext context, TripSeat seat) async {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final selected = await showMenu<TripSeatState>(
      context: context,
      position: RelativeRect.fromRect(
        _pointer & Size.zero,
        Offset.zero & overlay.size,
      ),
      items: [
        for (final state in TripSeatState.values)
          PopupMenuItem(
            value: state,
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _menuTone(context, state).fill,
                    shape: BoxShape.circle,
                    border: Border.all(color: _menuTone(context, state).border),
                  ),
                ),
                const SizedBox(width: 8),
                Text(state.label),
              ],
            ),
          ),
      ],
    );

    if (selected == null || !context.mounted) return;
    context.read<TripSeatsCubit>().changeSeatState(
      widget.trip.id,
      seat.id,
      selected,
    );
  }

  /// The swatch beside each menu entry, taken from the seat palette so the
  /// menu and the cabin cannot disagree about what a state looks like.
  SeatTones _menuTone(BuildContext context, TripSeatState state) {
    final palette = VehicleSeatPalette.of(context);
    return switch (state) {
      TripSeatState.available => palette.available,
      TripSeatState.reserved => palette.reserved,
      TripSeatState.paid || TripSeatState.subscription => palette.occupied,
      TripSeatState.blocked => palette.disabled,
    };
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
