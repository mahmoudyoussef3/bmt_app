import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/theme/client_typography.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/localization/l10n_context.dart';

/// Loading indicator shown while vehicles are being fetched.
class VehicleListingLoadingView extends StatelessWidget {
  const VehicleListingLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: ClientColors.primary),
            const SizedBox(height: 14),
            Text(
              context.l10n.booking_searchingBestOptions,
              textAlign: TextAlign.center,
              style: ClientTypography.bodyMedium(context).copyWith(
                fontWeight: FontWeight.w700,
                color: ClientColors.textPrimaryFor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared error/empty message card for the vehicle listing.
class VehicleListingMessageCard extends StatelessWidget {
  const VehicleListingMessageCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String actionLabel;
  final Widget actionIcon;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ClientColors.surfaceFor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ClientColors.borderFor(context)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: iconColor, size: 46),
              const SizedBox(height: 12),
              Text(
                title,
                style: ClientTypography.headingSmall(context),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: ClientTypography.bodyMedium(
                  context,
                ).copyWith(color: ClientColors.textSecondaryFor(context)),
              ),
              const SizedBox(height: 14),
              ClientButton(
                label: actionLabel,
                onPressed: onAction,
                icon: actionIcon,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
