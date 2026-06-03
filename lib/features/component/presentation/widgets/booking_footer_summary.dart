import 'package:flutter/material.dart';
import 'package:bmt_app/core/theme/text_themes.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

class BookingFooterSummary extends StatelessWidget {
  final String? selectedSeat;
  final VoidCallback? onConfirm;
  final double pricePerSeat;

  const BookingFooterSummary({
    super.key,
    required this.selectedSeat,
    required this.onConfirm,
    this.pricePerSeat = 25,
  });

  int get _seatCount => selectedSeat == null ? 0 : 1;

  double get _total => _seatCount * pricePerSeat;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasSeat = selectedSeat != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!hasSeat)
          _EmptySelectionBanner(scheme: scheme)
        else
          AppSurface(
            padding: const EdgeInsets.all(14),
            radius: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected seats',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _PriceStat(
                        label: 'Seats',
                        value: '$_seatCount',
                        icon: Icons.event_seat_rounded,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: _PriceStat(
                        label: 'Seat numbers',
                        value: 'Seat $selectedSeat',
                        icon: Icons.confirmation_number_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _PriceStat(
                        label: 'Per seat',
                        value: 'EGP ${pricePerSeat.toStringAsFixed(2)}',
                        icon: Icons.payments_outlined,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Total',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            'EGP ${_total.toStringAsFixed(2)}',
                            style: AppTextThemes.priceEmphasis(
                              scheme,
                            ).copyWith(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (hasSeat) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'EGP ${_total.toStringAsFixed(2)}',
                    style: AppTextThemes.priceEmphasis(
                      scheme,
                    ).copyWith(fontSize: 20),
                  ),
                  Text(
                    '$_seatCount seat selected',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: AppButton(
                label: hasSeat ? 'Continue Booking' : 'Select a Seat',
                height: 52,
                onPressed: onConfirm ?? () {},
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptySelectionBanner extends StatelessWidget {
  const _EmptySelectionBanner({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withAlpha(90)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.event_seat_outlined,
            color: scheme.onSurface.withAlpha(140),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Select one or more seats to continue',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withAlpha(180),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceStat extends StatelessWidget {
  const _PriceStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: scheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleSmall),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
