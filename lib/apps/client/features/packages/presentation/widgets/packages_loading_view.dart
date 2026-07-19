import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';

/// Skeletons shaped like the package cards they stand in for, so the catalogue
/// does not jump when the real rows arrive.
class PackagesLoadingView extends StatelessWidget {
  const PackagesLoadingView({super.key});

  static const _placeholderCount = 4;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _placeholderCount,
      separatorBuilder: (_, _) => const SizedBox(height: ClientSpacing.sm),
      itemBuilder: (_, _) => ClientSkeleton.packageCard(),
    );
  }
}
