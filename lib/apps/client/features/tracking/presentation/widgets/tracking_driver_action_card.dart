import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

/// Driver summary plus call/chat actions, shown in the active-trip sheet.
class TrackingDriverActionCard extends StatelessWidget {
  const TrackingDriverActionCard({
    super.key,
    required this.driverInitials,
    required this.driverName,
    required this.driverRatingLabel,
    required this.onCallDriver,
    required this.onChatDriver,
  });

  final String driverInitials;
  final String driverName;
  final String driverRatingLabel;
  final VoidCallback onCallDriver;
  final VoidCallback onChatDriver;

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
      child: Column(
        children: [
          Row(
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
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 14, color: scheme.tertiary),
                        const SizedBox(width: 4),
                        Text(
                          driverRatingLabel,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: ClientButton.secondary(
                  label: 'Call Driver',
                  expand: true,
                  onPressed: onCallDriver,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClientButton(
                  label: 'Chat Driver',
                  expand: true,
                  onPressed: onChatDriver,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
