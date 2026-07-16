import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bmt_app/apps/captain/core/theme/captain_design_tokens.dart';
import 'package:bmt_app/apps/captain/features/assigned_trips/domain/entities/assigned_trip.dart';

/// Opens the device's maps app centered on [stop], for turn-by-turn
/// navigation the app itself doesn't attempt to render. Renders nothing when
/// the stop has no saved coordinates rather than offering a button that
/// would fail.
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
      onPressed: () => _openInMaps(target),
      icon: const Icon(Icons.directions_rounded),
      label: Text(
        'التنقل إلى ${target.name}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: CaptainDesignTokens.s12),
        shape: RoundedRectangleBorder(borderRadius: CaptainDesignTokens.br16),
      ),
    );
  }

  Future<void> _openInMaps(AssignedTripStop target) {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=${target.latitude},${target.longitude}',
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
