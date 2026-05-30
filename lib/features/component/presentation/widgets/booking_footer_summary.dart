import 'package:flutter/material.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

class BookingFooterSummary extends StatelessWidget {
  final String? selectedSeat;
  final VoidCallback? onConfirm;

  const BookingFooterSummary({
    super.key,
    required this.selectedSeat,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSurface(
          padding: const EdgeInsets.all(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Seat', style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    selectedSeat == null ? 'None' : _selectedLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Fare', style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    'EGP 25.00',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        AppButton(
          label: selectedSeat == null ? 'Select a Seat' : 'Confirm Seat',
          onPressed: onConfirm ?? () {},
        ),
      ],
    );
  }

  String get _selectedLabel =>
      selectedSeat == null ? 'None' : 'Seat $selectedSeat';
}
