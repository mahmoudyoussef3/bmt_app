import 'package:flutter/material.dart';
import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// Section label above a create-ticket field, with an optional one-line hint
/// so the client knows what we expect before they start typing.
class SupportFieldLabel extends StatelessWidget {
  const SupportFieldLabel({
    super.key,
    required this.label,
    this.hint,
    this.isRequired = false,
  });

  final String label;
  final String? hint;

  /// Marks a mandatory field with a visual "*", mirroring how optional fields
  /// already spell out "Optional —" in their [hint].
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: ClientTypography.labelLarge(context).copyWith(
                color: ClientColors.textPrimaryFor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: ClientTypography.labelLarge(
                  context,
                ).copyWith(color: ClientColors.journeyRed),
              ),
            ],
          ],
        ),
        if (hint != null) ...[
          const SizedBox(height: 4),
          Text(
            hint!,
            style: ClientTypography.bodySmall(
              context,
            ).copyWith(color: ClientColors.textSecondaryFor(context)),
          ),
        ],
        const SizedBox(height: 10),
      ],
    );
  }
}
