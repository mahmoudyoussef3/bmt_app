import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';
import 'package:bmt_app/l10n/app_localizations.dart';

/// Greeting + identity row on the hero: avatar initial, time-aware greeting,
/// and the notification bell.
class HomeGreetingRow extends StatelessWidget {
  const HomeGreetingRow({
    super.key,
    required this.userName,
    required this.onOpenNotifications,
  });

  final String? userName;
  final VoidCallback onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    final firstName = _firstName(userName);
    final l10n = context.l10n;

    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(30),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withAlpha(50)),
          ),
          alignment: Alignment.center,
          child: firstName == null
              ? const Icon(
                  Icons.directions_bus_rounded,
                  color: Colors.white,
                  size: 22,
                )
              : Text(
                  firstName.characters.first.toUpperCase(),
                  style: ClientTypography.headingSmall(context).copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_greetingIcon(), size: 13, color: Colors.white.withAlpha(200)),
                  const SizedBox(width: 5),
                  Text(
                    _greeting(l10n),
                    style: ClientTypography.bodySmall(
                      context,
                    ).copyWith(color: Colors.white.withAlpha(200)),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                firstName ?? l10n.home_welcomeAboard,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ClientTypography.headingMedium(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Tooltip(
          message: l10n.common_notifications,
          child: Material(
            color: Colors.white.withAlpha(26),
            borderRadius: BorderRadius.circular(ClientRadius.md),
            child: InkWell(
              onTap: onOpenNotifications,
              borderRadius: BorderRadius.circular(ClientRadius.md),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(ClientRadius.md),
                  border: Border.all(color: Colors.white.withAlpha(45)),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String? _firstName(String? value) {
    final cleaned = value?.trim();
    if (cleaned == null || cleaned.isEmpty || cleaned.toLowerCase() == 'user') {
      return null;
    }
    return cleaned.split(RegExp(r'\s+')).first;
  }

  static String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.home_greetingMorning;
    if (hour < 17) return l10n.home_greetingAfternoon;
    return l10n.home_greetingEvening;
  }

  static IconData _greetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) return Icons.wb_sunny_rounded;
    if (hour < 17) return Icons.wb_cloudy_rounded;
    return Icons.nights_stay_rounded;
  }
}
