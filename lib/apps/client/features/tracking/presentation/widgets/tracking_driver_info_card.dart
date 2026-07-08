import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';

/// Compact driver summary (avatar, name, rating, call button) for the
/// pre-trip list.
class TrackingDriverInfoCard extends StatelessWidget {
  const TrackingDriverInfoCard({
    super.key,
    required this.driverInitials,
    required this.driverName,
    required this.driverRatingLabel,
    required this.onCallDriver,
  });

  final String driverInitials;
  final String driverName;
  final String driverRatingLabel;
  final VoidCallback onCallDriver;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ClientColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ClientColors.borderFor(context)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: ClientColors.primaryLight,
            child: Text(
              driverInitials,
              style: TextStyle(fontWeight: FontWeight.bold, color: ClientColors.primary),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: ClientColors.textPrimaryFor(context),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.star_rounded, size: 14, color: scheme.tertiary),
                    const SizedBox(width: 4),
                    Text(
                      driverRatingLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: ClientColors.textPrimaryFor(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.phone_in_talk_rounded, color: ClientColors.primary),
            onPressed: onCallDriver,
          ),
        ],
      ),
    );
  }
}
