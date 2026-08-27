import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bmt_app/core/localization/l10n_context.dart';

/// Hands a station's coordinates to whatever maps app the rider actually has.
///
/// The URL is the platform's **universal** https maps link rather than a
/// `geo:` scheme, so it resolves to the installed maps app when there is one
/// and falls back to the browser when there is not — a rider without Google
/// Maps installed still gets a map instead of a dead tap.
Future<void> openCoordinatesInMaps(
  BuildContext context, {
  required double latitude,
  required double longitude,
  String label = '',
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final failureMessage = context.l10n.booking_mapsAppUnavailable;
  final isApple = switch (Theme.of(context).platform) {
    TargetPlatform.iOS || TargetPlatform.macOS => true,
    _ => false,
  };
  final coordinates = '$latitude,$longitude';
  final name = label.trim();

  final uri = Uri.parse(
    isApple
        ? 'https://maps.apple.com/?ll=$coordinates'
              '&q=${Uri.encodeComponent(name.isEmpty ? coordinates : name)}'
        : 'https://www.google.com/maps/search/?api=1&query=$coordinates',
  );

  bool launched;
  try {
    launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    launched = false;
  }

  if (!launched) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(failureMessage)));
  }
}
