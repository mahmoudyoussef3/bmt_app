import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/features/seat_selection/domain/entities/seat_option.dart';
import 'package:bmt_app/apps/client/features/seat_selection/presentation/cubit/seat_selection_cubit.dart';
import 'package:bmt_app/apps/client/features/seat_selection/presentation/cubit/seat_selection_state.dart';
import 'package:bmt_app/apps/client/features/seat_selection/presentation/widgets/booking_footer_summary.dart';
import 'package:bmt_app/apps/client/features/seat_selection/presentation/widgets/interactive_seat.dart';
import 'package:bmt_app/apps/client/features/seat_selection/presentation/widgets/passenger_info_bottom_sheet.dart';
import 'package:bmt_app/apps/client/features/seat_selection/presentation/widgets/seat_booking_summary_panel.dart';
import 'package:bmt_app/apps/client/features/seat_selection/presentation/widgets/seat_legend.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

class SeatSelectionScreen extends StatefulWidget {
  const SeatSelectionScreen({super.key});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
        {};
    final tripId = args['tripId'] as String? ?? '';

    context.read<SeatSelectionCubit>().loadSeatSelection(tripId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SeatSelectionCubit, SeatSelectionState>(
      builder: (context, state) {
        if (state is SeatSelectionLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is SeatSelectionError) {
          return Scaffold(body: Center(child: Text(state.message)));
        }
        final loaded = state as SeatSelectionLoaded;
        return _SeatSelectionContent(loaded: loaded);
      },
    );
  }
}

class _SeatSelectionContent extends StatelessWidget {
  const _SeatSelectionContent({required this.loaded});

  final SeatSelectionLoaded loaded;

  SeatSelectionData get data => loaded.data;

