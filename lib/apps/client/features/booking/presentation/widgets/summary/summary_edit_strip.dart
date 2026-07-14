import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/pressable_scale.dart';

/// A wrong seat or a wrong date found on the review screen used to mean backing
/// out of the whole wizard. These jump straight to the step that owns the
/// choice, and the wizard keeps every other answer.
class SummaryEditStrip extends StatelessWidget {
  const SummaryEditStrip({super.key, required this.onEditStep});

  final ValueChanged<int> onEditStep;

  static const _targets = <(String, IconData, int)>[
    ('Stops', Icons.place_rounded, 0),
    ('Trip', Icons.schedule_rounded, 1),
    ('Seat', Icons.event_seat_rounded, 2),
    ('Fare', Icons.local_offer_rounded, 3),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Need a change?',
          style: ClientTypography.labelMedium(
            context,
          ).copyWith(color: ClientColors.textSecondaryFor(context)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final (label, icon, step) in _targets)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
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
