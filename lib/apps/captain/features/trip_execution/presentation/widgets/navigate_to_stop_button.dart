import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/domain/entities/assigned_trip.dart';
import 'package:bmt_app/core/widgets/app_snackbar.dart';

class NavigateToStopButton extends StatelessWidget {
  const NavigateToStopButton({super.key, required this.stop});

  final AssignedTripStop? stop;

  @override
  Widget build(BuildContext context) {
    final target = stop;
    if (target == null || !target.hasCoordinates) {
      return const SizedBox.shrink();
    }

    return OutlinedButton.icon(
      onPressed: () => _openInMaps(context, target),
      icon: const Icon(Icons.directions_rounded),
      label: Text(
        'التنقل إلى ${target.name}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: CaptainDesignTokens.s12),
        shape: const RoundedRectangleBorder(
          borderRadius: CaptainDesignTokens.br16,
        ),
      ),
    );
  }

  Future<void> _openInMaps(
    BuildContext context,
    AssignedTripStop target,
  ) async {
    final isApple = Theme.of(context).platform == TargetPlatform.iOS;
    final uri = Uri.parse(
      isApple
          ? 'https://maps.apple.com/?daddr=${target.latitude},${target.longitude}'
          : 'https://www.google.com/maps/search/?api=1'
                '&query=${target.latitude},${target.longitude}',
    );

    bool launched;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }

    if (!launched && context.mounted) {
      AppSnackbar.error(context, 'تعذر فتح تطبيق الخرائط على هذا الجهاز');
    }
  }
}
