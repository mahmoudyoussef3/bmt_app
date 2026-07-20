import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';

/// One of the small square affordances down the trailing edge of a passenger
/// card — edit status, call, message.
class PassengerActionButton extends StatelessWidget {
  const PassengerActionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color color;

  /// Null renders the button visibly unavailable. The affordance stays in
  /// place so the row of actions doesn't reflow from card to card.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final resolved = enabled
        ? color
        : Theme.of(context).colorScheme.onSurface.withAlpha(60);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: CaptainDesignTokens.br12,
          // A 40pt box is below the 48pt minimum touch target, so the tap area
          // is widened past the paint bounds rather than growing the visual.
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: resolved.withAlpha(20),
                borderRadius: CaptainDesignTokens.br12,
                border: Border.all(color: resolved.withAlpha(50)),
              ),
              child: Icon(icon, size: 20, color: resolved),
            ),
          ),
        ),
      ),
    );
  }
}
