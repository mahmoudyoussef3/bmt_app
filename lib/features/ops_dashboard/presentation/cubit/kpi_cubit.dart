import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/kpi_repository.dart';
import 'kpi_state.dart';

class KpiCubit extends Cubit<KpiState> {
  final KpiRepository repository;
  KpiCubit(this.repository) : super(KpiLoading());

  Future<void> loadKpis() async {
    try {
      emit(KpiLoading());
      final kpis = await repository.fetchKpis();
      emit(KpiLoaded(kpis));
    } catch (e) {
      emit(KpiError(e.toString()));
    }
  }
}
