import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/core/theme/app_layout.dart';

/// The hub's loading state, shaped like the hub itself so the content lands
/// where the skeleton promised it would.
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppLayout.pagePaddingWithTop,
      children: const [
        ClientSkeleton(height: 102, borderRadius: AppLayout.radiusLg),
        SizedBox(height: AppLayout.spaceLg),
        ClientSkeleton(height: 92, borderRadius: AppLayout.radiusLg),
        SizedBox(height: AppLayout.spaceXl),
        ClientSkeleton(height: 148, borderRadius: AppLayout.radiusLg),
        SizedBox(height: AppLayout.spaceXl),
        ClientSkeleton(height: 148, borderRadius: AppLayout.radiusLg),
      ],
    );
  }
}
