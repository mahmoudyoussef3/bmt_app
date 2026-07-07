import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// A single tappable field row (pickup, destination, date, time) used by
/// [SearchTripCard].
class SearchFieldRow extends StatelessWidget {
  const SearchFieldRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.compact = false,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String placeholder;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hasValue = value.isNotEmpty;
    final display = hasValue ? value : placeholder;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: compact ? 10 : 12,
          ),
          decoration: BoxDecoration(
            color: ClientColors.surfaceSubtleFor(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: ClientTypography.labelSmall(
                        context,
                      ).copyWith(color: ClientColors.textTertiaryFor(context)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      display,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ClientTypography.bodyMedium(context).copyWith(
                        fontWeight: hasValue
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: hasValue
                            ? ClientColors.textPrimaryFor(context)
                            : ClientColors.textTertiaryFor(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: ClientColors.textTertiaryFor(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
