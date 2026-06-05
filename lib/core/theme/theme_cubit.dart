import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:bmt_app/core/security/secure_storage.dart';

class ThemeState {
  final ThemeMode themeMode;
  final bool isLoaded;

  const ThemeState({required this.themeMode, this.isLoaded = false});
}

class ThemeCubit extends Cubit<ThemeState> {
  static const _storageKey = 'ops_dashboard_theme_mode';
  final SecureStorage _storage;

  ThemeCubit({SecureStorage? storage})
    : _storage = storage ?? SecureStorage(),
      super(const ThemeState(themeMode: ThemeMode.system));

  Future<void> load() async {
    try {
      final stored = await _storage.read(_storageKey);
      emit(ThemeState(themeMode: _themeModeFromKey(stored), isLoaded: true));
    } catch (_) {
      emit(const ThemeState(themeMode: ThemeMode.system, isLoaded: true));
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(ThemeState(themeMode: mode, isLoaded: true));
    try {
      await _storage.write(_storageKey, _keyFromThemeMode(mode));
    } catch (_) {}
  }

  static ThemeMode _themeModeFromKey(String? key) {
    return switch (key) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  static String _keyFromThemeMode(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
  }
}
