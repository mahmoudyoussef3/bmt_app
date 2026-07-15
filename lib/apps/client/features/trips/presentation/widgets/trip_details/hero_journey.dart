import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The pickup → drop-off rail on the trip hero.
///
/// Replaces the single "A → B" headline, which wrapped a long route across
/// three lines and buried the arrow mid-sentence. Two anchored stops read at a
/// glance and give the hero a stable height regardless of place-name length.
class HeroJourney extends StatelessWidget {
  const HeroJourney({
    super.key,
    required this.pickup,
    required this.destination,
    required this.departureLabel,
  });

  final String pickup;
  final String destination;
  final String departureLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _JourneyStop(
          node: const _OriginNode(),
          label: context.l10n.common_pickup.toUpperCase(),
          place: pickup,
          trailing: departureLabel,
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 9, top: 4, bottom: 4),
          child: Container(
            width: 2,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(70),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        _JourneyStop(
          node: const _DestinationNode(),
          label: context.l10n.common_dropOff.toUpperCase(),
          place: destination,
        ),
      ],
    );
  }
}

class _JourneyStop extends StatelessWidget {
  const _JourneyStop({
    required this.node,
    required this.label,
    required this.place,
    this.trailing,
  });

  final Widget node;
  final String label;
  final String place;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(top: 2), child: node),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: ClientTypography.labelSmall(context).copyWith(
                  color: Colors.white.withAlpha(180),
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                place,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.headingSmall(
                  context,
                ).copyWith(color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        if (trailing != null && trailing!.isNotEmpty) ...[
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              trailing!,
              style: ClientTypography.labelLarge(
                context,
              ).copyWith(color: Colors.white, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ],
    );
  }
}

class _OriginNode extends StatelessWidget {
  const _OriginNode();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(56),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _DestinationNode extends StatelessWidget {
  const _DestinationNode();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(56),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.place_rounded, size: 12, color: Colors.white),
    );
  }
}
