import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/core/utils/captain_formats.dart';
import 'package:bmt_app/core/widgets/app_snackbar.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/live_location_cubit.dart';
import '../cubit/live_location_state.dart';

class LocationUpdatePage extends StatelessWidget {
  const LocationUpdatePage({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LiveLocationCubit>(
      create: (_) => captainGetIt<LiveLocationCubit>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('إرسال الموقع')),
        body: BlocConsumer<LiveLocationCubit, LiveLocationState>(
          listener: (context, state) {
            if (state is LiveLocationReady && state.lastSentAt != null) {
              AppSnackbar.success(context, 'تم إرسال موقعك الحالي بنجاح.');
            }
          },
          builder: (context, state) {
            final scheme = Theme.of(context).colorScheme;
            final loading = state is LiveLocationLoading;
            final lastSentAt = state is LiveLocationReady
                ? state.lastSentAt
                : null;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: AppCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: scheme.primaryContainer,
                          child: Icon(
                            Icons.my_location_rounded,
                            size: 34,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'أرسل موقعك الحالي',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'أثناء سير الرحلة يُرسل موقعك تلقائياً كل 30 ثانية من شاشة تنفيذ '
                          'الرحلة. استخدم هذا الزر لإرسال موقع فوري في أي وقت. '
                          'لا يعمل التتبع في الخلفية.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        if (lastSentAt != null) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer.withAlpha(100),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: scheme.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'آخر إرسال: ${_formatTime(lastSentAt)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (state is LiveLocationError) ...[
                          const SizedBox(height: 16),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: scheme.error),
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: loading
                              ? null
                              : () => context.read<LiveLocationCubit>().send(
                                  tripId,
                                ),
                          icon: loading
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                          label: Text(
                            loading
                                ? 'جاري تحديد الموقع...'
                                : lastSentAt == null
                                ? 'إرسال موقعي الآن'
                                : 'إرسال موقع جديد',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatTime(DateTime value) {
    final local = value.toLocal();
    return '${local.year}/${local.month}/${local.day} - '
        '${CaptainFormats.clock(local)}';
  }
}
