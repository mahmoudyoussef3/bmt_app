import 'package:flutter/material.dart';

import '../widgets/notification_composer.dart';
import 'operational_alerts_view.dart';

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
    final cs = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Material(
              color: cs.surface,
              child: TabBar(
                tabs: const [
                  Tab(icon: Icon(Icons.inbox_outlined), text: 'الوارد'),
                  Tab(icon: Icon(Icons.campaign_outlined), text: 'إرسال إشعار'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  OperationalAlertsView(onOpenRoute: onOpenRoute),
                  _ComposerTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: const NotificationComposer(),
          ),
        ),
      ),
    );
  }
}
