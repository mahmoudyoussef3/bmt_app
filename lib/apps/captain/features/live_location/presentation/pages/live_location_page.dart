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
        appBar: AppBar(title: const Text('Live Location')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: BlocBuilder<LiveLocationCubit, LiveLocationState>(
            builder: (context, state) {
              final cubit = context.read<LiveLocationCubit>();
              final enabled = state is LiveLocationReady && state.enabled;
              final loading = state is LiveLocationLoading;

              return AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: enabled ? Colors.green : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          enabled
                              ? 'الموقع يُبث للعمليات'
                              : 'مشاركة الموقع متوقفة',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'الرحلة: ${widget.tripId}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (enabled) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_on_rounded,
                                color: Colors.green, size: 16),
                            SizedBox(width: 6),
                            Text('يعمل في الخلفية',
                                style: TextStyle(
                                    color: Colors.green, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    if (loading)
                      const Center(child: CircularProgressIndicator())
                    else
                      SizedBox(
                        width: double.infinity,
                        child: enabled
                            ? OutlinedButton.icon(
                                icon: const Icon(Icons.location_off_rounded),
                                label: const Text('إيقاف المشاركة'),
                                style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red),
                                onPressed: () => cubit.stop(widget.tripId),
                              )
                            : FilledButton.icon(
                                icon: const Icon(Icons.location_on_rounded),
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
                            fontSize: 12),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
