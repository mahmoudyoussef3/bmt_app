import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// A tappable pickup/destination row in the map selection panel.
class MapLocationSelector extends StatelessWidget {
  const MapLocationSelector({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(ClientRadius.md),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ClientColors.surfaceMutedFor(context),
            borderRadius: BorderRadius.circular(ClientRadius.md),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withAlpha(22),
                  borderRadius: BorderRadius.circular(ClientRadius.md),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Labels(label: label, value: value, subtitle: subtitle),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: enabled
                    ? ClientColors.primaryFor(context)
                    : ClientColors.textTertiaryFor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Labels extends StatelessWidget {
  const _Labels({
    required this.label,
    required this.value,
    required this.subtitle,
  });

  final String label;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: ClientTypography.labelSmall(
            context,
          ).copyWith(color: ClientColors.textSecondaryFor(context)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.labelLarge(
            context,
          ).copyWith(fontWeight: FontWeight.w900),
        ),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ClientTypography.bodySmall(context).copyWith(
            color: ClientColors.textTertiaryFor(context),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
