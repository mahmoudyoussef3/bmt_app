import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_routes_usecase.dart';
import 'routes_directory_state.dart';

class RoutesDirectoryCubit extends Cubit<RoutesDirectoryState> {
  RoutesDirectoryCubit(this._getRoutes) : super(const RoutesDirectoryLoading());

  final GetRoutesUseCase _getRoutes;

  Future<void> load() async {
    emit(const RoutesDirectoryLoading());
    await _fetch();
  }

  /// Narrows the catalog to routes whose name, endpoints, or office match.
  ///
  /// Filtering happens over the list already in memory: the catalog is small
  /// and fully loaded, so a round trip per keystroke would only add latency.
  void setQuery(String query) {
    final current = state;
    if (current is! RoutesDirectoryLoaded) return;
    if (current.query == query) return;
    emit(current.copyWith(query: query));
  }

  /// Refetches without dropping the catalog already on screen. A failed
  /// refresh keeps the last usable list rather than replacing it with an
  /// error, and the rider's search survives it too.
  Future<void> refresh() async {
    if (state is! RoutesDirectoryLoaded) return load();
    final previous = state as RoutesDirectoryLoaded;
    try {
      emit(previous.copyWith(routes: await _getRoutes()));
    } catch (_) {
      if (!isClosed) emit(previous);
    }
  }

  Future<void> _fetch() async {
    try {
      final routes = await _getRoutes();
      if (isClosed) return;
      emit(RoutesDirectoryLoaded(routes));
    } catch (e) {
      if (isClosed) return;
      emit(RoutesDirectoryError(e.toString()));
    }
  }
}
