import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

/// Loading placeholder mirroring Route Details' section layout (map, identity,
/// stations, departures) — never a blank screen or a spinner.
class RouteDetailsSkeleton extends StatelessWidget {
  const RouteDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: const [
        ClientSkeleton(height: 208, borderRadius: ClientRadius.lg),
        SizedBox(height: 14),
        ClientSkeleton(height: 168, borderRadius: ClientRadius.lg),
        SizedBox(height: 14),
        ClientSkeleton(height: 288, borderRadius: ClientRadius.lg),
        SizedBox(height: 14),
        ClientSkeleton(height: 196, borderRadius: ClientRadius.lg),
      ],
    );
  }
}
