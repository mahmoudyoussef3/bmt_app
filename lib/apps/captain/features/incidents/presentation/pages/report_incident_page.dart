import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/incident_report.dart';
import '../cubit/incident_cubit.dart';

class ReportIncidentPage extends StatefulWidget {
  const ReportIncidentPage({
    super.key,
    required this.tripId,
    this.initialType = IncidentType.delay,
  });

  final String tripId;
  final IncidentType initialType;

  @override
  State<ReportIncidentPage> createState() => _ReportIncidentPageState();
}

class _ReportIncidentPageState extends State<ReportIncidentPage> {
  late IncidentType _type;
  String _description = '';

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<IncidentCubit>(
      create: (_) => captainGetIt<IncidentCubit>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Report Incident')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          children: [
            DropdownButtonFormField<IncidentType>(
              initialValue: _type,
              items: IncidentType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(_label(type)),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _type = value ?? IncidentType.delay),
              decoration: const InputDecoration(labelText: 'Incident type'),
            ),
            const SizedBox(height: 12),
            TextField(
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Description'),
              onChanged: (value) => _description = value,
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Submit Report',
              onPressed: () {
                context.read<IncidentCubit>().submit(
                  IncidentReport(
                    tripId: widget.tripId,
                    type: _type,
                    description: _description,
                  ),
                );
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  String _label(IncidentType type) {
    return switch (type) {
      IncidentType.passengerIssue => 'Passenger issue',
      IncidentType.vehicleIssue => 'Vehicle issue',
      IncidentType.delay => 'Delay',
      IncidentType.emergency => 'Emergency',
      IncidentType.routeBlockage => 'Route blockage',
      IncidentType.other => 'Other',
    };
  }
}
