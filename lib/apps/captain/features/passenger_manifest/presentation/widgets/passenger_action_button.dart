import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';

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
