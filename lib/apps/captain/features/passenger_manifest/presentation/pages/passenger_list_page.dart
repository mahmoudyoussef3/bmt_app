import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/apps/captain/features/communication/presentation/pages/chat_details_page.dart';
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
        appBar: AppBar(title: const Text('Passenger Manifest')),
        body: BlocBuilder<PassengerManifestCubit, PassengerManifestState>(
          builder: (context, state) {
            if (state is PassengerManifestLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is PassengerManifestError) {
              return Center(child: Text(state.message));
            }
            final passengers = state is PassengerManifestLoaded
                ? state.passengers
                : <Passenger>[];
            final boarded = passengers
                .where((p) => p.status == PassengerBoardingStatus.boarded)
                .length;
            return Column(
              children: [
                if (passengers.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: Text(
                      '✓ $boarded boarded · ${passengers.length - boarded} remaining · ${passengers.length} total',
                      style: Theme.of(context).textTheme.bodySmall,
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
