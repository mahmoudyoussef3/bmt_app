import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

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
                style: ClientTypography.displayMedium(context).copyWith(
                  color: ClientColors.textPrimaryFor(context),
                ),
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
          'Smart, comfortable transport.\nBook, track, and ride — all in one place.',
          textAlign: TextAlign.center,
          style: ClientTypography.bodyMedium(context).copyWith(
            color: ClientColors.textSecondaryFor(context),
            height: 1.5,
          ),
        ),
        const SizedBox(height: ClientSpacing.xl),
        const _ValueProps(),
      ],
    );
  }
}

class _ValueProps extends StatelessWidget {
  const _ValueProps();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ValueProp(icon: Icons.event_seat_rounded, label: 'Reserve\nseats'),
        _ValueProp(icon: Icons.my_location_rounded, label: 'Live bus\ntracking'),
        _ValueProp(
          icon: Icons.card_membership_rounded,
          label: 'Manage\npasses',
        ),
      ],
    );
  }
}

class _ValueProp extends StatelessWidget {
  const _ValueProp({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: ClientColors.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(ClientRadius.md),
          ),
          child: Icon(icon, color: ClientColors.primaryFor(context), size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: ClientTypography.labelSmall(context).copyWith(
            color: ClientColors.textSecondaryFor(context),
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
