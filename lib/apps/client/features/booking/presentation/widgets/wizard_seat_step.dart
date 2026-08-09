import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_button.dart';
import 'package:bmt_app/apps/client/core/widgets/client_seat_map.dart';
import 'package:bmt_app/apps/client/core/widgets/client_skeleton.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_wizard_session.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/booking_step_components.dart';
import 'package:bmt_app/apps/client/features/seat_selection/domain/entities/seat_option.dart';
import 'package:bmt_app/apps/client/features/seat_selection/presentation/cubit/seat_selection_cubit.dart';
import 'package:bmt_app/apps/client/features/seat_selection/presentation/cubit/seat_selection_state.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/vehicles/vehicles.dart';
import 'package:bmt_app/core/widgets/directional_icon.dart';

class WizardSeatStep extends StatefulWidget {
  const WizardSeatStep({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  State<WizardSeatStep> createState() => _WizardSeatStepState();
}

class _WizardSeatStepState extends State<WizardSeatStep> {
  @override
  void initState() {
    super.initState();
    final tripId =
        context.read<BookingWizardCubit>().state.selectedTrip?.id ?? '';
    context.read<SeatSelectionCubit>().loadSeatSelection(tripId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SeatSelectionCubit, SeatSelectionState>(
      builder: (context, seatState) {
        return BlocBuilder<BookingWizardCubit, BookingWizardSession>(
          builder: (context, session) {
            return switch (seatState) {
              SeatSelectionLoading() => const _SeatLoadingBody(),
              SeatSelectionError(:final message) => _SeatErrorBody(
                message: message,
                onRetry: () => context
                    .read<SeatSelectionCubit>()
                    .loadSeatSelection(session.selectedTrip?.id ?? ''),
              ),
              SeatSelectionLoaded() => _SeatBody(
                state: seatState,
                session: session,
                onNext: widget.onNext,
              ),
            };
          },
        );
      },
    );
  }
}

class _SeatBody extends StatelessWidget {
  const _SeatBody({
    required this.state,
    required this.session,
    required this.onNext,
  });

  final SeatSelectionLoaded state;
  final BookingWizardSession session;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final seats = [...state.data.seats]
      ..sort((a, b) {
        final rowCompare = a.row.compareTo(b.row);
        return rowCompare != 0 ? rowCompare : a.column.compareTo(b.column);
      });
    // The vehicle on the trip decides the cabin — never the seat count, the
    // seat labels or the trip name.
    final blueprint = VehicleSeatLayouts.resolveRaw(
      vehicleType: state.data.vehicleType,
      seats: [for (final seat in seats) (row: seat.row, column: seat.column)],
    );
    final selectedIndex = seats.indexWhere(
      (seat) => seat.id == session.selectedSeatId,
    );
    final selectedSlot = selectedIndex < 0
        ? null
        : blueprint.seatSlotAt(selectedIndex);
    final selectedLabel = selectedIndex < 0
        ? null
        : selectedSlot != null
        ? cabinSeatLabel(blueprint, selectedSlot)
        : seats[selectedIndex].displayLabel;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            children: [
              BookingStepIntro(
                icon: Icons.event_seat_rounded,
                title: l10n.booking_pickYourSeat,
                subtitle: l10n.booking_frontSeatsNote,
                trailing: BookingCountPill(
                  label: l10n.booking_freeCount(state.data.availableCount),
                ),
              ),
              const SizedBox(height: 16),
              const _SeatLegend(),
              const SizedBox(height: 16),
              _VehicleCabin(
                blueprint: blueprint,
                seats: seats,
                selectedSeatId: session.selectedSeatId,
                onSeatTap: (seat) => context
                    .read<BookingWizardCubit>()
                    .selectSeat(seat.id, seat.displayLabel),
              ),
              if (seats.length > blueprint.capacity) ...[
                const SizedBox(height: 14),
                _ExtraSeats(
                  seats: seats.skip(blueprint.capacity).toList(),
                  selectedSeatId: session.selectedSeatId,
                  onSeatTap: (seat) => context
                      .read<BookingWizardCubit>()
                      .selectSeat(seat.id, seat.displayLabel),
                ),
              ],
            ],
          ),
        ),
        BookingBottomAction(
          summary: selectedLabel == null
              ? null
              : Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: ClientColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        selectedLabel,
                        style: ClientTypography.labelMedium(
                          context,
                        ).copyWith(color: ClientColors.primary),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.booking_yourSelectedSeat,
                        style: ClientTypography.bodySmall(context).copyWith(
                          color: ClientColors.textSecondaryFor(context),
                        ),
                      ),
                    ),
                    Text(
                      l10n.packages_egpAmount(
                        session.tripPrice.toStringAsFixed(0),
                      ),
                      style: ClientTypography.priceSmall(
                        context,
                      ).copyWith(color: ClientColors.primary),
                    ),
                  ],
                ),
          child: ClientButton(
            label: l10n.booking_continueToPackages,
            icon: const DirectionalIcon(Icons.arrow_forward_rounded),
            onPressed: session.seatValid ? onNext : null,
          ),
        ),
      ],
    );
  }

}

