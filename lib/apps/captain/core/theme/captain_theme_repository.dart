import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the captain's appearance choice (light/dark/system) — a
/// non-sensitive preference, so this uses `SharedPreferences` like the
/// app's other local stores (`CaptainSessionStore`, `SeenTripsLocalDataSource`),
/// not secure storage.
class CaptainThemeRepository {
  const CaptainThemeRepository();

  static const _storageKey = 'captain_theme_mode';

  Future<ThemeMode> loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return switch (prefs.getString(_storageKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await prefs.setString(_storageKey, value);
  }
}
