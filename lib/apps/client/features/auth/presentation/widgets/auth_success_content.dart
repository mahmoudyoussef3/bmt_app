import 'package:flutter/material.dart';

import 'package:bmt_app/l10n/app_localizations.dart';

import 'auth_success_perk_row.dart';

/// The animated headline, subtitle and (when a session was created) the perk
/// list on the account-success screen. Both blocks fade in via [fade].
class AuthSuccessContent extends StatelessWidget {
  const AuthSuccessContent({
    super.key,
    required this.created,
    required this.email,
    required this.fade,
  });

  final bool created;
  final String? email;
  final Animation<double> fade;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        FadeTransition(
          opacity: fade,
          child: Column(
            children: [
              Text(
                created
                    ? l10n.authSuccess_createdTitle
                    : l10n.authSuccess_verifyTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                created
                    ? l10n.authSuccess_createdSubtitle
                    : l10n.authSuccess_verifySubtitle(email ?? ''),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (created) ...[
          const SizedBox(height: 28),
          FadeTransition(
            opacity: fade,
            child: Column(
              children: [
                AuthSuccessPerkRow(
                  icon: Icons.event_seat_rounded,
                  label: l10n.authSuccess_perkBooking,
                ),
                AuthSuccessPerkRow(
                  icon: Icons.location_on_rounded,
                  label: l10n.authSuccess_perkTracking,
                ),
                AuthSuccessPerkRow(
                  icon: Icons.card_membership_rounded,
                  label: l10n.authSuccess_perkPasses,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
