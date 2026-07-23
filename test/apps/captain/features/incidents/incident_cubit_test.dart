import 'package:flutter_test/flutter_test.dart';

import 'package:bmt_app/apps/captain/features/incidents/domain/entities/incident_report.dart';
import 'package:bmt_app/apps/captain/features/incidents/domain/repositories/incident_repository.dart';
import 'package:bmt_app/apps/captain/features/incidents/domain/usecases/report_incident_usecase.dart';
import 'package:bmt_app/apps/captain/features/incidents/presentation/cubit/incident_cubit.dart';
import 'package:bmt_app/apps/captain/features/incidents/presentation/cubit/incident_state.dart';

/// The incident path is what an SOS hold lands on, so its states have to be
/// unambiguous: the screen closes on `submitted`, and must not close on a
/// failure that leaves the report unfiled.
class _FakeIncidentRepository implements IncidentRepository {
  _FakeIncidentRepository({this.fails = false});

  final bool fails;
  final List<IncidentReport> filed = [];

  @override
  Future<IncidentReport> reportIncident(IncidentReport report) async {
    if (fails) throw Exception('الشبكة غير متاحة');
    filed.add(report);
    return report;
  }
}

void main() {
  const report = IncidentReport(
    tripId: 't1',
    type: IncidentType.emergency,
    description: 'عطل في الفرامل على الطريق الصحراوي',
  );

  test('a filed report passes through submitting and lands submitted', () async {
    final repository = _FakeIncidentRepository();
    final cubit = IncidentCubit(ReportIncidentUseCase(repository));
    final seen = <IncidentState>[];
    cubit.stream.listen(seen.add);

    await cubit.submit(report);
    // The stream delivers asynchronously; let it drain before reading it.
    await Future<void>.delayed(Duration.zero);

    expect(seen.first, isA<IncidentSubmitting>());
    expect((cubit.state as IncidentReady).submitted, isTrue);
    expect(repository.filed.single.type, IncidentType.emergency);
    await cubit.close();
  });

  test('a failed report never reports itself as submitted, so the screen '
      'stays open on the captain\'s text', () async {
    final cubit = IncidentCubit(
      ReportIncidentUseCase(_FakeIncidentRepository(fails: true)),
    );

    await cubit.submit(report);

    expect(cubit.state, isA<IncidentError>());
    await cubit.close();
  });

  test('the cubit starts ready and unsubmitted', () {
    final cubit = IncidentCubit(
      ReportIncidentUseCase(_FakeIncidentRepository()),
    );

    expect((cubit.state as IncidentReady).submitted, isFalse);
    cubit.close();
  });
}
