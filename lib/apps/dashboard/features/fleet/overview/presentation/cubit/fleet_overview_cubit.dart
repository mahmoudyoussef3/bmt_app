import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/fleet_usecases.dart';
import 'fleet_overview_state.dart';

class FleetOverviewCubit extends Cubit<FleetOverviewState> {
  final GetFleetWorkspaceUseCase getWorkspace;

  FleetOverviewCubit({
    required this.getWorkspace,
  }) : super(FleetOverviewInitial());

  Future<void> loadWorkspace() async {
    emit(FleetOverviewLoading());
    try {
      final workspace = await getWorkspace();
      emit(FleetOverviewLoaded(workspace));
    } catch (e) {
      debugPrint('Error loading fleet workspace: $e');
      emit(FleetOverviewError(e.toString()));
    }
  }
}
