import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// The brand block at the top of an auth screen: the same gradient app mark the
/// welcome screen opens with, a warm [title], and one supporting line.
///
/// The screen's *name* lives in the app bar, so the title here is the greeting
/// ("Welcome back"), never a second copy of the toolbar text.
class AuthHero extends StatelessWidget {
  const AuthHero({super.key, this.title, required this.subtitle});

  final String? title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: ClientColors.primaryGradientFor(context),
            borderRadius: BorderRadius.circular(ClientRadius.lg),
            boxShadow: [
              BoxShadow(
                color: ClientColors.primary.withAlpha(70),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_bus_rounded,
            color: ClientColors.textInverse,
            size: 30,
          ),
        ),
        const SizedBox(height: ClientSpacing.md),
        if (title case final String heading) ...[
          Text(
            heading,
            textAlign: TextAlign.center,
            style: ClientTypography.headingLarge(
              context,
            ).copyWith(color: ClientColors.textPrimaryFor(context)),
          ),
          const SizedBox(height: ClientSpacing.xs),
        ],
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: ClientTypography.bodyMedium(
            context,
          ).copyWith(color: ClientColors.textSecondaryFor(context)),
        ),
      ],
    );
  }
}
