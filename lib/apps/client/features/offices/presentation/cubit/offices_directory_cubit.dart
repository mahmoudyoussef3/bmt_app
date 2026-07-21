import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_offices_usecase.dart';
import 'offices_directory_state.dart';

class OfficesDirectoryCubit extends Cubit<OfficesDirectoryState> {
  OfficesDirectoryCubit(this._getOffices)
    : super(const OfficesDirectoryLoading());

  final GetOfficesUseCase _getOffices;

  Future<void> load() async {
    emit(const OfficesDirectoryLoading());
    try {
      emit(OfficesDirectoryLoaded(await _getOffices()));
    } catch (e) {
      emit(OfficesDirectoryError(e.toString()));
    }
  }
}
