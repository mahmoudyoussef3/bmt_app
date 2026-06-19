import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

class TimeSelectionChip extends StatelessWidget {
  final String time;
  final bool active;
  final VoidCallback onTap;

  const TimeSelectionChip({
    super.key,
    required this.time,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active
          ? ClientColors.primaryLight
          : ClientColors.surfaceFor(context),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: active
                ? Border.all(color: ClientColors.primary, width: 2)
                : Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 18,
                color: active
                    ? ClientColors.primary
                    : ClientColors.textSecondaryFor(context),
              ),
              const SizedBox(width: 8),
              Text(
                time,
                style: ClientTypography.bodyMedium(context).copyWith(
                  fontWeight: FontWeight.w600,
                  color: active
                      ? ClientColors.primary
                      : ClientColors.textPrimaryFor(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
