import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// Small uppercase section header ("Recent", "All") used inside
/// [SelectionPickerSheet]'s option list.
class SelectionSectionLabel extends StatelessWidget {
  const SelectionSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: ClientTypography.labelSmall(context).copyWith(
        color: ClientColors.textTertiaryFor(context),
        letterSpacing: 0.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// Empty state shown inside [SelectionPickerSheet] when there is no data at
/// all, or when a search query matches nothing.
class SelectionEmptyState extends StatelessWidget {
  const SelectionEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: ClientColors.textTertiaryFor(context)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: ClientTypography.bodyMedium(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
