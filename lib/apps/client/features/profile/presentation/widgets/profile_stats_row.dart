import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/profile/domain/entities/client_profile.dart';
import 'package:bmt_app/core/localization/format_util.dart';
import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/core/widgets/app_card.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

/// Three facts a rider actually recognises about their own account. Real
/// counts from their bookings — never a decorative placeholder.
class ProfileStatsRow extends StatelessWidget {
  const ProfileStatsRow({super.key, required this.profile});

  final ClientProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final package = profile.activePackage;

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppLayout.spaceMd,
        vertical: AppLayout.spaceLg,
      ),
      child: Row(
        children: [
          Expanded(
            child: _Stat(
              icon: Icons.check_circle_outline_rounded,
              value: FormatUtil.number(context, profile.completedTrips),
              label: l10n.profile_statTrips,
            ),
          ),
          const _Divider(),
          Expanded(
            child: _Stat(
              icon: Icons.event_seat_outlined,
              value: FormatUtil.number(context, profile.upcomingTrips),
              label: l10n.profile_statUpcoming,
            ),
          ),
          const _Divider(),
          Expanded(
            child: _Stat(
              icon: Icons.card_membership_outlined,
              value: package == null
                  ? l10n.profile_packageNone
                  : l10n.profile_packageActive,
              label: l10n.profile_statPackage,
              highlight: package != null,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      color: ClientColors.borderFor(context),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
    this.highlight = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = highlight
        ? ClientColors.journeyCyan
        : ClientColors.primaryFor(context);

    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: AppLayout.spaceSm),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.headingSmall(context),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: ClientTypography.labelSmall(
            context,
          ).copyWith(color: ClientColors.textTertiaryFor(context)),
        ),
      ],
    );
  }
}
