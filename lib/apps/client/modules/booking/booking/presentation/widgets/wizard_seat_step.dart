import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_button.dart';
import 'package:bmt_app/apps/client/core/widgets/client_skeleton.dart';
import 'package:bmt_app/apps/client/modules/booking/booking/domain/entities/booking_wizard_session.dart';
import 'package:bmt_app/apps/client/modules/booking/booking/presentation/cubit/booking_wizard_cubit.dart';
import 'package:bmt_app/apps/client/modules/booking/seat_selection/domain/entities/seat_option.dart';
import 'package:bmt_app/apps/client/modules/booking/seat_selection/presentation/cubit/seat_selection_cubit.dart';
import 'package:bmt_app/apps/client/modules/booking/seat_selection/presentation/cubit/seat_selection_state.dart';

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
    final tripId = context.read<BookingWizardCubit>().state.selectedTrip?.id ?? '';
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
              SeatSelectionError(:final message) => _SeatErrorBody(message: message,
                  onRetry: () => context.read<SeatSelectionCubit>()
                      .loadSeatSelection(session.selectedTrip?.id ?? '')),
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
  const _SeatBody({required this.state, required this.session, required this.onNext});
  final SeatSelectionLoaded state;
  final BookingWizardSession session;
  final VoidCallback onNext;

  static const _cols = 4;

  @override
  Widget build(BuildContext context) {
    final seats = state.data.seats;
    return Column(
      children: [
        _SeatLegend(),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _cols, mainAxisSpacing: 10, crossAxisSpacing: 10,
            ),
            itemCount: seats.length,
            itemBuilder: (_, i) => _SeatCell(
              seat: seats[i],
              isSelected: seats[i].id == session.selectedSeatId,
              onTap: seats[i].isAvailable
                  ? () => context.read<BookingWizardCubit>()
                      .selectSeat(seats[i].id, 'Seat ${seats[i].seatNumber}')
                  : null,
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (session.seatValid)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text('Selected: ${session.selectedSeatLabel}',
                        style: ClientTypography.bodyMedium(context).copyWith(
                          color: ClientColors.primary, fontWeight: FontWeight.w600,
                        )),
                  ),
                ClientButton(label: 'Continue', onPressed: session.seatValid ? onNext : null),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SeatCell extends StatelessWidget {
  const _SeatCell({required this.seat, required this.isSelected, this.onTap});
  final SeatOption seat;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final available = seat.isAvailable;
    Color bg = isSelected
        ? ClientColors.primary
        : available
            ? ClientColors.journeyGreenLight
            : ClientColors.journeySlateLight;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? ClientColors.primary : ClientColors.borderFor(context),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_seat_rounded,
                size: 22,
                color: isSelected
                    ? Colors.white
                    : available
                        ? ClientColors.journeyGreen
                        : ClientColors.journeySlate),
            const SizedBox(height: 2),
            Text('${seat.seatNumber}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? Colors.white
                      : available
                          ? ClientColors.onJourneyGreen
                          : ClientColors.journeySlate,
                )),
          ],
        ),
      ),
    );
  }
}

class _SeatLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _item(context, ClientColors.journeyGreenLight, ClientColors.journeyGreen, 'Available'),
          const SizedBox(width: 16),
          _item(context, ClientColors.primary, Colors.white, 'Selected'),
          const SizedBox(width: 16),
          _item(context, ClientColors.journeySlateLight, ClientColors.journeySlate, 'Taken'),
        ],
      ),
    );
  }

  Widget _item(BuildContext ctx, Color bg, Color icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 18, height: 18,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
        child: Icon(Icons.event_seat_rounded, size: 12, color: icon),
      ),
      const SizedBox(width: 5),
      Text(label, style: ClientTypography.labelSmall(ctx).copyWith(
        color: ClientColors.textSecondaryFor(ctx),
      )),
    ],
  );
}

class _SeatLoadingBody extends StatelessWidget {
  const _SeatLoadingBody();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10,
      ),
      itemCount: 20,
      itemBuilder: (_, _) => ClientSkeleton(width: double.infinity, height: double.infinity,
          borderRadius: 10),
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
            const Icon(Icons.error_outline_rounded, size: 56, color: ClientColors.journeyRed),
            const SizedBox(height: 16),
            Text('Could not load seats', style: ClientTypography.headingSmall(context)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center,
                style: ClientTypography.bodySmall(context).copyWith(
                  color: ClientColors.textSecondaryFor(context),
                )),
            const SizedBox(height: 20),
            ClientButton(label: 'Try Again', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
