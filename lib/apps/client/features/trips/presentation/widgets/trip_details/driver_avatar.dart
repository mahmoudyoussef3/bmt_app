import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';

/// The captain's avatar: their photo when the office uploaded one, their
/// initials when it didn't.
///
/// Uses the brand container pair rather than the light-mode-only
/// `primaryLight`, so the initials stay readable in dark mode. A photo that
/// fails to load falls back to the same initials rather than a broken frame —
/// a captain is never left faceless.
class DriverAvatar extends StatelessWidget {
  const DriverAvatar({
    super.key,
    required this.initials,
    this.imageUrl = '',
    this.radius = 24,
  });

  final String initials;
  final String imageUrl;

  /// Radius in logical pixels. The captain row runs at 24 — an avatar is the
  /// section's identity mark, not its headline.
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();

    return Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ClientColors.primaryContainerFor(context),
        border: Border.all(
          color: ClientColors.primaryFor(context).withAlpha(46),
          width: 1.5,
        ),
      ),
      child: url.isEmpty
          ? _Initials(initials: initials, radius: radius)
          : Image.network(
              url,
              fit: BoxFit.cover,
              width: radius * 2,
              height: radius * 2,
              errorBuilder: (_, _, _) =>
                  _Initials(initials: initials, radius: radius),
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : _Initials(initials: initials, radius: radius),
            ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.initials, required this.radius});

  final String initials;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        maxLines: 1,
        style: ClientTypography.headingSmall(context).copyWith(
          fontSize: radius * 0.62,
          fontWeight: FontWeight.w800,
          color: ClientColors.onPrimaryContainerFor(context),
        ),
      ),
    );
  }
}
