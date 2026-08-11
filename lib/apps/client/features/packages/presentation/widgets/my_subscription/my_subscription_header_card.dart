import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/offices/presentation/widgets/office_brand_decor.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

import '../../../domain/entities/my_subscription.dart';

/// The pass the rider holds, drawn as one: a brand-blue card on the same
/// letterhead the offices and home rails use, torn across the middle with what
/// is left of the subscription printed underneath.
///
/// It is the screen's only coloured surface. Everything below it — the window,
/// the ride allowance — is detail on white cards, so the eye lands on the thing
/// the rider opened the screen to see: *do I still have a package, and how much
/// of it is left*.
class MySubscriptionHeaderCard extends StatelessWidget {
  const MySubscriptionHeaderCard({super.key, required this.subscription});

  final MySubscription subscription;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: ClientColors.heroGradientFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.lg),
        boxShadow: ClientElevation.md(context),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: OfficeBrandDecor(scale: 0.7)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(ClientSpacing.md),
                child: _Identity(subscription: subscription),
              ),
              
              const TicketTearLine(),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  ClientSpacing.md,
                  ClientSpacing.xs,
                  ClientSpacing.md,
                  ClientSpacing.md,
                ),
                child: _RemainingStrip(subscription: subscription),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// What the rider bought, and whether it is still good: the plan's name under a
/// crest, its state on the trailing edge, the corridor it is bound to below.
class _Identity extends StatelessWidget {
  const _Identity({required this.subscription});

  final MySubscription subscription;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(46),
                borderRadius: BorderRadius.circular(ClientRadius.sm),
              ),
              child: const Icon(
                Icons.card_membership_rounded,
                size: 24,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: ClientSpacing.sm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  subscription.packageName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.headingMedium(
                    context,
                  ).copyWith(color: Colors.white, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(width: ClientSpacing.xs),
            _StatusPill(status: subscription.status),
          ],
        ),
        if (subscription.routeName.isNotEmpty) ...[
          const SizedBox(height: ClientSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.alt_route_rounded,
                size: 15,
                color: Colors.white.withAlpha(190),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  subscription.routeName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.bodySmall(
                    context,
                  ).copyWith(color: Colors.white.withAlpha(215)),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Active reads as the calm state — a plain white stamp on the pass — while
/// anything a rider has to act on is coloured, so the exception is the thing
/// that catches the eye rather than the norm.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  ({Color bg, Color fg, String Function(AppLocalizations) label}) get _style =>
      switch (status) {
        'active' => (
          bg: Colors.white,
          fg: ClientColors.onPrimaryContainer,
          label: (l10n) => l10n.mySubscription_statusActive,
        ),
        'expired' => (
          bg: ClientColors.journeyRed,
          fg: Colors.white,
          label: (l10n) => l10n.mySubscription_statusExpired,
        ),
        _ => (
          bg: ClientColors.journeyAmber,
          fg: Colors.white,
          label: (l10n) => l10n.mySubscription_statusPending,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final style = _style;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(ClientRadius.pill),
      ),
      child: Text(
        style.label(context.l10n),
        style: ClientTypography.labelMedium(
          context,
        ).copyWith(color: style.fg, fontWeight: FontWeight.w900),
      ),
    );
  }
}

/// The stub: the two figures that answer "how much have I got left", set as
/// large numerals over their noun — the same stat band an office profile
/// closes its identity card with.
class _RemainingStrip extends StatelessWidget {
  const _RemainingStrip({required this.subscription});

  final MySubscription subscription;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final unlimited = !subscription.hasTripLimit;

    return Row(
      children: [
        Expanded(
          child: _Stat(
            value: '${subscription.remainingDays}',
            label: l10n.mySubscription_statDaysLeft,
          ),
        ),
        Container(width: 1, height: 34, color: Colors.white.withAlpha(56)),
        Expanded(
          child: _Stat(
            
            value: unlimited ? '∞' : '${subscription.tripsRemaining}',
            semanticValue: unlimited
                ? l10n.mySubscription_unlimitedTrips
                : null,
            label: l10n.mySubscription_statRidesLeft,
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.semanticValue});

  final String value;
  final String label;

  /// Spoken instead of [value] where the glyph is not a word — the infinity
  /// mark a screen reader would otherwise skip.
  final String? semanticValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          semanticsLabel: semanticValue,
          maxLines: 1,
          style: ClientTypography.headingLarge(
            context,
          ).copyWith(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.labelSmall(context).copyWith(
            color: Colors.white.withAlpha(200),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}
