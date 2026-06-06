import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/check_in_result.dart';
import '../cubit/check_in_cubit.dart';
import '../cubit/check_in_state.dart';

class CheckInPage extends StatefulWidget {
  const CheckInPage({super.key, required this.tripId});

  final String tripId;

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  late final TextEditingController _controller;
  String _passengerId = 'p1';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _passengerId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CheckInCubit>(
      create: (_) => captainGetIt<CheckInCubit>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Passenger Check-In')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          children: [
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QR scanner placeholder',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Passenger ID',
                    ),
                    onChanged: (value) => _passengerId = value,
                  ),
                  const SizedBox(height: 12),
                  BlocBuilder<CheckInCubit, CheckInState>(
                    builder: (context, state) {
                      final result = state is CheckInReady
                          ? state.result
                          : null;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (result != null) ...[
                            StatusChip(label: result.status.name),
                            const SizedBox(height: 12),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  label: 'Boarded',
                                  onPressed: () =>
                                      _check(context, CheckInStatus.boarded),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: AppButton(
                                  label: 'Absent',
                                  outline: true,
                                  onPressed: () =>
                                      _check(context, CheckInStatus.absent),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _check(BuildContext context, CheckInStatus status) {
    context.read<CheckInCubit>().check(
      tripId: widget.tripId,
      passengerId: _passengerId,
      status: status,
    );
  }
}
