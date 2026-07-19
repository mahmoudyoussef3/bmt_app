import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// One stop on the hero's journey rail: its node, label, place name, and an
/// optional trailing time.
class HeroJourneyStop extends StatelessWidget {
  const HeroJourneyStop({
    super.key,
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
