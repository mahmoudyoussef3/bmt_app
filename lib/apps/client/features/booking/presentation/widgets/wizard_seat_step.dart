import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_button.dart';
import 'package:bmt_app/apps/client/core/widgets/client_skeleton.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_wizard_session.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/cubit/booking_wizard_cubit.dart';
import 'package:bmt_app/apps/client/features/booking/presentation/widgets/booking_step_components.dart';
import 'package:bmt_app/apps/client/features/seat_selection/domain/entities/seat_option.dart';
import 'package:bmt_app/apps/client/features/seat_selection/presentation/cubit/seat_selection_cubit.dart';
import 'package:bmt_app/apps/client/features/seat_selection/presentation/cubit/seat_selection_state.dart';

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

  static const _labels = [
    'A3',
    'B1',
    'B2',
    'B3',
    'C1',
    'C2',
    'C3',
    'D1',
    'D2',
    'D3',
    'E1',
    'E2',
    'E3',
    'E4',
  ];

  @override
  Widget build(BuildContext context) {
    final seats = [...state.data.seats]
      ..sort((a, b) {
        final rowCompare = a.row.compareTo(b.row);
        return rowCompare != 0 ? rowCompare : a.column.compareTo(b.column);
      });
    final selectedIndex = seats.indexWhere(
      (seat) => seat.id == session.selectedSeatId,
    );
    final selectedLabel = selectedIndex < 0
        ? null
        : _labelFor(selectedIndex, seats[selectedIndex]);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            children: [
              BookingStepIntro(
                icon: Icons.event_seat_rounded,
                title: 'Pick your seat',
                subtitle: 'Front seats are nearest to the driver.',
                trailing: BookingCountPill(
                  label: '${state.data.availableCount} free',
                ),
              ),
              const SizedBox(height: 16),
              const _SeatLegend(),
              const SizedBox(height: 16),
              _VehicleCabin(
                seats: seats,
                selectedSeatId: session.selectedSeatId,
                labelFor: _labelFor,
                onSeatTap: (seat, label) => context
                    .read<BookingWizardCubit>()
                    .selectSeat(seat.id, label),
              ),
              if (seats.length > _labels.length) ...[
                const SizedBox(height: 14),
                _ExtraSeats(
                  seats: seats.skip(_labels.length).toList(),
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
                        'Your selected seat',
                        style: ClientTypography.bodySmall(context).copyWith(
                          color: ClientColors.textSecondaryFor(context),
                        ),
                      ),
                    ),
                    Text(
                      'EGP ${session.tripPrice.toStringAsFixed(0)}',
                      style: ClientTypography.priceSmall(
                        context,
                      ).copyWith(color: ClientColors.primary),
                    ),
                  ],
                ),
          child: ClientButton(
            label: 'Continue to packages',
            icon: const Icon(Icons.arrow_forward_rounded),
            onPressed: session.seatValid ? onNext : null,
          ),
        ),
      ],
    );
  }

  String _labelFor(int index, SeatOption seat) {
    if (index < _labels.length) return _labels[index];
    return seat.displayLabel;
  }
}

class _VehicleCabin extends StatelessWidget {
  const _VehicleCabin({
    required this.seats,
    required this.selectedSeatId,
    required this.labelFor,
    required this.onSeatTap,
  });

  final List<SeatOption> seats;
  final String? selectedSeatId;
  final String Function(int index, SeatOption seat) labelFor;
  final void Function(SeatOption seat, String label) onSeatTap;

  @override
  Widget build(BuildContext context) {
    SeatOption? seatAt(int index) => index < seats.length ? seats[index] : null;

    return Container(
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
          const SizedBox(height: 14),
          Row(
            children: [
              const _DriverSeat(label: 'A1'),
              const SizedBox(width: 10),
              const _DriverSeat(label: 'A2'),
              const Spacer(),
              SizedBox(width: 64, child: _seat(context, seatAt(0), 0)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'DRIVER',
            style: ClientTypography.labelSmall(context).copyWith(
              color: ClientColors.textTertiaryFor(context),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          Divider(color: ClientColors.borderFor(context)),
          const SizedBox(height: 8),
          _threeSeatRow(context, 'B', 1),
          _threeSeatRow(context, 'C', 4),
          _threeSeatRow(context, 'D', 7),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: List.generate(4, (offset) {
                if (offset > 0) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _seat(context, seatAt(10 + offset), 10 + offset),
                    ),
                  );
                }
                return Expanded(child: _seat(context, seatAt(10), 10));
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _threeSeatRow(BuildContext context, String row, int start) {
    SeatOption? at(int index) => index < seats.length ? seats[index] : null;
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Expanded(child: _seat(context, at(start), start)),
          const SizedBox(width: 8),
          Expanded(child: _seat(context, at(start + 1), start + 1)),
          const SizedBox(width: 34),
          Expanded(child: _seat(context, at(start + 2), start + 2)),
        ],
      ),
    );
  }

  Widget _seat(BuildContext context, SeatOption? seat, int index) {
    if (seat == null) return const SizedBox(height: 62);
    final label = labelFor(index, seat);
    return _SeatCell(
      seat: seat,
      label: label,
      isSelected: seat.id == selectedSeatId,
      onTap: seat.isAvailable ? () => onSeatTap(seat, label) : null,
    );
  }
}

class _DriverSeat extends StatelessWidget {
  const _DriverSeat({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 62,
      decoration: BoxDecoration(
        color: ClientColors.surfaceMutedFor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.airline_seat_recline_extra_rounded,
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
            'Additional vehicle seats',
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _item(
          context,
          ClientColors.seatAvailableFor(context),
          'Available',
          border: ClientColors.seatAvailableBorderFor(context),
        ),
        const SizedBox(width: 16),
        _item(context, ClientColors.primary, 'Selected'),
        const SizedBox(width: 16),
        _item(context, ClientColors.surfaceMutedFor(context), 'Unavailable'),
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
              'Could not load seats',
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
            ClientButton(label: 'Try again', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
