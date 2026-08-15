import 'package:flutter/material.dart';

import '../../../../core/theme/dashboard_icons.dart';
import '../cubit/platform_licensing_state.dart';
import '../sections/features_section.dart';
import '../sections/plans_section.dart';
import '../widgets/licensing_layout.dart';
import '../widgets/licensing_scaffold.dart';

/// الباقات والميزات — everything the platform sells, in one destination.
///
/// These were two sidebar rows, «الخطط والباقات» and «كتالوج الميزات», and they
/// are two halves of one question: a plan is a set of feature values, and a
/// feature is meaningless until a plan carries it. Pricing one without reading
/// the other is not a thing anyone does, so making the operator leave the screen
/// to cross-check was pure tax.
///
/// The switch between them lives in the page header, and the header belongs to
/// whichever section is showing — so the tab strip is always in the same place
/// whichever half is open.
///
/// **The one exception:** while a plan is open in its workspace, the switch is
/// gone. A page-level tab strip above a workspace that has its own tabs is two
/// navigations competing for the same glance, and the workspace already carries
/// a «كل الباقات» button that returns to the gallery — and to the switch with it.
class PlatformCatalogScreen extends StatefulWidget {
  const PlatformCatalogScreen({super.key});

  @override
  State<PlatformCatalogScreen> createState() => _PlatformCatalogScreenState();
}

class _PlatformCatalogScreenState extends State<PlatformCatalogScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return LicensingScreenFrame(
      builder: (context, state) {
        // A plan workspace owns the whole page: no page-level switch above it.
        final inWorkspace = _tab == 0 && state.selectedPlan != null;
        final tabBar = inWorkspace ? null : _tabBar(state);

        return switch (_tab) {
          1 => FeaturesSection(state: state, tabBar: tabBar),
          _ => PlansSection(state: state, tabBar: tabBar),
        };
      },
    );
  }

  Widget _tabBar(PlatformLicensingLoaded state) => LicensingTabs(
    selected: _tab,
    onChanged: (index) => setState(() => _tab = index),
    tabs: [
      LicensingTab(
        label: 'الباقات',
        icon: DashboardIcons.plans,
        count: state.plans.length,
      ),
      LicensingTab(
        label: 'الميزات',
        icon: DashboardIcons.featureCatalog,
        count: state.catalog.features.length,
      ),
    ],
  );
}
