import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/live_location_cubit.dart';
import '../cubit/live_location_state.dart';

class LiveLocationPage extends StatefulWidget {
  const LiveLocationPage({super.key, required this.tripId});

  final String tripId;

  @override
  State<LiveLocationPage> createState() => _LiveLocationPageState();
}

class _LiveLocationPageState extends State<LiveLocationPage> {
  bool _batteryWarningShown = false;

  Future<void> _startWithWarning(LiveLocationCubit cubit) async {
    if (!_batteryWarningShown) {
      _batteryWarningShown = true;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('تنبيه استهلاك البطارية'),
          content: const Text(
            'مشاركة الموقع المستمرة تستهلك البطارية.\n'
            'يُنصح بتوصيل الشاحن أثناء الرحلة.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('بدء المشاركة'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    cubit.start(widget.tripId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LiveLocationCubit>(
      create: (_) => captainGetIt<LiveLocationCubit>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('مشاركة الموقع')),
        body: BlocBuilder<LiveLocationCubit, LiveLocationState>(
          builder: (context, state) {
            final cubit = context.read<LiveLocationCubit>();
            final enabled = state is LiveLocationReady && state.enabled;
            final loading = state is LiveLocationLoading;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              children: [
                Column(
                  children: [
                    AppCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: (enabled ? Colors.green : Colors.grey)
                                      .withAlpha(32),
                                ),
                                child: Icon(
                                  enabled
                                      ? Icons.location_on_rounded
                                      : Icons.location_off_rounded,
                                  color: enabled ? Colors.green : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      enabled
                                          ? 'الموقع يُبث للعمليات'
                                          : 'مشاركة الموقع متوقفة',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'الرحلة: ${widget.tripId}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            enabled
                                ? 'يعمل التتبع في الخلفية ليساعد فريق العمليات على متابعة الرحلة لحظة بلحظة.'
                                : 'ابدأ مشاركة الموقع عند الاستعداد للتحرك أو عند طلب العمليات ذلك.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 18),
                          if (loading)
                            const Center(child: CircularProgressIndicator())
                          else
                            SizedBox(
                              width: double.infinity,
                              child: enabled
                                  ? OutlinedButton.icon(
                                      icon: const Icon(
                                        Icons.location_off_rounded,
                                      ),
                                      label: const Text('إيقاف المشاركة'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      onPressed: () =>
                                          cubit.stop(widget.tripId),
                                    )
                                  : FilledButton.icon(
                                      icon: const Icon(
                                        Icons.location_on_rounded,
                                      ),
                                      label: const Text('بدء المشاركة'),
                                      onPressed: () => _startWithWarning(cubit),
                                    ),
                            ),
                          if (state is LiveLocationError) ...[
                            const SizedBox(height: 12),
                            Text(
                              state.message,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
