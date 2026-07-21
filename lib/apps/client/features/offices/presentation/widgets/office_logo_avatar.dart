import 'package:flutter/material.dart';

/// The office's logo, falling back to a storefront glyph — never a broken
/// image tile — when the office hasn't uploaded one or it fails to load.
class OfficeLogoAvatar extends StatelessWidget {
  const OfficeLogoAvatar({super.key, required this.logoUrl, this.size = 48});

  final String? logoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primary.withAlpha(20),
        borderRadius: BorderRadius.circular(size / 4),
      ),
      child: Icon(
        Icons.storefront_rounded,
        size: size * 0.5,
        color: scheme.primary,
      ),
    );

    final url = logoUrl;
    if (url == null || url.isEmpty) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 4),
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
