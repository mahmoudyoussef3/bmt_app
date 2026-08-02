import 'package:flutter/material.dart';

import 'package:bmt_app/apps/dashboard/core/widgets/dashboard_module_header.dart';
import 'package:bmt_app/core/theme/spacing.dart';

import '../widgets/notification_composer.dart';
import 'operational_alerts_view.dart';
import 'package:bmt_app/apps/dashboard/core/theme/dashboard_icons.dart';

/// Dashboard notifications center: a live inbox of operational alerts plus a
/// composer for broadcasting announcements to the Client/Captain apps.
///
/// Expects an [OperationalAlertsCubit] and a [NotificationsDispatchCubit]
/// provided above it (wired in the dashboard shell).
class NotificationsCenterScreen extends StatelessWidget {
  const NotificationsCenterScreen({super.key, this.onOpenRoute});

  final ValueChanged<String>? onOpenRoute;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.large,
              AppSpacing.large,
              AppSpacing.large,
              AppSpacing.small,
            ),
            child: DashboardModuleHeader(
              icon: DashboardIcons.notificationsActive,
              title: 'مركز الإشعارات',
              subtitle:
                  'تابع تنبيهات التشغيل الواردة وأرسل إشعارات للعملاء والكباتن.',
            ),
          ),
          Material(
            color: scheme.surface,
            child: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.inbox_outlined), text: 'الوارد'),
                Tab(icon: Icon(Icons.campaign_outlined), text: 'إرسال إشعار'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                OperationalAlertsView(onOpenRoute: onOpenRoute),
                const _ComposerTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComposerTab extends StatelessWidget {
  const _ComposerTab();

  @override
  Widget build(BuildContext context) {
    // Scroll owns the padding so the composer can never be clipped on short
    // viewports; Center only handles horizontal placement of the capped column.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: const NotificationComposer(),
        ),
      ),
    );
  }
}
