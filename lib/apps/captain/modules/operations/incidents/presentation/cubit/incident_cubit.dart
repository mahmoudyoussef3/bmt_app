import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/incident_report.dart';
import '../../domain/usecases/report_incident_usecase.dart';
import 'incident_state.dart';

class IncidentCubit extends Cubit<IncidentState> {
  IncidentCubit(this._reportIncident) : super(const IncidentReady());

  final ReportIncidentUseCase _reportIncident;

  Future<void> submit(IncidentReport report) async {
    emit(const IncidentSubmitting());
    try {
      await _reportIncident(report);
      emit(const IncidentReady(submitted: true));
    } catch (error) {
      emit(IncidentError(error.toString()));
    }
  }
}
