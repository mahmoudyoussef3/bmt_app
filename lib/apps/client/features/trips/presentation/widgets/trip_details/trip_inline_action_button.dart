import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

class TripInlineActionButton extends StatelessWidget {
  const TripInlineActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  final Color? color;

  final bool filled;

  static const double _height = 44;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? ClientColors.primaryFor(context);
    final foreground = filled ? ClientColors.onPrimary : accent;
    final background = filled ? accent : accent.withAlpha(22);
    final borderColor = filled ? accent : accent.withAlpha(52);
    final radius = BorderRadius.circular(ClientRadius.sm);

    return Material(
      color: background,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          height: _height,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: foreground, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.labelLarge(
                    context,
                  ).copyWith(color: foreground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
