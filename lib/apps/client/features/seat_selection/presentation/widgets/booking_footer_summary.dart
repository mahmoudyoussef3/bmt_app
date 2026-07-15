import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

class BookingFooterSummary extends StatelessWidget {
  final String? selectedSeat;
  final VoidCallback? onConfirm;
  final double pricePerSeat;
  final bool isLoading;
  final String? errorMessage;

  const BookingFooterSummary({
    super.key,
    required this.selectedSeat,
    required this.onConfirm,
    this.pricePerSeat = 25,
    this.isLoading = false,
    this.errorMessage,
  });

  int get _seatCount => selectedSeat == null ? 0 : 1;
  double get _total => _seatCount * pricePerSeat;

  @override
  Widget build(BuildContext context) {
    final hasSeat = selectedSeat != null;
    final l10n = context.l10n;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!hasSeat)
          _EmptySelectionBanner()
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ClientColors.surfaceFor(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: ClientColors.borderFor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.seatSelection_selectedSeatLabel,
                  style: ClientTypography.labelMedium(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: ClientColors.textPrimaryFor(context),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _PriceStat(
                        label: l10n.common_seats,
                        value: '$_seatCount',
                        icon: Icons.event_seat_rounded,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: _PriceStat(
                        label: l10n.seatSelection_seatNumbersLabel,
                        value: l10n.home_seatLabel('$selectedSeat'),
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
                        label: l10n.seatSelection_perSeatLabel,
                        value: 'EGP ${pricePerSeat.toStringAsFixed(2)}',
                        icon: Icons.payments_outlined,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            l10n.payments_total,
                            style: ClientTypography.labelSmall(context)
                                .copyWith(
                                  color: ClientColors.textSecondaryFor(context),
                                ),
                          ),
                          Text(
                            'EGP ${_total.toStringAsFixed(2)}',
                            style: ClientTypography.priceMedium(
                              context,
                            ).copyWith(color: ClientColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        if (errorMessage != null && errorMessage!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            errorMessage!,
            style: ClientTypography.bodySmall(context).copyWith(
              color: ClientColors.journeyRed,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
                    style: ClientTypography.priceMedium(
                      context,
                    ).copyWith(color: ClientColors.primary),
                  ),
                  Text(
                    l10n.seatSelection_seatCountSelected(_seatCount),
                    style: ClientTypography.bodySmall(
                      context,
                    ).copyWith(color: ClientColors.textSecondaryFor(context)),
                  ),
                ],
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: ClientButton(
                label: isLoading
                    ? l10n.seatSelection_reservingSeat
                    : hasSeat
                    ? l10n.seatSelection_continueBooking
                    : l10n.seatSelection_selectASeat,
                isLoading: isLoading,
                onPressed: onConfirm,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptySelectionBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ClientColors.surfaceMutedFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.event_seat_outlined,
            color: ClientColors.textTertiaryFor(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.l10n.seatSelection_selectSeatToContinue,
              style: ClientTypography.bodySmall(context).copyWith(
                fontWeight: FontWeight.w600,
                color: ClientColors.textSecondaryFor(context),
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
    return Row(
      children: [
        Icon(icon, size: 16, color: ClientColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: ClientTypography.labelSmall(
                  context,
                ).copyWith(color: ClientColors.textSecondaryFor(context)),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.bodySmall(context).copyWith(
                  fontWeight: FontWeight.w800,
                  color: ClientColors.textPrimaryFor(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
