import 'package:flutter/material.dart';

import 'package:bmt_app/core/security/secure_storage.dart';

class DashboardThemeRepository {
  static const _storageKey = 'dashboard_theme_mode';
  final SecureStorage _storage;

  DashboardThemeRepository({SecureStorage? storage})
    : _storage = storage ?? SecureStorage();

  Future<ThemeMode> loadThemeMode() async {
    final stored = await _storage.read(_storageKey);
    return switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _storage.write(_storageKey, value);
  }
}
