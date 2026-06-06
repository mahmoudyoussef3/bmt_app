import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/text_themes.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

/// Premium booking summary before continue (UI only).
class SeatBookingSummaryPanel extends StatelessWidget {
  const SeatBookingSummaryPanel({
    super.key,
    required this.selectedSeat,
    this.vehicleName = 'Mega Coach Elite',
    this.route = 'Banha Station → Smart Village',
    this.pricePerSeat = 25.0,
    this.onPassengerDetailsTap,
  });

  final String? selectedSeat;
  final String vehicleName;
  final String route;
  final double pricePerSeat;
  final VoidCallback? onPassengerDetailsTap;

  int get seatCount => selectedSeat == null ? 0 : 1;

  double get total => seatCount * pricePerSeat;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasSelection = selectedSeat != null;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Booking summary',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (onPassengerDetailsTap != null && hasSelection)
                TextButton(
                  onPressed: onPassengerDetailsTap,
                  child: const Text('Passenger details'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _SummaryRow(label: 'Vehicle', value: vehicleName),
          _SummaryRow(label: 'Route', value: route),
          _SummaryRow(
            label: 'Selected seats',
            value: hasSelection ? 'Seat $selectedSeat' : '—',
            emphasized: hasSelection,
          ),
          const SizedBox(height: 10),
          const AppSeparator(),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Price per seat',
            value: 'EGP ${pricePerSeat.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total amount',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                'EGP ${total.toStringAsFixed(2)}',
                style: AppTextThemes.priceEmphasis(scheme),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
                color: emphasized
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
