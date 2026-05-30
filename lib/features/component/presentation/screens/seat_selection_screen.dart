import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:bmt_app/features/component/presentation/models/payment_models.dart';
import 'package:bmt_app/features/component/presentation/screens/payment_checkout_screen.dart';
import 'package:bmt_app/features/component/presentation/widgets/booking_footer_summary.dart';
import 'package:bmt_app/features/component/presentation/widgets/interactive_seat.dart';
import 'package:bmt_app/features/component/presentation/widgets/seat_legend.dart';

class SeatSelectionScreen extends StatefulWidget {
  const SeatSelectionScreen({super.key});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  final ValueNotifier<String?> _selectedSeat = ValueNotifier<String?>(null);

  final List<_SeatSpec> _seats = const [
    _SeatSpec('1', SeatStatus.reserved),
    _SeatSpec('2', SeatStatus.reserved),
    _SeatSpec('3', SeatStatus.reserved),
    _SeatSpec('4', SeatStatus.available),
    _SeatSpec('5', SeatStatus.available),
    _SeatSpec('6', SeatStatus.available),
    _SeatSpec('7', SeatStatus.available),
    _SeatSpec('8', SeatStatus.reserved),
    _SeatSpec('9', SeatStatus.available),
    _SeatSpec('10', SeatStatus.available),
    _SeatSpec('11', SeatStatus.available),
    _SeatSpec('12', SeatStatus.available),
    _SeatSpec('13', SeatStatus.reserved),
    _SeatSpec('14', SeatStatus.available),
    _SeatSpec('15', SeatStatus.available),
  ];

  @override
  Widget build(BuildContext context) {
    final availableCount = _seats
        .where((seat) => seat.status == SeatStatus.available)
        .length;
    final width = MediaQuery.sizeOf(context).width;
    final contentPadding = width < 380 ? 16.0 : 20.0;
    final horizontalGap = width < 380 ? 8.0 : 12.0;
    final aisleGap = width < 380 ? 20.0 : 28.0;
    final rowGap = width < 380 ? 10.0 : 14.0;

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
              _buildHeader(context, availableCount),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    contentPadding,
                    12,
                    contentPadding,
                    24,
                  ),
                  children: [
                    _buildTripOverview(context, availableCount),
                    const SizedBox(height: 14),
                    _buildBusLayout(
                      context,
                      horizontalGap: horizontalGap,
                      aisleGap: aisleGap,
                      rowGap: rowGap,
                    ),
                    const SizedBox(height: 14),
                    _buildHintCard(context),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
              _buildBottomSummary(context),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _selectedSeat.dispose();
    super.dispose();
  }

  Widget _buildHeader(BuildContext context, int availableCount) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withAlpha(28),
            scheme.secondary.withAlpha(16),
            scheme.surfaceContainerHighest,
          ],
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
                colors: [scheme.primary, scheme.secondary],
              ),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withAlpha(40),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
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
                        '$availableCount free',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  'Banha Station → Smart Village',
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

  Widget _buildTripOverview(BuildContext context, int availableCount) {
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
                  '$availableCount open',
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
            children: const [
              _InfoPill(
                icon: Icons.route_rounded,
                label: 'Banha Station → Smart Village',
              ),
              _InfoPill(icon: Icons.schedule_rounded, label: 'Departs 8:40 AM'),
              _InfoPill(icon: Icons.groups_rounded, label: '15-seat microbus'),
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
            seats: _seats,
            selectedNotifier: _selectedSeat,
            horizontalGap: horizontalGap,
            aisleGap: aisleGap,
            rowGap: rowGap,
          ),
          const SizedBox(height: 18),
          const SeatLegend(),
        ],
      ),
    );
  }

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

  Widget _buildBottomSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withAlpha(245),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor.withAlpha(70)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(24),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ValueListenableBuilder<String?>(
          valueListenable: _selectedSeat,
          builder: (context, value, _) => BookingFooterSummary(
            selectedSeat: value,
            onConfirm: value == null
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PaymentCheckoutScreen(
                        checkoutData: PaymentCheckoutData(
                          pickupPoint: 'Banha Station',
                          destination: 'Smart Village',
                          vehicleNumber: 'MB-15-2847',
                          departureTime: '8:40 AM',
                          arrivalTime: '9:20 AM',
                          selectedSeat: value,
                          driverName: 'Ahmed Mohamed',
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SeatSpec {
  final String id;
  final SeatStatus status;

  const _SeatSpec(this.id, this.status);
}

class _SeatMapGrid extends StatelessWidget {
  final List<_SeatSpec> seats;
  final ValueNotifier<String?> selectedNotifier;
  final double horizontalGap;
  final double aisleGap;
  final double rowGap;

  const _SeatMapGrid({
    required this.seats,
    required this.selectedNotifier,
    required this.horizontalGap,
    required this.aisleGap,
    required this.rowGap,
  });

  _SeatSpec _seat(String id) => seats.firstWhere((seat) => seat.id == id);

  Widget _seatTile(String id) {
    final spec = _seat(id);
    return InteractiveSeat(
      id: spec.id,
      initialStatus: spec.status,
      selectedNotifier: selectedNotifier,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _tripleRow(['1', '2', '3']),
        SizedBox(height: rowGap),
        _pairSingleRow(['4', '5'], '6'),
        SizedBox(height: rowGap),
        _pairSingleRow(['7', '8'], '9'),
        SizedBox(height: rowGap),
        _pairSingleRow(['10', '11'], '12'),
        SizedBox(height: rowGap),
        _tripleRow(['13', '14', '15']),
      ],
    );
  }

  Widget _tripleRow(List<String> ids) {
    return Row(
      children: [
        Expanded(child: _seatTile(ids[0])),
        SizedBox(width: horizontalGap),
        Expanded(child: _seatTile(ids[1])),
        SizedBox(width: horizontalGap),
        Expanded(child: _seatTile(ids[2])),
      ],
    );
  }

  Widget _pairSingleRow(List<String> leftSeats, String rightSeat) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Expanded(child: _seatTile(leftSeats[0])),
              SizedBox(width: horizontalGap),
              Expanded(child: _seatTile(leftSeats[1])),
            ],
          ),
        ),
        SizedBox(width: aisleGap),
        Expanded(child: _seatTile(rightSeat)),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

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
