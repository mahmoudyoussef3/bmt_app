import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_panel.dart';
import 'package:bmt_app/apps/dashboard/features/office_profile/presentation/widgets/office_marketplace_summary.dart';

import '../../domain/entities/dashboard_home_summary.dart';

/// Pure reuse: the office-profile module already built the exact "listing
/// status / rating / profile completeness" card the spec asks for here, so
/// Home just feeds it the same [OfficeProfile] rather than re-implementing it.
class MarketplaceStatusCard extends StatelessWidget {
  const MarketplaceStatusCard({super.key, required this.summary});

  final DashboardHomeSummary summary;

  @override
  Widget build(BuildContext context) {
    return DashboardPanel(
      icon: Icons.storefront_rounded,
      title: 'حالة المكتب في السوق',
      child: OfficeMarketplaceSummary(profile: summary.officeProfile),
    );
  }
}
