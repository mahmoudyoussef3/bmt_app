import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/features/communication/presentation/pages/chat_details_page.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/passenger.dart';
import '../cubit/passenger_manifest_cubit.dart';
import '../cubit/passenger_manifest_state.dart';
import '../widgets/passenger_card.dart';

class PassengerListPage extends StatelessWidget {
  const PassengerListPage({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PassengerManifestCubit>(
      create: (_) => captainGetIt<PassengerManifestCubit>()..load(tripId),
      child: Scaffold(
        appBar: AppBar(title: const Text('قائمة الركاب')),
        body: BlocBuilder<PassengerManifestCubit, PassengerManifestState>(
          builder: (context, state) {
            if (state is PassengerManifestLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is PassengerManifestError) {
              return AsyncStateView(
                status: AsyncViewStatus.error,
                errorMessage: state.message,
                onRetry: () =>
                    context.read<PassengerManifestCubit>().load(tripId),
                child: const SizedBox.shrink(),
              );
            }
            final passengers = state is PassengerManifestLoaded
                ? state.passengers
                : <Passenger>[];
            final boarded = passengers
                .where((p) => p.status == PassengerBoardingStatus.boarded)
                .length;
            if (passengers.isEmpty) {
              return const EmptyState(
                title: 'لا يوجد ركاب على هذه الرحلة',
                subtitle: 'ستظهر الحجوزات المؤكدة هنا فور إضافتها.',
              );
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ManifestMetric(
                            label: 'صعد',
                            value: boarded.toString(),
                            color: Colors.green,
                          ),
                        ),
                        Expanded(
                          child: _ManifestMetric(
                            label: 'متبقٍ',
                            value: (passengers.length - boarded).toString(),
                            color: Colors.orange,
                          ),
                        ),
                        Expanded(
                          child: _ManifestMetric(
                            label: 'الإجمالي',
                            value: passengers.length.toString(),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                    itemCount: passengers.length,
                    itemBuilder: (context, index) {
                      final passenger = passengers[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: PassengerCard(
                          passenger: passenger,
                          onCall: () {
                            launchUrl(Uri.parse('tel:${passenger.phone}'));
                          },
                          onChat: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatDetailsPage(
                                tripId: tripId,
                                passengerId: passenger.id,
                                title: passenger.name,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ManifestMetric extends StatelessWidget {
  const _ManifestMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
