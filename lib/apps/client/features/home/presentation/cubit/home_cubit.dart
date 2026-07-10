import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_home_data_usecase.dart';
import '../../domain/usecases/watch_home_changes_usecase.dart';
import 'home_state.dart';

import 'package:bmt_app/core/network/api_error_handler.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._getHomeData, this._watchHomeChanges)
      : super(const HomeLoading());

  final GetHomeDataUseCase _getHomeData;
  final WatchHomeChangesUseCase _watchHomeChanges;
  StreamSubscription<void>? _homeChangesSubscription;
  Timer? _refreshDebounce;
  bool _refreshing = false;

  /// Loads home data. When content is already on screen (pull-to-refresh,
  /// realtime event, or app resume), the loaded state is kept instead of
  /// flashing the skeleton; a refresh failure also keeps the existing
  /// content rather than replacing it with a full-screen error.
  Future<void> load() async {
    final previous = state;
    if (previous is! HomeLoaded) emit(const HomeLoading());
    try {
      final data = await _getHomeData();
      if (isClosed) return;
      emit(HomeLoaded(data));
      _subscribeToChanges();
    } catch (error) {
      if (isClosed) return;
      final failure = ApiErrorHandler.handle(error);
      if (previous is HomeLoaded) {
        emit(HomeLoaded(previous.data, refreshFailure: failure));
      } else {
        emit(HomeError(failure));
      }
    }
  }

  /// Keeps Home in sync with trip status changes (e.g. a trip completing)
  /// so listings never outlive the trips they describe. Debounced so a
  /// burst of row changes triggers a single refetch.
  void _subscribeToChanges() {
    if (_homeChangesSubscription != null) return;
    _homeChangesSubscription = _watchHomeChanges().listen((_) {
      _refreshDebounce?.cancel();
      _refreshDebounce = Timer(
        const Duration(milliseconds: 250),
        _refreshFromRealtime,
      );
    }, onError: (_) {});
  }

  Future<void> _refreshFromRealtime() async {
    if (_refreshing || isClosed) return;
    _refreshing = true;
    try {
      final data = await _getHomeData();
      if (isClosed) return;
      emit(HomeLoaded(data));
    } catch (_) {
      // A realtime refresh is best-effort; keep the last usable state.
    } finally {
      _refreshing = false;
    }
  }

  @override
  Future<void> close() {
    _refreshDebounce?.cancel();
    _homeChangesSubscription?.cancel();
    return super.close();
  }
}
