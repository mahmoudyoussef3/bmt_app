import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// The three quick value props beneath the welcome hero (seats / tracking /
/// passes).
class WelcomeValueProps extends StatelessWidget {
  const WelcomeValueProps({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _ValueProp(
            icon: Icons.event_seat_rounded,
            label: l10n.welcome_valueSeats,
          ),
        ),
        Expanded(
          child: _ValueProp(
            icon: Icons.my_location_rounded,
            label: l10n.welcome_valueTracking,
          ),
        ),
        Expanded(
          child: _ValueProp(
            icon: Icons.card_membership_rounded,
            label: l10n.welcome_valuePasses,
          ),
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
