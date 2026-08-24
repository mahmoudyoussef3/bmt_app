import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// One tinted row of the route search card: the pin, the `from`/`to` label,
/// the station, and the chevron that opens the picker.
///
/// [value] is the station the rider actually chose; while it is empty the row
/// shows [placeholder] in the muted tertiary tone, so a filled row reads as a
/// real selection rather than as decoration.
class HomeRouteSearchField extends StatelessWidget {
  const HomeRouteSearchField({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(ClientRadius.md);
    final hasValue = value.trim().isNotEmpty;

    return Material(
      color: ClientColors.surfaceMutedFor(context),
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 10, 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: ClientColors.primaryFor(context)),
              const SizedBox(width: 10),
              Text(
                label,
                style: ClientTypography.labelMedium(
                  context,
                ).copyWith(color: ClientColors.textTertiaryFor(context)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasValue ? value : placeholder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTypography.bodyMedium(context).copyWith(
                    color: hasValue
                        ? ClientColors.textPrimaryFor(context)
                        : ClientColors.textTertiaryFor(context),
                    fontWeight: hasValue ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: ClientColors.textTertiaryFor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
