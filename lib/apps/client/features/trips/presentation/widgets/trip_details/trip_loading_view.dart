import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_colors.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/trips/presentation/widgets/trip_details/trip_static_app_bar.dart';

/// Trip Details' loading placeholder, mirroring the loaded layout's section
/// shapes — never a blank screen or spinner.
class TripLoadingView extends StatelessWidget {
  const TripLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ClientColors.surfaceSubtleFor(context),
      appBar: const TripStaticAppBar(title: 'Trip Details'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          ClientSkeleton(height: 120, borderRadius: 20),
          const SizedBox(height: 14),
          ClientSkeleton(height: 80, borderRadius: 20),
          const SizedBox(height: 14),
          ClientSkeleton(height: 100, borderRadius: 20),
          const SizedBox(height: 14),
          ClientSkeleton(height: 90, borderRadius: 20),
        ],
      ),
    );
  }
}
