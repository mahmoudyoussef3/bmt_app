import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';
import 'package:bmt_app/apps/captain/core/theme/captain_typography.dart';

import 'driver_profile_metrics.dart';

/// The captain's face, or their initials when the office has not uploaded one.
///
/// The ring is a hairline over a brand tint rather than the old 3px brand
/// border: at 88px with a heavy ring the avatar read as a button. It is the one
/// brand-coloured surface on this screen, which is all the accent the identity
/// block needs.
class DriverProfileAvatar extends StatelessWidget {
  const DriverProfileAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.size = DriverProfileMetrics.avatarSize,
  });

  final String name;
  final String? photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: CaptainColors.primary.withValues(alpha: 0.10),
        border: Border.all(
          color: CaptainColors.primary.withValues(alpha: 0.22),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null || url.isEmpty
          ? _Initials(name: name, size: size)
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _Initials(name: name, size: size),
            ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        _initialsOf(name),
        maxLines: 1,
        style: CaptainTypography.titleLarge(context).copyWith(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w900,
          color: CaptainColors.primaryInkFor(context),
          height: 1,
        ),
      ),
    );
  }

  /// The first letter of the first two words — one letter reads as a
  /// placeholder, two read as somebody's monogram.
  String _initialsOf(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return '؟';
    final first = words.first.characters.first;
    if (words.length == 1) return first;
    return '$first ${words[1].characters.first}';
  }
}
