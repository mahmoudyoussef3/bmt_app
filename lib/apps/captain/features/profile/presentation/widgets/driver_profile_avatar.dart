import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';

import 'driver_profile_metrics.dart';

class DriverProfileAvatar extends StatelessWidget {
  const DriverProfileAvatar({super.key, required this.name, this.photoUrl});

  final String name;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl;
    return Container(
      width: DriverProfileMetrics.avatarSize,
      height: DriverProfileMetrics.avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: CaptainColors.primary.withAlpha(20),
        border: Border.all(
          color: CaptainColors.primary.withAlpha(70),
          width: 3,
        ),
      ),
      child: url == null
          ? _Initials(name: name)
          : ClipOval(
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _Initials(name: name),
              ),
            ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    return Center(
      child: Text(
        trimmed.isNotEmpty ? trimmed[0].toUpperCase() : '؟',
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          color: CaptainColors.primary,
        ),
      ),
    );
  }
}
