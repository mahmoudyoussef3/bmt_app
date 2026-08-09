import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Where an operator drives, as chips.
///
/// [limit] caps how many are spelled out before the rest collapse into a "+N"
/// chip: on a directory card the row must stay one line tall no matter how many
/// governorates an office serves, while the profile masthead shows them all.
class OfficeServiceAreas extends StatelessWidget {
  const OfficeServiceAreas({
    super.key,
    required this.areas,
    this.limit,
    this.alignment = WrapAlignment.start,
  });

  final List<String> areas;
  final int? limit;

  /// How the chips sit in their row. Start on a directory card, where they
  /// hang off the same margin as the text above them; centred in the profile
  /// masthead, which is a centred composition.
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) {
    if (areas.isEmpty) return const SizedBox.shrink();

    final cap = limit;
    final shown = cap == null || areas.length <= cap
        ? areas
        : areas.take(cap).toList(growable: false);
    final hidden = areas.length - shown.length;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: alignment,
      children: [
        for (final area in shown) _AreaChip(label: area),
        if (hidden > 0)
          _AreaChip(
            label: context.l10n.offices_moreAreasCount(hidden),
            withPin: false,
          ),
      ],
    );
  }
}

class _AreaChip extends StatelessWidget {
  const _AreaChip({required this.label, this.withPin = true});

  final String label;
  final bool withPin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: withPin ? 8 : 10, vertical: 5),
      decoration: BoxDecoration(
        color: ClientColors.primaryContainerFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (withPin) ...[
            Icon(
              Icons.place_rounded,
              size: 11,
              color: ClientColors.onPrimaryContainerFor(context).withAlpha(150),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: ClientTypography.labelSmall(context).copyWith(
              color: ClientColors.onPrimaryContainerFor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
