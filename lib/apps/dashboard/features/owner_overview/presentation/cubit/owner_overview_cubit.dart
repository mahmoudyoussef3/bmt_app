import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_owner_overview_usecase.dart';
import 'owner_overview_state.dart';

class OwnerOverviewCubit extends Cubit<OwnerOverviewState> {
  final GetOwnerOverviewUseCase _getOverview;

  OwnerOverviewCubit({required GetOwnerOverviewUseCase getOverview})
      : _getOverview = getOverview,
        super(const OwnerOverviewLoading());

  Future<void> load() async {
    emit(const OwnerOverviewLoading());
    try {
      emit(OwnerOverviewLoaded(await _getOverview()));
    } catch (error) {
      emit(OwnerOverviewError(error.toString()));
    }
  }
}
