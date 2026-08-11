import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_button.dart';
import 'package:bmt_app/apps/client/core/widgets/client_seat_labels.dart';
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
import 'package:bmt_app/core/widgets/vehicle_seats/vehicle_seats.dart';

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
              VehicleSeatLayout(
                blueprint: blueprint,
                seats: [
                  for (var i = 0; i < seats.length; i++)
                    _seatData(blueprint, seats[i], i, session.selectedSeatId),
                ],
                mode: SeatLayoutMode.selection,
                showLegend: true,
                labels: clientSeatLabels(context),
                onSeatTap: (data) =>
                    context.read<BookingWizardCubit>().selectSeat(
                      data.id,
                      seats.firstWhere((s) => s.id == data.id).displayLabel,
                    ),
              ),
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

  /// Turns one booking seat into a tile for the shared cabin renderer.
  ///
  /// This is where the client's booking rule lives — and the only place it
  /// does: a rider may tap a seat that is free, and nothing else. The renderer
  /// is told the outcome (`enabled`), never the rule.
  VehicleSeatData _seatData(
    SeatLayoutBlueprint blueprint,
    SeatOption seat,
    int index,
    String? selectedSeatId,
  ) {
    
    final slot = blueprint.seatSlotAt(index);
    return VehicleSeatData(
      id: seat.id,
      label: slot == null ? seat.displayLabel : cabinSeatLabel(blueprint, slot),
      state: seat.id == selectedSeatId
          ? SeatViewState.selected
          : seat.isAvailable
          ? SeatViewState.available
          : SeatViewState.occupied,
      enabled: seat.isAvailable,
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
