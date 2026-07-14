import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// One line of the fare breakdown: what it is on the left, what it costs on
/// the right.
class SummaryFareRow extends StatelessWidget {
  const SummaryFareRow({
    super.key,
    required this.label,
    required this.value,
    this.note,
    this.color,
    this.emphasis = false,
  });

  final String label;
  final String value;

  /// Secondary line under the label — the "why" behind a number.
  final String? note;
  final Color? color;

  /// The total. Rendered large so it wins the row.
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? ClientColors.textPrimaryFor(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: ClientTypography.bodyMedium(context).copyWith(
                    fontWeight: emphasis ? FontWeight.w800 : FontWeight.w500,
                    color: emphasis
                        ? ClientColors.textPrimaryFor(context)
                        : ClientColors.textSecondaryFor(context),
                  ),
                ),
                if (note != null)
                  Text(
                    note!,
                    style: ClientTypography.labelSmall(
                      context,
                    ).copyWith(color: ClientColors.textTertiaryFor(context)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: emphasis
                ? ClientTypography.priceMedium(
                    context,
                  ).copyWith(color: ClientColors.primaryFor(context))
                : ClientTypography.priceSmall(context).copyWith(color: tint),
          ),
        ],
      ),
    );
  }
}
