import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/home/domain/entities/home_data.dart';
import 'package:bmt_app/core/localization/format_util.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The subscription the rider is riding on. Home renders this only when one
/// exists — plans they have not bought are left to the subscription screen.
///
/// It is the same boarding pass the bookings above it are drawn as: a tinted
/// band carrying the identity and the status, torn across, then what is left of
/// it underneath. A package is a thing a rider holds, exactly like a seat, and
/// on one screen the two must not be two different card languages.
class HomeActivePackageCard extends StatelessWidget {
  const HomeActivePackageCard({
    super.key,
    required this.package,
    required this.onTap,
  });

  final HomeActivePackageData package;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasWindow = package.endDate != null;

    return ClientCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      borderColor: ClientColors.primaryFor(context).withAlpha(70),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Band(package: package),
          if (hasWindow) ...[
            const TicketTearLine(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ClientSpacing.md,
                ClientSpacing.xs,
                ClientSpacing.md,
                ClientSpacing.md,
              ),
              child: _Validity(package: package),
            ),
          ],
        ],
      ),
    );
  }
}

/// Crest, plan, corridor, state — the header row every card on Home opens with.
class _Band extends StatelessWidget {
  const _Band({required this.package});

  final HomeActivePackageData package;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = ClientColors.primaryFor(context);

    return Container(
      padding: const EdgeInsets.all(ClientSpacing.md),
      decoration: BoxDecoration(
        color: accent.withAlpha(isDark ? 30 : 16),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(ClientRadius.lg),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withAlpha(36),
              borderRadius: BorderRadius.circular(ClientRadius.sm),
            ),
            child: Icon(Icons.card_membership_rounded, color: accent, size: 22),
          ),
          const SizedBox(width: ClientSpacing.sm),
          Expanded(child: _Titles(package: package)),
          const SizedBox(width: ClientSpacing.xs),
          ClientStatusBadge(
            status: ClientJourneyStatus.active,
            label: context.l10n.mySubscription_statusActive,
          ),
        ],
      ),
    );
  }
}

class _Titles extends StatelessWidget {
  const _Titles({required this.package});

  final HomeActivePackageData package;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          package.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.headingSmall(
            context,
          ).copyWith(fontWeight: FontWeight.w800),
        ),
        if (package.routeLabel.isNotEmpty) ...[
          const SizedBox(height: 3),
          Row(
            children: [
              Icon(
                Icons.alt_route_rounded,
                size: 13,
                color: ClientColors.textTertiaryFor(context),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  package.routeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.bodySmall(
                    context,
                  ).copyWith(color: ClientColors.textSecondaryFor(context)),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// How much of the subscription window is left — the only progress the
/// `subscriptions` table can honestly report.
///
/// The countdown leads in brand ink and the expiry date follows as the fine
/// print, because "how long have I got" is the question and the calendar date
/// is only the answer's evidence.
class _Validity extends StatelessWidget {
  const _Validity({required this.package});

  final HomeActivePackageData package;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final remaining = package.remainingDays;
    final expiring = remaining <= 3;
    final label = remaining == 0
        ? l10n.home_expiresToday
        : remaining == 1
        ? l10n.home_dayLeft
        : l10n.home_daysLeft(remaining);

    // A window closing this week is the one state on this card a rider has to
    // act on, so it stops being brand-blue and takes the attention colour.
    final accent = expiring
        ? ClientColors.journeyAmberFor(context)
        : ClientColors.primaryFor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.labelLarge(
                  context,
                ).copyWith(color: accent, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: ClientSpacing.xs),
            Text(
              l10n.home_validUntil(FormatUtil.date(context, package.endDate!)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ClientTypography.labelSmall(
                context,
              ).copyWith(color: ClientColors.textTertiaryFor(context)),
            ),
          ],
        ),
        if (package.totalDays > 0) ...[
          const SizedBox(height: ClientSpacing.xs),
          ClientMeter(value: 1 - package.remainingRatio, color: accent),
        ],
      ],
    );
  }
}