  String? get selectedSeat => loaded.selectedSeatId;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final contentPadding = width < 380 ? 16.0 : 20.0;
    final horizontalGap = width < 380 ? 10.0 : 14.0;
    final aisleGap = width < 380 ? 22.0 : 32.0;
    final rowGap = width < 380 ? 12.0 : 16.0;
    final maxContentWidth = width >= 900
        ? 720.0
        : (width >= 600 ? 560.0 : width);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceContainerLowest,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        contentPadding,
                        12,
                        contentPadding,
                        24,
                      ),
                      children: [
                        const SeatLegend(),

                        const SizedBox(height: 14),
                        _buildBusLayout(
                          context,
                          horizontalGap: horizontalGap,
                          aisleGap: aisleGap,
                          rowGap: rowGap,
                        ),
                        const SizedBox(height: 14),
                        if (selectedSeat == null)
                          _buildEmptyState(context)
                        else
                          _buildSelectedSeatsSummary(context, selectedSeat!),
                        const SizedBox(height: 12),
                        //    SeatPassengerPreviewCard(selectedSeat: selectedSeat),
                        //  const SizedBox(height: 12),
                        SeatBookingSummaryPanel(
                          selectedSeat: selectedSeat == null
                              ? null
                              : data.seats
                                    .firstWhere(
                                      (s) => s.id == selectedSeat,
                                      orElse: () => const SeatOption(
                                        id: '',
                                        seatNumber: 0,
                                        availability:
                                            SeatAvailability.available,
                                      ),
                                    )
                                    .seatNumber
                                    .toString(),
                          vehicleName: data.vehicleName,
                          route: data.route,
                          pricePerSeat: data.pricePerSeat,
                          onPassengerDetailsTap: selectedSeat == null
                              ? null
                              : () => showPassengerInfoBottomSheet(
                                  context,
                                  seatLabel: selectedSeat,
                                ),
                        ),
                        //const SizedBox(height: 14),
                        //_buildHintCard(context),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
              _buildBottomSummary(
                context,
                selectedSeat == null
                    ? null
                    : data.seats
                          .firstWhere(
                            (s) => s.id == selectedSeat,
                            orElse: () => const SeatOption(
                              id: '',
                              seatNumber: 0,
                              availability: SeatAvailability.available,
                            ),
                          )
                          .seatNumber
                          .toString(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary.withAlpha(28), scheme.primary.withAlpha(28)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: scheme.outline.withAlpha(55)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [scheme.primary, scheme.primary],
              ),
            ),
            child: const Icon(
              Icons.directions_bus_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Select Your Seat',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(24),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white.withAlpha(28)),
                      ),
                      child: Text(
                        '${data.availableCount} free',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  data.route,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withAlpha(180),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildTripOverview(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppSurface(
      padding: const EdgeInsets.all(20),
      radius: 24,
      color: scheme.surfaceContainerHigh,
      border: Border.all(color: scheme.outline.withAlpha(55)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [scheme.primary, scheme.secondary],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withAlpha(45),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose a seat',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap an available seat to continue',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: scheme.primary.withAlpha(16),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: scheme.primary.withAlpha(35)),
                ),
                child: Text(
                  '${data.availableCount} open',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoPill(icon: Icons.route_rounded, label: data.route),
              _InfoPill(
                icon: Icons.schedule_rounded,
                label: 'Departs ${data.departureTime}',
              ),
              const _InfoPill(
                icon: Icons.groups_rounded,
                label: '15-seat microbus',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusLayout(
    BuildContext context, {
    required double horizontalGap,
    required double aisleGap,
    required double rowGap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return AppSurface(
      padding: const EdgeInsets.all(18),
      radius: 28,
      color: scheme.surfaceContainerHighest,
      border: Border.all(color: scheme.outline.withAlpha(55)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: scheme.primary.withAlpha(22),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: scheme.primary.withAlpha(35)),
                ),
                child: Text(
                  'FRONT OF VEHICLE',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                'Cabin layout',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: scheme.surface.withAlpha(230),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Theme.of(context).dividerColor.withAlpha(55),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.tire_repair_rounded,
                      size: 18,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Driver',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Seats 1 and 2 are reserved for the driver cabin',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withAlpha(170),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Container(
                  width: 150,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        scheme.surfaceContainerHigh,
                        scheme.surfaceContainerHighest,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: scheme.outline.withAlpha(30)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.airline_seat_recline_normal_rounded,
                        size: 14,
                        color: scheme.primary.withAlpha(170),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Driver Cabin',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface.withAlpha(190),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SeatMapGrid(
            seats: data.seats,
            selectedSeatId: selectedSeat,
            horizontalGap: horizontalGap,
            aisleGap: aisleGap,
            rowGap: rowGap,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppSurface(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      radius: 22,
      color: scheme.surfaceContainerLow,
      border: Border.all(color: scheme.outline.withAlpha(70)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary.withAlpha(30),
            ),
            child: Icon(
              Icons.event_seat_outlined,
              size: 36,
              color: scheme.primary.withAlpha(200),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Select one or more seats to continue',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap any available seat on the layout above. Your fare updates instantly below.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withAlpha(170),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedSeatsSummary(BuildContext context, String seatId) {
    final scheme = Theme.of(context).colorScheme;
    final seatNum = data.seats
        .firstWhere(
          (s) => s.id == seatId,
          orElse: () => const SeatOption(
            id: '',
            seatNumber: 0,
            availability: SeatAvailability.available,
          ),
        )
        .seatNumber;

    return AppSurface(
      padding: const EdgeInsets.all(16),
      radius: 20,
      color: scheme.primary.withAlpha(22),
      border: Border.all(color: scheme.primary.withAlpha(90), width: 1.5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.check_rounded, color: scheme.onPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seat $seatNum selected',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  '1 seat · EGP ${data.pricePerSeat.toStringAsFixed(2)} each · '
                  'Total EGP ${loaded.total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildHintCard(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.all(14),
      radius: 20,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      border: Border.all(
        color: Theme.of(context).colorScheme.outline.withAlpha(55),
      ),
      child: Row(
        children: [
          Icon(
            Icons.touch_app_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Middle rows use a pair on the left and a single seat on the right for a more realistic shuttle layout.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSummary(BuildContext context, String? seatNumStr) {
    final width = MediaQuery.sizeOf(context).width;
    final maxContentWidth = width >= 900
        ? 720.0
        : (width >= 600 ? 560.0 : width);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withAlpha(245),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor.withAlpha(70)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(28),
            blurRadius: 28,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: BookingFooterSummary(
                selectedSeat: seatNumStr,
                pricePerSeat: data.pricePerSeat,
                onConfirm: selectedSeat == null
                    ? null
                    : () => Navigator.of(context).pushNamed(
                        '/payment-demo',
                        arguments: {
                          'tripId': data.tripId,
                          'pickupPoint': data.pickupPoint,
                          'destination': data.destination,
                          'vehicleNumber': data.vehicleNumber,
                          'tripDate': data.tripDate,
                          'departureTime': data.departureTime,
                          'arrivalTime': data.arrivalTime,
                          'selectedSeatId': selectedSeat,
                          'selectedSeat': seatNumStr,
                          'driverName': data.driverName,
                        },
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SeatMapGrid extends StatelessWidget {
  const _SeatMapGrid({
    required this.seats,
    required this.selectedSeatId,
    required this.horizontalGap,
    required this.aisleGap,
    required this.rowGap,
  });

  final List<SeatOption> seats;
  final String? selectedSeatId;
  final double horizontalGap;
  final double aisleGap;
  final double rowGap;

  SeatOption _seat(int seatNumber) {
    return seats.firstWhere(
      (seat) => seat.seatNumber == seatNumber,
      orElse: () => SeatOption(
        id: '',
        seatNumber: seatNumber,
        availability: SeatAvailability.reserved,
      ),
    );
  }

  Widget _seatTile(BuildContext context, int seatNumber) {
    final spec = _seat(seatNumber);
    if (spec.id.isEmpty) {
      // Missing seat in DB, show it as unavailable
      return InteractiveSeat(id: '', status: SeatStatus.reserved, onTap: null);
    }
    final status = _seatStatus(spec, selectedSeatId);
    return InteractiveSeat(
      id: spec.seatNumber
          .toString(), // The widget shows label from ID if we want, but let's pass seatNumber string
      status: status,
      onTap: spec.isAvailable
          ? () => context.read<SeatSelectionCubit>().selectSeat(spec.id)
          : null,
    );
  }

  SeatStatus _seatStatus(SeatOption seat, String? selectedSeatId) {
    if (!seat.isAvailable) return SeatStatus.reserved;
    if (seat.id == selectedSeatId) return SeatStatus.selected;
    return SeatStatus.available;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _tripleRow(context, [1, 2, 3]),
        SizedBox(height: rowGap),
        _pairSingleRow(context, [4, 5], 6),
        SizedBox(height: rowGap),
        _pairSingleRow(context, [7, 8], 9),
        SizedBox(height: rowGap),
        _pairSingleRow(context, [10, 11], 12),
        SizedBox(height: rowGap),
        _tripleRow(context, [13, 14, 15]),
      ],
    );
  }

  Widget _tripleRow(BuildContext context, List<int> numbers) {
    return Row(
      children: [
        Expanded(child: _seatTile(context, numbers[0])),
        SizedBox(width: horizontalGap),
        Expanded(child: _seatTile(context, numbers[1])),
        SizedBox(width: horizontalGap),
        Expanded(child: _seatTile(context, numbers[2])),
      ],
    );
  }

  Widget _pairSingleRow(
    BuildContext context,
    List<int> leftSeats,
    int rightSeat,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Expanded(child: _seatTile(context, leftSeats[0])),
              SizedBox(width: horizontalGap),
              Expanded(child: _seatTile(context, leftSeats[1])),
            ],
          ),
        ),
        SizedBox(width: aisleGap),
        Expanded(child: _seatTile(context, rightSeat)),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(170),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outline.withAlpha(70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
