import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/features/profile/domain/entities/client_profile.dart';
import 'package:bmt_app/core/localization/format_util.dart';
import 'package:bmt_app/core/theme/app_layout.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

/// The identity card at the top of the hub: who the rider is, on the brand's
/// hero gradient — the same canvas Home uses, so the two tabs read as one app.
class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({
    super.key,
    required this.profile,
    required this.onEdit,
  });

  final ClientProfile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = profile.name.trim().isEmpty
        ? l10n.profile_guestName
        : profile.name;
    final contact = profile.phone.trim().isNotEmpty
        ? profile.phone
        : (profile.email.trim().isEmpty ? l10n.profile_noEmail : profile.email);
    final memberSince = profile.memberSince;

    return Container(
      padding: const EdgeInsets.all(AppLayout.spaceLg),
      decoration: BoxDecoration(
        gradient: ClientColors.heroGradientFor(context),
        borderRadius: BorderRadius.circular(AppLayout.radiusLg),
      ),
      child: Row(
        children: [
          _Avatar(initials: profile.initials),
          const SizedBox(width: AppLayout.spaceLg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.headingSmall(
                    context,
                  ).copyWith(color: ClientColors.textInverse),
                ),
                const SizedBox(height: 2),
                Text(
                  contact,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.bodySmall(
                    context,
                  ).copyWith(color: ClientColors.textInverse.withAlpha(210)),
                ),
                if (memberSince != null) ...[
                  const SizedBox(height: AppLayout.spaceSm),
                  Text(
                    l10n.profile_memberSince(
                      FormatUtil.date(context, memberSince),
                    ),
                    style: ClientTypography.labelSmall(
                      context,
                    ).copyWith(color: ClientColors.textInverse.withAlpha(170)),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onEdit,
            tooltip: l10n.profile_editProfile,
            icon: const Icon(Icons.edit_outlined),
            color: ClientColors.textInverse,
            style: IconButton.styleFrom(
              backgroundColor: ClientColors.textInverse.withAlpha(38),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: ClientColors.textInverse.withAlpha(46),
        shape: BoxShape.circle,
        border: Border.all(color: ClientColors.textInverse.withAlpha(90)),
      ),
      child: Text(
        initials,
        style: ClientTypography.headingMedium(
          context,
        ).copyWith(color: ClientColors.textInverse),
      ),
    );
  }
}
