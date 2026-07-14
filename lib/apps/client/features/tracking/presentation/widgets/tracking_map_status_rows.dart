import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/core/widgets/maps/map_style.dart';

/// The lead line of the map status card: a tinted glyph, a caption, the fact
/// that matters, and an optional trailing badge.
class TrackingHeadlineRow extends StatelessWidget {
  const TrackingHeadlineRow({
    super.key,
    required this.icon,
    required this.tone,
    required this.caption,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final Color tone;
  final String caption;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: tone.withAlpha(28),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: tone),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                caption,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: MapStyle.onSurfaceMuted(context),
                ),
              ),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                  color: MapStyle.onSurface(context),
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}

/// Who is driving — deliberately the quiet line.
class TrackingDriverRow extends StatelessWidget {
  const TrackingDriverRow({
    super.key,
    required this.initials,
    required this.name,
    required this.plate,
    required this.trailing,
  });

  final String initials;
  final String name;
  final String plate;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: ClientColors.primaryLight,
          child: Text(
            initials,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: ClientColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            '$name · $plate',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: MapStyle.onSurfaceMuted(context),
            ),
          ),
        ),
        const SizedBox(width: 6),
        trailing,
      ],
    );
  }
}
