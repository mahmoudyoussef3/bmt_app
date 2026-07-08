import 'package:bmt_app/apps/captain/core/di/captain_di.dart';
import 'package:bmt_app/core/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/incident_report.dart';
import '../cubit/incident_cubit.dart';
import '../cubit/incident_state.dart';

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
  bool _submitting = false;

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
        appBar: AppBar(title: const Text('الإبلاغ عن حادثة')),
        body: BlocConsumer<IncidentCubit, IncidentState>(
          listener: (context, state) {
            if (state is IncidentReady && state.submitted) {
              Navigator.of(context).pop();
            }
            if (state is IncidentError) {
              setState(() => _submitting = false);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 20),
              children: [
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تفاصيل البلاغ',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
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
                        onChanged: _submitting
                            ? null
                            : (value) => setState(
                                () => _type = value ?? IncidentType.delay,
                              ),
                        decoration: const InputDecoration(
                          labelText: 'نوع الحادثة',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        minLines: 4,
                        maxLines: 6,
                        enabled: !_submitting,
                        decoration: const InputDecoration(
                          labelText: 'الوصف',
                          hintText: 'اكتب ما حدث بوضوح لفريق العمليات',
                        ),
                        onChanged: (value) => _description = value,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'إرسال البلاغ',
                  isLoading: state is IncidentSubmitting || _submitting,
                  onPressed: () {
                    final description = _description.trim();
                    if (description.length < 8) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('اكتب وصفاً واضحاً قبل إرسال البلاغ'),
                        ),
                      );
                      return;
                    }
                    setState(() => _submitting = true);
                    context.read<IncidentCubit>().submit(
                      IncidentReport(
                        tripId: widget.tripId,
                        type: _type,
                        description: description,
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _label(IncidentType type) {
    return switch (type) {
      IncidentType.passengerIssue => 'مشكلة مع راكب',
      IncidentType.vehicleIssue => 'مشكلة في المركبة',
      IncidentType.delay => 'تأخير',
      IncidentType.emergency => 'طوارئ',
      IncidentType.routeBlockage => 'انسداد الطريق',
      IncidentType.other => 'أخرى',
    };
  }
}
