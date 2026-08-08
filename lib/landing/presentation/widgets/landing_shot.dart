import 'package:flutter/material.dart';

import 'package:bmt_app/core/theme/spacing.dart';

/// A real product screenshot, already framed (browser chrome or device bezel)
/// and exported on a transparent background by `tool/showcase`.
///
/// The framing lives in the asset rather than in this widget on purpose: the
/// same PNG is reused across the marketing compositions and this page, so a
/// visitor and a case study see the product framed identically. Nothing here
/// draws over the screenshot — the product's own pixels are the content.
class LandingShot extends StatelessWidget {
  const LandingShot({super.key, required this.asset, this.caption, this.maxWidth});

  /// File name under `assets/showcase/`, without the extension.
  final String asset;

  /// What the screen is, in the page's voice. Omitted where the surrounding
  /// copy already names it.
  final String? caption;

  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final image = Image.asset(
      'assets/showcase/$asset.png',
      fit: BoxFit.contain,
      // Screenshots are wide; letting them scale with the column keeps the
      // console readable on a laptop without cropping it on a phone.
      filterQuality: FilterQuality.medium,
    );

    final content = caption == null
        ? image
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              image,
              const SizedBox(height: AppSpacing.medium),
              Text(
                caption!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

    if (maxWidth == null) return content;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth!),
        child: content,
      ),
    );
  }
}
