import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

import 'welcome_value_props.dart';

/// The branded hero block on the welcome screen: app mark, "EasyWay" wordmark,
/// a supporting tagline, and three quick value props.
class WelcomeHero extends StatelessWidget {
  const WelcomeHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            gradient: ClientColors.primaryGradientFor(context),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: ClientColors.primary.withAlpha(80),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_bus_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: ClientSpacing.lg),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Easy',
                style: ClientTypography.displayMedium(
                  context,
                ).copyWith(color: ClientColors.textPrimaryFor(context)),
              ),
              TextSpan(
                text: 'Way',
                style: ClientTypography.displayMedium(
                  context,
                ).copyWith(color: ClientColors.primaryFor(context)),
              ),
            ],
          ),
        ),
        const SizedBox(height: ClientSpacing.sm),
        Text(
          context.l10n.welcome_heroTagline,
          textAlign: TextAlign.center,
          style: ClientTypography.bodyMedium(context).copyWith(
            color: ClientColors.textSecondaryFor(context),
            height: 1.5,
          ),
        ),
        const SizedBox(height: ClientSpacing.xl),
        const WelcomeValueProps(),
      ],
    );
  }
}