/// The label riders see on a seat tile: the row's letter (A the driver row,
/// B the next, …) followed by its 1-based position in that row — counting the
/// driver bench too, so the lone seat beside the driver reads `A3` rather than
/// `A1`. Pure geometry off the blueprint; never touches the seat's stored id
/// or the label persisted in `trip_seats`.
String cabinSeatLabel(SeatLayoutBlueprint blueprint, SeatSlot slot) {
  final rowLetter = String.fromCharCode('A'.codeUnitAt(0) + slot.row - 1);
  var position = 0;
  for (final other in blueprint.rows[slot.row - 1]) {
    if (other.isGap) continue;
    position++;
    if (other.column == slot.column) break;
  }
  return '$rowLetter$position';
}

class _VehicleCabin extends StatelessWidget {
  const _VehicleCabin({
    required this.blueprint,
    required this.seats,
    required this.selectedSeatId,
    required this.onSeatTap,
  });

  final SeatLayoutBlueprint blueprint;
  final List<SeatOption> seats;
  final String? selectedSeatId;
  final ValueChanged<SeatOption> onSeatTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 430),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 22),
          decoration: BoxDecoration(
            color: ClientColors.surfaceFor(context),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(54),
              topRight: Radius.circular(54),
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            border: Border.all(color: ClientColors.borderStrongFor(context)),
            boxShadow: ClientElevation.md(context),
          ),
          child: Column(
            children: [
              Container(
                width: 76,
                height: 7,
                decoration: BoxDecoration(
                  color: ClientColors.surfaceMutedFor(context),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 10),
              _CabinCaption(label: context.l10n.seatSelection_frontOfVehicle),
              const SizedBox(height: 14),
              ClientSeatMap(
                blueprint: blueprint,
                rowGap: 12,
                seatBuilder: _seat,
                decorationBuilder: _decoration,
                clusterBuilder: _bench,
              ),
              const SizedBox(height: 14),
              Divider(color: ClientColors.borderFor(context)),
              const SizedBox(height: 6),
              _CabinCaption(label: context.l10n.seatSelection_cabinRear),
            ],
          ),
        ),
        Positioned(bottom: -6, left: 30, child: _CabinWheel()),
        Positioned(bottom: -6, right: 30, child: _CabinWheel()),
      ],
    );
  }

  /// The shared card behind one physical bench — a 2-seat pair, the lone
  /// aisle seat across from it, or (on the flush back row) all four seats at
  /// once. Makes the 2+1 split the rider will actually sit in visible instead
  /// of implied by spacing alone.
  Widget _bench(BuildContext context, List<SeatSlot> cluster, Widget row) {
    final isDriverBench = cluster.every(
      (slot) => slot.kind == SeatSlotKind.driver,
    );
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDriverBench
            ? ClientColors.surfaceMutedFor(context)
            : ClientColors.surfaceSubtleFor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: row,
    );
  }

  Widget _seat(BuildContext context, SeatSlot slot) {
    final index = slot.seatNumber - 1;
    if (index < 0 || index >= seats.length) {
      return const SizedBox(height: 62);
    }
    final seat = seats[index];
    return _SeatCell(
      seat: seat,
      label: cabinSeatLabel(blueprint, slot),
      isSelected: seat.id == selectedSeatId,
      onTap: seat.isAvailable ? () => onSeatTap(seat) : null,
    );
  }

  Widget _decoration(BuildContext context, SeatSlot slot) {
    if (slot.kind == SeatSlotKind.door) {
      return _CabinDoor(label: context.l10n.seatSelection_cabinDoor);
    }
    // Column 1 is always the driver's own seat — the blueprint is drawn in a
    // fixed left-hand-drive coordinate system regardless of app direction.
    final isDriver = slot.column == 1;
    final fallback = isDriver ? 'A1' : 'A2';
    return _DriverSeat(
      caption: isDriver
          ? context.l10n.booking_driver
          : slot.label.isEmpty
          ? fallback
          : slot.label,
      isDriver: isDriver,
    );
  }
}

/// A small wheel peeking out from the cabin card's bottom corner — the one
/// cue that reads "vehicle" rather than "seating chart".
class _CabinWheel extends StatelessWidget {
  const _CabinWheel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ClientColors.textTertiaryFor(context),
        border: Border.all(color: ClientColors.surfaceFor(context), width: 2),
      ),
    );
  }
}

class _DriverSeat extends StatelessWidget {
  const _DriverSeat({required this.caption, required this.isDriver});

