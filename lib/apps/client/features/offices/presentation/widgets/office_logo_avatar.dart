import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/widgets/client_brand_avatar.dart';

/// The office's logo, falling back to the design's gradient brand tile — never
/// a broken image tile — when the office hasn't uploaded one or it fails to
/// load.
///
/// Pass [brandKey] (the office id) so the fallback picks the same one of the
/// design's three brand ramps for that operator on every screen it appears on.
class OfficeLogoAvatar extends StatelessWidget {
  const OfficeLogoAvatar({
    super.key,
    required this.logoUrl,
    this.size = 48,
    this.brandKey,
  });

  final String? logoUrl;
  final double size;
  final String? brandKey;

  @override
  Widget build(BuildContext context) {
    final fallback = ClientBrandAvatar.glyph(
      icon: Icons.storefront_rounded,
      size: size,
      brandKey: brandKey,
    );

    final url = logoUrl;
    if (url == null || url.isEmpty) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.32),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}
