import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/operational_alert.dart';
import '../cubit/operational_alerts_cubit.dart';
import '../cubit/operational_alerts_state.dart';
import '../widgets/alert_tile.dart';

/// The Dashboard's inbound operational-alert inbox. Expects an
/// [OperationalAlertsCubit] provided above it.
class OperationalAlertsView extends StatefulWidget {
  const OperationalAlertsView({super.key, this.onOpenRoute});

  final ValueChanged<String>? onOpenRoute;

  @override
  State<OperationalAlertsView> createState() => _OperationalAlertsViewState();
}

class _OperationalAlertsViewState extends State<OperationalAlertsView> {
  @override
  void initState() {
    super.initState();
    context.read<OperationalAlertsCubit>().startWatching();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OperationalAlertsCubit, OperationalAlertsState>(
      builder: (context, state) {
        return switch (state) {
          OperationalAlertsLoading() || OperationalAlertsInitial() =>
            const Center(child: CircularProgressIndicator()),
          OperationalAlertsError(:final message) => _ErrorView(
            message: message,
            onRetry: () =>
                context.read<OperationalAlertsCubit>().startWatching(),
          ),
          OperationalAlertsLoaded(:final alerts) => _buildLoaded(
            context,
            alerts,
          ),
        };
      },
    );
  }

  Widget _buildLoaded(BuildContext context, List<OperationalAlert> alerts) {
    final cubit = context.read<OperationalAlertsCubit>();
    if (alerts.isEmpty) return const _EmptyView();
    final unread = alerts.where((a) => !a.isRead).length;

    return Column(
      children: [
        if (unread > 0)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 16, 0),
              child: TextButton.icon(
                onPressed: cubit.markAllAsRead,
                icon: const Icon(Icons.done_all_rounded, size: 18),
                label: Text('تعليم الكل كمقروء ($unread)'),
              ),
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: alerts.length,
            itemBuilder: (context, i) => AlertTile(
              alert: alerts[i],
              onMarkRead: () => cubit.markAsRead(alerts[i].id),
              onTap: () => _handleTap(context, alerts[i]),
            ),
          ),
        ),
      ],
    );
  }

  void _handleTap(BuildContext context, OperationalAlert alert) {
    context.read<OperationalAlertsCubit>().markAsRead(alert.id);
    final url = alert.actionUrl;
    if (url != null && url.isNotEmpty) widget.onOpenRoute?.call(url);
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cs.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 56,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text('لا توجد تنبيهات', style: tt.titleMedium),
          const SizedBox(height: 6),
          Text(
            'ستظهر هنا مراجعات الدفع وطلبات الكباتن والشكاوى فور وصولها.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 44, color: cs.error),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
        ],
      ),
    );
  }
}
