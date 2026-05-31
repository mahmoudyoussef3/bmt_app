import 'package:flutter/material.dart';
import 'package:bmt_app/features/driver/driver_service.dart';
import 'package:bmt_app/features/driver/domain/models/incident.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

class IncidentReportingScreen extends StatefulWidget {
  const IncidentReportingScreen({super.key});

  @override
  State<IncidentReportingScreen> createState() =>
      _IncidentReportingScreenState();
}

class _IncidentReportingScreenState extends State<IncidentReportingScreen> {
  String _type = 'Traffic';
  String _description = '';
  int _severity = 2;

  final types = [
    'Traffic',
    'Vehicle Issue',
    'Passenger Issue',
    'Breakdown',
    'Emergency',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Incident')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: _type,
              items: types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? types.first),
              decoration: const InputDecoration(labelText: 'Incident Type'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Description'),
              onChanged: (v) => setState(() => _description = v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Severity'),
                Expanded(
                  child: Slider(
                    value: _severity.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    onChanged: (v) => setState(() => _severity = v.toInt()),
                  ),
                ),
                Text('$_severity'),
              ],
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Submit Report',
              onPressed: () {
                final incident = Incident(
                  id: 'inc-${DateTime.now().millisecondsSinceEpoch}',
                  type: _type,
                  description: _description,
                  severity: _severity,
                );
                DriverService.cubitInstance.reportIncident(incident);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
