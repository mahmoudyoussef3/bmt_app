import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_offices_usecase.dart';
import 'offices_directory_state.dart';

class OfficesDirectoryCubit extends Cubit<OfficesDirectoryState> {
  OfficesDirectoryCubit(this._getOffices)
    : super(const OfficesDirectoryLoading());

  final GetOfficesUseCase _getOffices;

  Future<void> load() async {
    emit(const OfficesDirectoryLoading());
    await _fetch();
  }

  /// Refetches without dropping the directory already on screen, so a
  /// pull-to-refresh on Home does not blink the companies rail back to its
  /// skeleton. A failed refresh keeps the last usable list rather than
  /// replacing it with an error.
  Future<void> refresh() async {
    if (state is! OfficesDirectoryLoaded) return load();
    final previous = state as OfficesDirectoryLoaded;
    try {
      emit(OfficesDirectoryLoaded(await _getOffices()));
    } catch (_) {
      if (!isClosed) emit(previous);
    }
  }

  Future<void> _fetch() async {
    try {
      final offices = await _getOffices();
      if (isClosed) return;
      emit(OfficesDirectoryLoaded(offices));
    } catch (e) {
      if (isClosed) return;
      emit(OfficesDirectoryError(e.toString()));
    }
  }
}
