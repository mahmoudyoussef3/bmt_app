import 'package:flutter/material.dart';

import 'package:bmt_app/apps/client/core/theme/client_design_tokens.dart';
import 'package:bmt_app/apps/client/features/offices/domain/entities/office_summary.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_office_tile.dart';
import 'package:bmt_app/apps/client/features/home/presentation/widgets/home_offices_rail_skeleton.dart';

/// The operators trading on the marketplace, as a horizontal rail.
///
/// EWT sells several companies' seats side by side, so Home names them before
/// it lists departures: a rider who trusts one operator can go straight to
/// everything it runs instead of scanning a mixed feed for its badge. A rail
/// rather than a grid — it is a shortcut into the directory, not the directory.
class HomeOfficesRail extends StatelessWidget {
  const HomeOfficesRail({
    super.key,
    required this.offices,
    required this.isLoading,
    required this.onOpenOffice,
  });

  final List<OfficeSummary> offices;
  final bool isLoading;
  final ValueChanged<OfficeSummary> onOpenOffice;

  static const double height = HomeOfficeTile.height;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const HomeOfficesRailSkeleton(height: height);

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        itemCount: offices.length,
        separatorBuilder: (_, _) => const SizedBox(width: ClientSpacing.sm),
        itemBuilder: (context, index) {
          final office = offices[index];
          return HomeOfficeTile(
            office: office,
            onTap: () => onOpenOffice(office),
          );
        },
      ),
    );
  }
}
