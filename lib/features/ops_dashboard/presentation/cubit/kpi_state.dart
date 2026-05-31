import '../../domain/models/kpi.dart';

abstract class KpiState {}

class KpiLoading extends KpiState {}

class KpiLoaded extends KpiState {
  final List<Kpi> kpis;
  KpiLoaded(this.kpis);
}

class KpiError extends KpiState {
  final String message;
  KpiError(this.message);
}
