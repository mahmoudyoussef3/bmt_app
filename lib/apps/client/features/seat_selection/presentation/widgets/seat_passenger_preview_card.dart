import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Multi-passenger presentation placeholder (UI only, no booking logic).
class SeatPassengerPreviewCard extends StatelessWidget {
  const SeatPassengerPreviewCard({
    super.key,
    required this.selectedSeat,
    this.showMultiPreview = true,
  });

  final String? selectedSeat;
  final bool showMultiPreview;

  @override
  Widget build(BuildContext context) {
    if (selectedSeat == null) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.groups_rounded,
                size: 20,
                color: ClientColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.seatSelection_passengersTitle,
                style: ClientTypography.bodyMedium(
                  context,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: ClientColors.primaryLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  l10n.seatSelection_oneSeatBadge,
                  style: ClientTypography.labelSmall(context).copyWith(
                    color: ClientColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _PassengerRow(
            index: 1,
            seatLabel: 'A$selectedSeat',
            highlighted: true,
          ),
          if (showMultiPreview) ...[
            const SizedBox(height: 8),
            _PassengerRow(
              index: 2,
              seatLabel: 'A4',
              highlighted: false,
              placeholder: true,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.seatSelection_addPassengerHint,
              style: ClientTypography.bodySmall(context).copyWith(
                color: ClientColors.textTertiaryFor(context),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PassengerRow extends StatelessWidget {
  const _PassengerRow({
    required this.index,
    required this.seatLabel,
    required this.highlighted,
    this.placeholder = false,
  });

  final int index;
  final String seatLabel;
  final bool highlighted;
  final bool placeholder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlighted
            ? ClientColors.primaryLight
            : ClientColors.surfaceMutedFor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlighted
              ? ClientColors.primaryMuted
              : ClientColors.borderFor(context),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: highlighted
                ? ClientColors.primaryMuted
                : ClientColors.borderFor(context),
            child: Text(
              '$index',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: highlighted
                    ? ClientColors.primary
                    : ClientColors.textTertiaryFor(context),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Passenger $index',
                  style: ClientTypography.bodySmall(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: placeholder
                        ? ClientColors.textTertiaryFor(context)
                        : ClientColors.textPrimaryFor(context),
                  ),
                ),
                Text(
                  placeholder ? 'Awaiting seat selection' : 'Seat $seatLabel',
                  style: ClientTypography.bodySmall(context).copyWith(
                    fontWeight: FontWeight.w600,
                    color: ClientColors.textSecondaryFor(context),
                  ),
                ),
              ],
            ),
          ),
          if (!highlighted)
            const Icon(
              Icons.check_circle_rounded,
              color: ClientColors.primary,
              size: 20,
            ),
        ],
      ),
    );
  }
}
