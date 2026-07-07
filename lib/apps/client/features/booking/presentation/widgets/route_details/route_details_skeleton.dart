import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

/// Loading placeholder mirroring Route Details' section layout (overview,
/// timeline, pricing, available trips) — never a blank screen or spinner.
class RouteDetailsSkeleton extends StatelessWidget {
  const RouteDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        const ClientSkeleton(height: 30, width: 220),
        const SizedBox(height: 14),
        ClientSkeleton(height: 176, borderRadius: 18),
        const SizedBox(height: 14),
        ClientSkeleton(height: 220, borderRadius: 18),
        const SizedBox(height: 14),
        ClientSkeleton(height: 100, borderRadius: 18),
        const SizedBox(height: 14),
        ClientSkeleton(height: 190, borderRadius: 18),
      ],
    );
  }
}
