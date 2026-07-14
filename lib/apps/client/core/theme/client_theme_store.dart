import 'package:flutter/material.dart';

import 'package:bmt_app/core/security/secure_storage.dart';

/// Remembers the appearance the rider picked.
///
/// Without this the theme switch only lasted until the app was killed, which
/// reads as a bug: the rider sets dark mode, comes back tomorrow, and the app
/// is light again.
class ClientThemeStore {
  ClientThemeStore({SecureStorage? storage})
    : _storage = storage ?? SecureStorage();

  final SecureStorage _storage;

  static const _key = 'client_theme_mode';

  Future<ThemeMode> read() async {
    try {
      return fromKey(await _storage.read(_key));
    } catch (_) {
      return ThemeMode.system;
    }
  }

  Future<void> write(ThemeMode mode) async {
    try {
      await _storage.write(_key, keyOf(mode));
    } catch (_) {
      // The theme already applied in-session; it just won't survive a restart.
    }
  }

  static ThemeMode fromKey(String? key) => switch (key) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  static String keyOf(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };
}
