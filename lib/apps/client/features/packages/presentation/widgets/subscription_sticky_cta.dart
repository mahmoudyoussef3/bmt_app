import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

/// The bottom action bar that stays pinned below a scrolling pane.
class SubscriptionStickyCta extends StatelessWidget {
  const SubscriptionStickyCta({
    super.key,
    required this.label,
    required this.onPressed,
    this.note,
  });

  final String label;
  final VoidCallback onPressed;

  /// One line above the button explaining what pressing it leads to. The
  /// package pane uses it to say where the price appears, so the rider is not
  /// left looking for a figure the catalogue cannot give them.
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        ClientSpacing.md,
        ClientSpacing.sm,
        ClientSpacing.md,
        ClientSpacing.md,
      ),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(ClientRadius.lg),
        ),
        border: Border(top: BorderSide(color: ClientColors.borderFor(context))),
        boxShadow: ClientElevation.md(context),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (note case final String line when line.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 13,
                    color: ClientColors.textTertiaryFor(context),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      line,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ClientTypography.labelSmall(
                        context,
                      ).copyWith(color: ClientColors.textTertiaryFor(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: ClientSpacing.xs),
            ],
            ClientButton(label: label, expand: true, onPressed: onPressed),
          ],
        ),
      ),
    );
  }
}
