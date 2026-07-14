import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

enum PasswordStrength { empty, weak, fair, good, strong }

/// Heuristic password strength used by the meter and (optionally) validation.
PasswordStrength evaluatePasswordStrength(String value) {
  if (value.isEmpty) return PasswordStrength.empty;
  var score = 0;
  if (value.length >= 8) score++;
  if (value.length >= 12) score++;
  if (RegExp(r'[A-Z]').hasMatch(value) && RegExp(r'[a-z]').hasMatch(value)) {
    score++;
  }
  if (RegExp(r'[0-9]').hasMatch(value)) score++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score++;

  if (score <= 1) return PasswordStrength.weak;
  if (score == 2) return PasswordStrength.fair;
  if (score == 3) return PasswordStrength.good;
  return PasswordStrength.strong;
}

/// Animated 4-segment password strength meter with a localized label.
/// Renders nothing until the user starts typing.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final strength = evaluatePasswordStrength(password);

    if (strength == PasswordStrength.empty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          l10n.auth_passwordHint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: ClientColors.textTertiaryFor(context),
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    final (filled, color, label) = switch (strength) {
      PasswordStrength.weak => (
        1,
        ClientColors.journeyRed,
        l10n.auth_passwordWeak,
      ),
      PasswordStrength.fair => (
        2,
        ClientColors.journeyAmber,
        l10n.auth_passwordFair,
      ),
      PasswordStrength.good => (
        3,
        ClientColors.primary,
        l10n.auth_passwordGood,
      ),
      _ => (4, ClientColors.journeyCyan, l10n.auth_passwordStrong),
    };

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(4, (index) {
              final active = index < filled;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: EdgeInsets.only(right: index == 3 ? 0 : 6),
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? color : ClientColors.borderFor(context),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${l10n.auth_passwordStrengthLabel}: ',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ClientColors.textTertiaryFor(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
