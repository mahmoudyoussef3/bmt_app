import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// One column of the hero's fact strip.
class HeroFact {
  const HeroFact({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;
}

/// The date / departure / seat strip at the foot of the trip hero.
///
/// A single frosted panel with hairline dividers rather than three loose
/// pills: the facts line up on a shared baseline, so the eye scans them in one
/// pass instead of hopping between floating shapes.
class HeroFactStrip extends StatelessWidget {
  const HeroFactStrip({super.key, required this.facts});

  final List<HeroFact> facts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha(46)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < facts.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 30,
                color: Colors.white.withAlpha(46),
              ),
            Expanded(child: _FactCell(fact: facts[i])),
          ],
        ],
      ),
    );
  }
}

class _FactCell extends StatelessWidget {
  const _FactCell({required this.fact});

  final HeroFact fact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(fact.icon, size: 13, color: Colors.white.withAlpha(180)),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  fact.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.labelSmall(context).copyWith(
                    color: Colors.white.withAlpha(180),
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            fact.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: ClientTypography.bodyMedium(
              context,
            ).copyWith(color: Colors.white, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
