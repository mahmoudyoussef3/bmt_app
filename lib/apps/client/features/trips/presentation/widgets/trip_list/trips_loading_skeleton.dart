import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/widgets/client_skeleton.dart';

/// Loading placeholder mirroring the trip list's card shape — never a blank
/// screen or generic spinner.
class TripsLoadingSkeleton extends StatelessWidget {
  const TripsLoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          ClientSkeleton.tripCard(),
          const SizedBox(height: 12),
          ClientSkeleton.tripCard(),
          const SizedBox(height: 12),
          ClientSkeleton.tripCard(),
        ],
      ),
    );
  }
}
