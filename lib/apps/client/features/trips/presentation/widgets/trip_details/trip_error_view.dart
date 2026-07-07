import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_static_app_bar.dart';

/// Shown when the selected trip fails to load.
class TripErrorView extends StatelessWidget {
  const TripErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClientColors.surfaceFor(context),
      appBar: const TripStaticAppBar(title: 'Trip Details'),
      body: ClientErrorCard.fullScreen(message: message, onRetry: onRetry),
    );
  }
}
