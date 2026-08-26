import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/booking/domain/entities/booking_option.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/core/widgets/route_direction_text.dart';

/// Route Details' opening card: what this line is called, which way it runs,
/// and the three facts that decide whether it is the right line — how far,
/// how long, how many stations.
///
/// It replaces the old overview header's four-pill grid. Departure and
/// destination were two of those pills *and* the headline underneath them, so
/// the card said everything twice; here the endpoints are stated once, as a
/// direction line, and the pills are spent on facts that appear nowhere else.
class RouteIdentityCard extends StatelessWidget {
  const RouteIdentityCard({
    super.key,
    required this.route,
    required this.stopCount,
  });

  final RouteOptionData route;
  final int stopCount;

  @override
  Widget build(BuildContext context) {
    return ClientCard(
      padding: ClientSpacing.panel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Title(route: route),
          if (!route.isExactMatch) ...[
            const SizedBox(height: 14),
            _MatchNote(quality: route.matchQuality),
          ],
          const SizedBox(height: 18),
          Divider(height: 1, color: ClientColors.borderFor(context)),
          const SizedBox(height: 16),
          _FactsRow(route: route, stopCount: stopCount),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.route});

  final RouteOptionData route;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: ClientColors.primaryContainerFor(context),
            borderRadius: BorderRadius.circular(ClientRadius.md),
          ),
          child: Icon(
            Icons.alt_route_rounded,
            size: 23,
            color: ClientColors.onPrimaryContainerFor(context),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                route.routeName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.headingSmall(context),
              ),
              const SizedBox(height: 5),
              RouteDirectionText(
                origin: route.pickup,
                destination: route.destination,
                // Two lines, because a corridor's endpoints are often long
                // official names ("American University in Cairo (AUC) - New
                // Cairo") and one clipped line states neither of them.
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.bodySmall(
                  context,
                ).copyWith(color: ClientColors.textSecondaryFor(context)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The quiet version of the old full-width "closest match" banner: the same
/// warning, sized like the aside it is rather than like the headline.
class _MatchNote extends StatelessWidget {
  const _MatchNote({required this.quality});

  final RouteMatchQuality quality;

  @override
  Widget build(BuildContext context) {
    final color = ClientColors.journeyAmberFor(context);
    final message = quality == RouteMatchQuality.partial
        ? context.l10n.booking_noExactMatchCoversTrip
        : context.l10n.booking_noRouteMatchClosest;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ClientColors.journeyAmberLightFor(context),
        borderRadius: BorderRadius.circular(ClientRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 17, color: color),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: ClientTypography.bodySmall(context).copyWith(
                color: ClientColors.onJourneyAmberFor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FactsRow extends StatelessWidget {
  const _FactsRow({required this.route, required this.stopCount});

  final RouteOptionData route;
  final int stopCount;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Fact(
              icon: Icons.straighten_rounded,
              label: l10n.booking_distance,
              value: route.distance,
            ),
          ),
          const _FactDivider(),
          Expanded(
            child: _Fact(
              icon: Icons.schedule_rounded,
              label: l10n.packages_duration,
              value: route.duration,
            ),
          ),
          const _FactDivider(),
          Expanded(
            child: _Fact(
              icon: Icons.place_outlined,
              label: l10n.booking_stationsLabel,
              value: '$stopCount',
            ),
          ),
        ],
      ),
    );
  }
}

class _FactDivider extends StatelessWidget {
  const _FactDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: ClientColors.borderFor(context),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: ClientColors.textTertiaryFor(context),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.labelSmall(
                  context,
                ).copyWith(color: ClientColors.textTertiaryFor(context)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          value.trim().isEmpty ? context.l10n.common_notSet : value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.labelLarge(
            context,
          ).copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
