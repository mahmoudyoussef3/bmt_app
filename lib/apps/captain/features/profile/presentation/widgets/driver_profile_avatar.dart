import 'package:flutter/material.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_colors.dart';

import 'driver_profile_metrics.dart';

/// The captain's photo on the header gradient, falling back to their initial.
///
/// The fallback is also the error state: a broken photo URL must not leave a
/// hole in the identity block.
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
        color: Colors.white.withAlpha(40),
        border: Border.all(color: Colors.white.withAlpha(140), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
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
          fontSize: 16,
          fontWeight: FontWeight.w900,
          color: CaptainColors.primary,
        ),
      ),
    );
  }
}
