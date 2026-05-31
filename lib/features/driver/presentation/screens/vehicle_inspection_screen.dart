import 'package:flutter/material.dart';
import 'package:bmt_app/features/driver/driver_service.dart';
import 'package:bmt_app/core/widgets/widgets.dart';

class VehicleInspectionScreen extends StatefulWidget {
  const VehicleInspectionScreen({super.key});

  @override
  State<VehicleInspectionScreen> createState() =>
      _VehicleInspectionScreenState();
}

class _VehicleInspectionScreenState extends State<VehicleInspectionScreen> {
  final Map<String, bool> checks = {
    'Fuel': true,
    'Tires': true,
    'Brakes': true,
    'AC': true,
    'Lights': true,
    'Cleanliness': true,
  };

  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle Inspection')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        children: [
          AppCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pre-trip checklist',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 8),
                for (final key in checks.keys) ...[
                  CheckboxListTile(
                    value: checks[key],
                    title: Text(key),
                    onChanged: (v) => setState(() => checks[key] = v ?? false),
                  ),
                ],
                const SizedBox(height: 12),
                AppButton(
                  label: _submitting ? 'Submitting...' : 'Submit Inspection',
                  onPressed: () {
                    if (_submitting) return;
                    setState(() => _submitting = true);
                    final navigator = Navigator.of(context);
                    DriverService.cubitInstance.submitInspection(checks).then((
                      _,
                    ) {
                      if (!mounted) return;
                      setState(() => _submitting = false);
                      navigator.pop();
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
