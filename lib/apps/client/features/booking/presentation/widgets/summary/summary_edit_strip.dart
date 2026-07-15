import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/pressable_scale.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// A wrong seat or a wrong date found on the review screen used to mean backing
/// out of the whole wizard. These jump straight to the step that owns the
/// choice, and the wizard keeps every other answer.
class SummaryEditStrip extends StatelessWidget {
  const SummaryEditStrip({super.key, required this.onEditStep});

  final ValueChanged<int> onEditStep;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final targets = <(String, IconData, int)>[
      (l10n.booking_stepStops, Icons.place_rounded, 0),
      (l10n.notifications_categoryTrip, Icons.schedule_rounded, 1),
      (l10n.payments_stepSeat, Icons.event_seat_rounded, 2),
      (l10n.booking_fare, Icons.local_offer_rounded, 3),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.booking_needAChange,
          style: ClientTypography.labelMedium(
            context,
          ).copyWith(color: ClientColors.textSecondaryFor(context)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final (label, icon, step) in targets)
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: _EditChip(
                    label: label,
                    icon: icon,
                    onTap: () => onEditStep(step),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _EditChip extends StatelessWidget {
  const _EditChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = ClientColors.primaryFor(context);

    return PressableScale(
      onTap: onTap,
      scale: 0.95,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ClientColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(ClientRadius.pill),
          border: Border.all(color: ClientColors.borderFor(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: accent),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.labelMedium(
                  context,
                ).copyWith(color: accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