  final String caption;
  final bool isDriver;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      decoration: BoxDecoration(
        color: ClientColors.surfaceMutedFor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isDriver
                ? Icons.airline_seat_recline_extra_rounded
                : Icons.airline_seat_recline_normal_rounded,
            color: ClientColors.textTertiaryFor(context),
            size: 19,
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.labelSmall(context).copyWith(
              color: ClientColors.textTertiaryFor(context),
              fontSize: isDriver ? 9 : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// The FRONT / REAR markers that orient the rider inside the cabin.
class _CabinCaption extends StatelessWidget {
  const _CabinCaption({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: ClientTypography.labelSmall(context).copyWith(
        color: ClientColors.textTertiaryFor(context),
        letterSpacing: 1.2,
      ),
    );
  }
}

/// The passenger entrance, so the rider can read front from rear and see which
/// seats sit by the door.
class _CabinDoor extends StatelessWidget {
  const _CabinDoor({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      decoration: BoxDecoration(
        color: ClientColors.surfaceSubtleFor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: ClientColors.borderFor(context),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sensor_door_outlined,
            color: ClientColors.textTertiaryFor(context),
            size: 21,
          ),
          Text(
            label,
            style: ClientTypography.labelSmall(
              context,
            ).copyWith(color: ClientColors.textTertiaryFor(context)),
          ),
        ],
      ),
    );
  }
}

class _SeatCell extends StatelessWidget {
  const _SeatCell({
    required this.seat,
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  final SeatOption seat;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final available = seat.isAvailable;
    final background = isSelected
        ? ClientColors.primary
        : available
        ? ClientColors.seatAvailableFor(context)
        : ClientColors.surfaceMutedFor(context);
    final foreground = isSelected
        ? Colors.white
        : available
        ? ClientColors.onSeatAvailableFor(context)
        : ClientColors.textTertiaryFor(context);

    return GestureDetector(
      key: ValueKey('seat-${seat.id}'),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 62,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? ClientColors.primary
                : available
                ? ClientColors.seatAvailableBorderFor(context)
                : ClientColors.borderFor(context),
          ),
          boxShadow: isSelected ? ClientElevation.sm(context) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_seat_rounded, size: 22, color: foreground),
            const SizedBox(height: 3),
            Text(
              label,
              style: ClientTypography.labelMedium(
                context,
              ).copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExtraSeats extends StatelessWidget {
  const _ExtraSeats({
    required this.seats,
    required this.selectedSeatId,
    required this.onSeatTap,
  });

  final List<SeatOption> seats;
  final String? selectedSeatId;
  final ValueChanged<SeatOption> onSeatTap;

  @override
  Widget build(BuildContext context) {
    return BookingSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.booking_additionalVehicleSeats,
            style: ClientTypography.labelMedium(context),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: seats.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              mainAxisExtent: 62,
            ),
            itemBuilder: (context, index) {
              final seat = seats[index];
              return _SeatCell(
                seat: seat,
                label: seat.displayLabel,
                isSelected: seat.id == selectedSeatId,
                onTap: seat.isAvailable ? () => onSeatTap(seat) : null,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SeatLegend extends StatelessWidget {
  const _SeatLegend();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _item(
          context,
          ClientColors.seatAvailableFor(context),
          l10n.booking_available,
          border: ClientColors.seatAvailableBorderFor(context),
        ),
        const SizedBox(width: 16),
        _item(context, ClientColors.primary, l10n.seatSelection_seatStatusSelected),
        const SizedBox(width: 16),
        _item(
          context,
          ClientColors.surfaceMutedFor(context),
          l10n.booking_unavailable,
        ),
      ],
    );
  }

  Widget _item(
    BuildContext context,
    Color color,
    String label, {
    Color? border,
  }) => Row(
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: border ?? ClientColors.borderFor(context)),
        ),
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: ClientTypography.labelSmall(
          context,
        ).copyWith(color: ClientColors.textSecondaryFor(context)),
      ),
    ],
  );
}

class _SeatLoadingBody extends StatelessWidget {
  const _SeatLoadingBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        ClientSkeleton(width: double.infinity, height: 68, borderRadius: 18),
        SizedBox(height: 18),
        ClientSkeleton(width: double.infinity, height: 490, borderRadius: 28),
      ],
    );
  }
}

class _SeatErrorBody extends StatelessWidget {
  const _SeatErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: ClientColors.journeyRed,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.booking_couldNotLoadSeats,
              style: ClientTypography.headingSmall(context),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: ClientTypography.bodySmall(
                context,
              ).copyWith(color: ClientColors.textSecondaryFor(context)),
            ),
            const SizedBox(height: 20),
            ClientButton(
              label: context.l10n.common_tryAgain,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
