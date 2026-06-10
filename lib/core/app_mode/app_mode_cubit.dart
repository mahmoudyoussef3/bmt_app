import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'app_mode.dart';

class AppModeState {
  final AppMode mode;
  const AppModeState(this.mode);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppModeState &&
          runtimeType == other.runtimeType &&
          mode == other.mode;

  @override
  int get hashCode => mode.hashCode;
}

class AppModeCubit extends Cubit<AppModeState> {
  static const _storageKey = 'dev_app_mode';
  final FlutterSecureStorage _storage;

  AppModeCubit({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage(),
      super(const AppModeState(AppMode.client));

  Future<void> load() async {
    try {
      final saved = await _storage.read(key: _storageKey);
      if (saved != null) {
        final mode = AppMode.values.firstWhere((e) => e.name == saved);
        emit(AppModeState(mode));
      }
    } catch (_) {}
  }

  Future<void> changeMode(AppMode mode) async {
    emit(AppModeState(mode));
    try {
      await _storage.write(key: _storageKey, value: mode.name);
    } catch (_) {}
  }
}
