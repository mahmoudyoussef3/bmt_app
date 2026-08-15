import 'package:flutter/material.dart';

import '../../../../core/theme/dashboard_icons.dart';
import '../cubit/platform_licensing_state.dart';
import '../sections/audit_section.dart';
import '../sections/invoices_section.dart';
import '../widgets/licensing_layout.dart';
import '../widgets/licensing_scaffold.dart';

/// الفوترة والسجل — what the platform charged, and what the platform decided.
///
/// Two sidebar rows became one destination. They belong together because they
/// are the same kind of thing: append-only records of what already happened,
/// consulted when a question comes up rather than worked in daily. Neither
/// earned a permanent row of its own next to the surfaces the operator actually
/// lives in.
///
/// They also answer each other. "Why was this office invoiced at this figure"
/// is a billing question whose answer — the plan assignment, the override, the
/// cycle change — is an audit row; keeping the switch between them in the page
/// header makes that a single press instead of a round trip through the
/// sidebar.
class PlatformBillingScreen extends StatefulWidget {
  const PlatformBillingScreen({super.key});

  @override
  State<PlatformBillingScreen> createState() => _PlatformBillingScreenState();
}

class _PlatformBillingScreenState extends State<PlatformBillingScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return LicensingScreenFrame(
      builder: (context, state) {
        final tabBar = _tabBar(state);
        return switch (_tab) {
          1 => AuditSection(state: state, tabBar: tabBar),
          _ => InvoicesSection(state: state, tabBar: tabBar),
        };
      },
    );
  }

  Widget _tabBar(PlatformLicensingLoaded state) => LicensingTabs(
    selected: _tab,
    onChanged: (index) => setState(() => _tab = index),
    tabs: [
      LicensingTab(
        label: 'الفواتير',
        icon: DashboardIcons.billing,
        count: state.billing.invoiceCount,
      ),
      LicensingTab(
        label: 'سجل التغييرات',
        icon: DashboardIcons.audit,
        count: state.audit.length,
      ),
    ],
  );
}
