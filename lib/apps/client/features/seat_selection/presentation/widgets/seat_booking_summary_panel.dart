import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/format_util.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Premium booking summary before continue (UI only).
class SeatBookingSummaryPanel extends StatelessWidget {
  const SeatBookingSummaryPanel({
    super.key,
    required this.selectedSeat,
    this.vehicleName,
    this.route,
    this.pricePerSeat = 25.0,
    this.onPassengerDetailsTap,
  });

  final String? selectedSeat;
  final String? vehicleName;
  final String? route;
  final double pricePerSeat;
  final VoidCallback? onPassengerDetailsTap;

  int get seatCount => selectedSeat == null ? 0 : 1;

  double get total => seatCount * pricePerSeat;

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedSeat != null;
    final l10n = context.l10n;
    final resolvedVehicleName = vehicleName ?? l10n.seatSelection_defaultVehicleName;
    final resolvedRoute = route ?? l10n.seatSelection_defaultRoute;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.seatSelection_bookingSummaryTitle,
            style: ClientTypography.bodyMedium(
              context,
            ).copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _SummaryRow(label: l10n.payments_vehicle, value: resolvedVehicleName),
          _SummaryRow(label: l10n.packages_route, value: resolvedRoute),
          _SummaryRow(
            label: l10n.seatSelection_selectedSeatLabel,
            value: hasSelection ? l10n.home_seatLabel('$selectedSeat') : '—',
            emphasized: hasSelection,
          ),
          const SizedBox(height: 10),
          Divider(color: ClientColors.borderFor(context)),
          const SizedBox(height: 10),
          _SummaryRow(
            label: l10n.seatSelection_pricePerSeatLabel,
            value: FormatUtil.currency(context, pricePerSeat),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.seatSelection_totalAmountLabel,
                style: ClientTypography.bodyMedium(
                  context,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                FormatUtil.currency(context, total),
                style: ClientTypography.priceMedium(
                  context,
                ).copyWith(color: ClientColors.primary),
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
            child: Text(
              label,
              style: ClientTypography.bodySmall(
                context,
              ).copyWith(color: ClientColors.textSecondaryFor(context)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: ClientTypography.bodySmall(context).copyWith(
                fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
                color: emphasized ? ClientColors.primary : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
