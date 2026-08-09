import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// What this office publishes, counted.
typedef OfficeProfileCounts = ({int departures, int routes});

/// Which block of the profile a stat cell jumps to.
enum OfficeProfileSection { departures, routes }

/// The masthead's closing strip: how much this office is actually selling.
///
/// It reads as a profile's stat band — the figure large, its noun beneath —
/// and doubles as wayfinding: a rider who came for "does this company run my
/// corridor?" taps Routes and lands on it instead of scrolling the whole
/// departure board first.
class OfficeProfileStats extends StatelessWidget {
  const OfficeProfileStats({
    super.key,
    required this.counts,
    required this.onSelect,
  });

  final OfficeProfileCounts counts;
  final ValueChanged<OfficeProfileSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              icon: Icons.departure_board_rounded,
              value: counts.departures,
              label: l10n.offices_statDepartures,
              onTap: () => onSelect(OfficeProfileSection.departures),
            ),
          ),
          const SizedBox(width: ClientSpacing.sm),
          Expanded(
            child: _StatCell(
              icon: Icons.alt_route_rounded,
              value: counts.routes,
              label: l10n.offices_statRoutes,
              onTap: () => onSelect(OfficeProfileSection.routes),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final int value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // An empty section is still worth landing on — the empty note is the answer
    // to "does this office have any?" — but it must not promise a list.
    final muted = value == 0;
    final accent = muted
        ? ClientColors.textTertiaryFor(context)
        : ClientColors.primaryFor(context);

    return ClientCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: ClientSpacing.md, horizontal: ClientSpacing.sm),
      backgroundColor: muted 
          ? ClientColors.surfaceFor(context) 
          : accent.withAlpha(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: accent),
              const SizedBox(width: 8),
              Text(
                '$value',
                style: ClientTypography.headingMedium(
                  context,
                ).copyWith(fontWeight: FontWeight.w900, color: accent),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ClientTypography.labelMedium(
              context,
            ).copyWith(
              color: muted 
                  ? ClientColors.textTertiaryFor(context) 
                  : ClientColors.textSecondaryFor(context),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
