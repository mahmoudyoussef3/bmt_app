import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';

/// Shows a driver-phone dialog, or a friendly "not available yet" message
/// when the trip has no phone on file.
void showTrackingContactDialog(BuildContext context, String title, String? phone) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: ClientColors.surfaceFor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              phone == null || phone.trim().isEmpty
                  ? 'Driver phone is not available for this trip yet.'
                  : 'Phone: $phone',
              style: TextStyle(fontSize: 13, color: ClientColors.textSecondaryFor(context)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close', style: TextStyle(color: ClientColors.primary)),
          ),
        ],
      );
    },
  );
}
