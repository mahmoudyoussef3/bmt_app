import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/core/widgets/client_widgets.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_office_tile.dart';

/// Placeholder rail shown while the marketplace directory loads.
class HomeOfficesRailSkeleton extends StatelessWidget {
  const HomeOfficesRailSkeleton({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(width: ClientSpacing.sm),
        itemBuilder: (_, _) => SizedBox(
          width: HomeOfficeTile.width,
          child: ClientSkeleton(height: height, borderRadius: ClientRadius.lg),
        ),
      ),
    );
  }
}
