import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';

/// The small muted heading above a block on the My Subscription pane.
class PackageSectionTitle extends StatelessWidget {
  const PackageSectionTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: ClientColors.textTertiaryFor(context),
      ),
    );
  }
}
