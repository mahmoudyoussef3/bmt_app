import 'package:flutter/material.dart';

/// Lets the client app switch [ThemeMode] from settings without extra state libs.
class ClientAppTheme extends InheritedWidget {
  const ClientAppTheme({
    super.key,
    required this.themeMode,
    required this.setThemeMode,
    required super.child,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> setThemeMode;

  static ClientAppTheme? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ClientAppTheme>();
  }

  static ThemeMode themeModeFromKey(String key) {
    switch (key) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static String keyFromThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  @override
  bool updateShouldNotify(ClientAppTheme oldWidget) {
    return oldWidget.themeMode != themeMode;
  }
}
