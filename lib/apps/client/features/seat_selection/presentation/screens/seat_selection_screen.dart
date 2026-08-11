import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/apps/client/features/seat_selection/domain/entities/seat_option.dart';
import 'package:bmt_app/apps/client/features/seat_selection/presentation/cubit/seat_selection_cubit.dart';
import 'package:bmt_app/apps/client/features/seat_selection/presentation/cubit/seat_selection_state.dart';
import 'package:bmt_app/apps/client/features/seat_selection/presentation/widgets/booking_footer_summary.dart';
import 'package:bmt_app/apps/client/features/seat_selection/presentation/widgets/passenger_info_bottom_sheet.dart';
import 'package:bmt_app/apps/client/features/seat_selection/presentation/widgets/seat_booking_summary_panel.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_seat_labels.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/vehicles/vehicles.dart';
import 'package:bmt_app/core/widgets/vehicle_seats/vehicle_seats.dart';

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
    
    final maxContentWidth = width >= 900
        ? 720.0
        : (width >= 600 ? 560.0 : width);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: ClientColors.backgroundFor(context)),
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
                        
                        _buildBusLayout(context),
                        const SizedBox(height: 14),
                        if (selectedSeat == null)
                          _buildEmptyState(context)
                        else
                          _buildSelectedSeatsSummary(context, selectedSeat!),
                        const SizedBox(height: 12),
                        
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
    final l10n = context.l10n;
    return ClientCard(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      backgroundColor: ClientColors.primaryContainerFor(context),
      useShadow: true,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: ClientColors.primary,
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
                        l10n.seatSelection_selectYourSeat,
                        style: ClientTypography.headingSmall(context).copyWith(
                          color: ClientColors.textPrimaryFor(context),
                          height: 1.1,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.tracking_refresh,
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: ClientColors.primaryFor(context),
                      ),
                      onPressed: () => context
                          .read<SeatSelectionCubit>()
                          .loadSeatSelection(data.tripId),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: ClientColors.primary.withAlpha(24),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: ClientColors.primary.withAlpha(60),
                        ),
                      ),
                      child: Text(
                        l10n.seatSelection_seatsFreeCount(data.availableCount),
                        style: ClientTypography.labelSmall(context).copyWith(
                          color: ClientColors.primaryFor(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  data.route,
                  style: ClientTypography.bodySmall(
                    context,
                  ).copyWith(color: ClientColors.textSecondaryFor(context)),
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
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: ClientColors.primary,
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
                      l10n.seatSelection_chooseASeat,
                      style: ClientTypography.headingSmall(
                        context,
                      ).copyWith(color: ClientColors.textPrimaryFor(context)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.seatSelection_tapSeatToContinue,
                      style: ClientTypography.bodySmall(
                        context,
                      ).copyWith(color: ClientColors.textSecondaryFor(context)),
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
                  color: ClientColors.primaryContainerFor(context),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: ClientColors.primaryMuted),
                ),
                child: Text(
                  l10n.seatSelection_seatsOpenCount(data.availableCount),
                  style: ClientTypography.labelSmall(context).copyWith(
                    color: ClientColors.primaryFor(context),
                    fontWeight: FontWeight.w700,
                  ),
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
                label: l10n.seatSelection_departsAt(data.departureTime),
              ),
              _InfoPill(
                icon: Icons.groups_rounded,
                label: l10n.seatSelection_microbusCapacity,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// The cabin.
  ///
  /// The chrome that used to wrap it — a FRONT pill, a "cabin layout" caption
  /// and a hand-built driver panel — is gone: the shared seat map draws the
  /// vehicle's nose, its windshield and its driver area itself, and the panel
  /// was describing in three lines of text what the cabin now shows.
  Widget _buildBusLayout(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ClientColors.surfaceMutedFor(context),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: _SeatMapGrid(
        seats: data.seats,
        vehicleType: data.vehicleType,
        selectedSeatId: selectedSeat,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ClientColors.primaryContainerFor(context),
            ),
            child: Icon(
              Icons.event_seat_outlined,
              size: 36,
              color: ClientColors.primaryFor(context),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.seatSelection_selectSeatToContinue,
            textAlign: TextAlign.center,
            style: ClientTypography.bodyMedium(context).copyWith(
              fontWeight: FontWeight.w700,
              color: ClientColors.textPrimaryFor(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.seatSelection_tapAvailableSeatHint,
            textAlign: TextAlign.center,
            style: ClientTypography.bodySmall(context).copyWith(
              color: ClientColors.textSecondaryFor(context),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedSeatsSummary(BuildContext context, String seatId) {
    final l10n = context.l10n;
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.primaryContainerFor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ClientColors.primaryMuted, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ClientColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.check_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.seatSelection_seatSelectedTitle('$seatNum'),
                  style: ClientTypography.bodyMedium(context).copyWith(
                    fontWeight: FontWeight.w800,
                    color: ClientColors.textPrimaryFor(context),
                  ),
                ),
                Text(
                  l10n.seatSelection_seatSummaryLine(
                    data.pricePerSeat.toStringAsFixed(2),
                    loaded.total.toStringAsFixed(2),
                  ),
                  style: ClientTypography.bodySmall(
                    context,
                  ).copyWith(color: ClientColors.textSecondaryFor(context)),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Row(
        children: [
          const Icon(Icons.touch_app_rounded, color: ClientColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.seatSelection_hintCardBody,
              style: ClientTypography.bodySmall(
                context,
              ).copyWith(color: ClientColors.textSecondaryFor(context)),
            ),
          ),
        ],
      ),
    );
  }

  /// Maps the raw error code emitted by [SeatSelectionCubit] to a localized,
  /// user-friendly message. The cubit has no BuildContext, so it stores a
  /// stable code and this widget resolves the copy from AppLocalizations.
  String? _lockErrorMessage(BuildContext context, String? code) {
    if (code == null || code.trim().isEmpty) return null;
    if (code == 'seat_unavailable') {
      return context.l10n.seatSelection_lockErrorSeatUnavailable;
    }
    return code;
  }

  Widget _buildBottomSummary(BuildContext context, String? seatNumStr) {
    final width = MediaQuery.sizeOf(context).width;
    final maxContentWidth = width >= 900
        ? 720.0
        : (width >= 600 ? 560.0 : width);

    return Container(
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context).withAlpha(245),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: ClientColors.borderFor(context))),
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
                isLoading: loaded.isLocking,
                errorMessage: _lockErrorMessage(context, loaded.lockError),
                onConfirm: selectedSeat == null || loaded.isLocking
                    ? null
                    : () async {
                        final locked = await context
                            .read<SeatSelectionCubit>()
                            .lockSelectedSeat();
                        if (!locked || !context.mounted) return;
                        Navigator.of(context).pushNamed(
                          '/subscription',
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
                            'driverRating': data.driverRating,
                            'driverImageUrl': data.driverImageUrl,
                            'vehicleName': [
                              data.vehicleName,
                              data.vehicleModel,
                            ].where((part) => part.trim().isNotEmpty).join(' '),
                            'vehicleImageUrl': data.vehicleImageUrl,
                            'baseFare': data.pricePerSeat,
                            'serviceFee': 0,
                            'tax': 0,
                          },
                        );
                      },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The trip's real seats drawn in the cabin its vehicle type resolves to,
/// through the one seat renderer the whole EWT ecosystem shares.
class _SeatMapGrid extends StatelessWidget {
  const _SeatMapGrid({
    required this.seats,
    required this.vehicleType,
    required this.selectedSeatId,
  });

  final List<SeatOption> seats;
  final String vehicleType;
  final String? selectedSeatId;

  @override
  Widget build(BuildContext context) {
    final ordered = [...seats]
      ..sort((a, b) {
        final byRow = a.row.compareTo(b.row);
        return byRow != 0 ? byRow : a.column.compareTo(b.column);
      });
    final blueprint = VehicleSeatLayouts.resolveRaw(
      vehicleType: vehicleType,
      seats: [for (final seat in ordered) (row: seat.row, column: seat.column)],
    );

    return VehicleSeatLayout(
      blueprint: blueprint,
      seats: [
        for (final seat in ordered)
          VehicleSeatData(
            id: seat.id,
            label: seat.displayLabel,
            state: seat.id == selectedSeatId
                ? SeatViewState.selected
                : seat.isAvailable
                ? SeatViewState.available
                : SeatViewState.occupied,
            
            enabled: seat.isAvailable,
          ),
      ],
      mode: SeatLayoutMode.selection,
      showLegend: true,
      labels: clientSeatLabels(context),
      onSeatTap: (seat) =>
          context.read<SeatSelectionCubit>().selectSeat(seat.id),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ClientColors.surfaceMutedFor(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: ClientColors.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: ClientTypography.bodySmall(context).copyWith(
              fontWeight: FontWeight.w600,
              color: ClientColors.textPrimaryFor(context),
            ),
          ),
        ],
      ),
    );
  }
}
