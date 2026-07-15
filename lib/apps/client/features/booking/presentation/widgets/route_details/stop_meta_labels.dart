import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// What a passenger may do at a stop. Derived from the route point's
/// pickup/drop-off permissions.
enum StopCapability {
  boardAndAlight(Icons.swap_vert_rounded),
  boardOnly(Icons.login_rounded),
  alightOnly(Icons.logout_rounded),
  passThrough(Icons.do_not_disturb_alt_rounded);

  const StopCapability(this.icon);

  final IconData icon;

  static StopCapability of({
    required bool pickupAllowed,
    required bool dropoffAllowed,
  }) {
    if (pickupAllowed && dropoffAllowed) return StopCapability.boardAndAlight;
    if (pickupAllowed) return StopCapability.boardOnly;
    if (dropoffAllowed) return StopCapability.alightOnly;
    return StopCapability.passThrough;
  }
}

/// Localized caption for a [StopCapability].
String stopCapabilityLabel(BuildContext context, StopCapability capability) {
  final l10n = context.l10n;
  return switch (capability) {
    StopCapability.boardAndAlight => l10n.booking_stopCapabilityBoardAlight,
    StopCapability.boardOnly => l10n.booking_stopCapabilityBoardOnly,
    StopCapability.alightOnly => l10n.booking_stopCapabilityAlightOnly,
    StopCapability.passThrough => l10n.booking_stopCapabilityPassThrough,
  };
}

/// The quiet caption under a stop's name. Rendered as muted text rather than a
/// colored chip: capability is supporting detail, not a status to alarm on, so
/// it must not compete with the stop name or the rail.
class StopCapabilityLabel extends StatelessWidget {
  const StopCapabilityLabel({super.key, required this.capability});

  final StopCapability capability;

  @override
  Widget build(BuildContext context) {
    final isPassThrough = capability == StopCapability.passThrough;
    final color = isPassThrough
        ? ClientColors.textTertiaryFor(context)
        : ClientColors.textSecondaryFor(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(capability.icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          stopCapabilityLabel(context, capability),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Tonal pill marking the two stops that anchor the journey (start / end).
/// Intermediate stops get none — they are numbered on the rail instead.
class StopRoleChip extends StatelessWidget {
  const StopRoleChip({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(
          Theme.of(context).brightness == Brightness.dark ? 38 : 22,
        ),
        borderRadius: BorderRadius.circular(ClientRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
