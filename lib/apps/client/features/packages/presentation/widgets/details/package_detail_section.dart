import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

/// One titled block of the package detail pane.
///
/// The pane used to be a run of hand-rolled containers with four different
/// paddings, radii and heading styles, which read as a form rather than as a
/// product page. Every block now goes through this shell, so the column has one
/// rhythm and a new block cannot introduce a fifth shape.
class PackageDetailSection extends StatelessWidget {
  const PackageDetailSection({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.padding,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: ClientColors.textTertiaryFor(context)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: ClientTypography.labelMedium(context).copyWith(
                  fontWeight: FontWeight.w800,
                  color: ClientColors.textTertiaryFor(context),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: ClientSpacing.xs),
        ClientCard(
          padding: padding ?? const EdgeInsets.all(ClientSpacing.md),
          child: child,
        ),
      ],
    );
  }
}
